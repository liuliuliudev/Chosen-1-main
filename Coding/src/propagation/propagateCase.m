function result = propagateCase(caseConfig, p)
%PROPAGATECASE 分段传播单个案例的轨道和质量状态。
% 输入为案例配置和国际单位制参数；输出含轨迹、控制记录、事件及指标。
% 每段内控制命令固定，积分到占空比边界、事件或时间上限后再更新命令。
if nargin < 2, p = baseline_case(); end
[caseConfig,p] = faultInjection(caseConfig,p);
if ~isfield(caseConfig,'id'), caseConfig.id = caseConfig.strategy; end
% 初始状态与控制阶段由案例参数和策略共同确定。
x = initialOrbitState(p);
t = 0;
phase = caseConfig.policy.initialPhase;
supervised = isfield(caseConfig,'supervisor') && caseConfig.supervisor.enabled;
powerCoupled = isfield(caseConfig,'powerModel') && caseConfig.powerModel;
improvedControl = isfield(caseConfig,'improvedControl') && caseConfig.improvedControl;
unifiedLoads = improvedControl || (isfield(caseConfig,'unifiedLoads') && caseConfig.unifiedLoads);
deploymentModel = improvedControl && isfield(caseConfig,'deploymentModel') && caseConfig.deploymentModel;
deployStarted_s = NaN;
deployFinished = false;
if powerCoupled
    assert(supervised,'Power model requires a supervised case.');
    q = powerScenario(p,caseConfig);
    if unifiedLoads
        % 保守预留安全等待负载（高于帆监测负载）。
        q.coastLoad_W = modePowerLoad("safe",false,q);
        q.thrustLoad_W = modePowerLoad("thrust",true,q);
        q.deployLoad_W = modePowerLoad("deploying",false,q);
    end
    if improvedControl
        q.improvedControl = true;
        assert(isfield(caseConfig,'reserveFraction') && isfinite(caseConfig.reserveFraction) && caseConfig.reserveFraction>=0);
        q.safetyReserve_Wh = caseConfig.reserveFraction*q.coastLoad_W*q.period_s*q.eclipseFraction/3600;
        if deploymentModel
            assert(caseConfig.deploymentDelay_s>0 && caseConfig.deploymentTimeout_s>=caseConfig.deploymentDelay_s);
        end
    end
    if isfield(caseConfig,'powerStep_s')
        assert(isscalar(caseConfig.powerStep_s) && isfinite(caseConfig.powerStep_s) && ...
            caseConfig.powerStep_s > 0 && caseConfig.powerStep_s <= q.step_s);
        q.step_s = caseConfig.powerStep_s;
    end
    q.solarEol_W = caseConfig.supervisor.powerAvailable_W;
    battery_Wh = q.initialFraction*q.capacity_Wh;
    batteryMinimum_Wh = battery_Wh;
    unmetBase_Wh = 0;
    powerTrace=zeros(0,7);
    nextPowerDecision_s=0;
    heldPower_W=0;
end
if supervised
    ledger = loadEngineeringBudget();
    budget = computeEngineeringBudget(p,ledger);
    powerMode = budget.power.mode;
    limits = struct('coastLoad_W',budget.power.peakLoad_W(powerMode == "S3"), ...
        'thrustLoad_W',budget.power.peakLoad_W(powerMode == "S1"), ...
        'deployLoad_W',budget.power.peakLoad_W(powerMode == "S2"));
    if unifiedLoads
        limits.coastLoad_W=q.coastLoad_W;
        limits.thrustLoad_W=q.thrustLoad_W;
        limits.deployLoad_W=q.deployLoad_W;
    end
    memory = struct('phase',"idle",'deploymentIssued',false);
    sailState = "stowed";
end
time = t;
state = x.';
labels = strings(1,1);
thrustHistory = false(1,1);
sailHistory = 0;
eventLog = struct('time_s',{},'type',{},'detail',{});
% 某些故障在起始时刻就发生，应先写入事件日志。
if ~isempty(caseConfig.policy.initialEventType)
    eventLog(end+1) = logEvent(0,caseConfig.policy.initialEventType, ...
        caseConfig.policy.initialEventDetail);
end
thrustOn_s = 0;
status = 'time_limit';
clockStart = tic;
solver = str2func(p.sim.solver);
while t < p.sim.maxDuration_s - 1e-8
    % 若片段刚好从阈值以下开始，立即切换，避免漏掉边界事件。
    if caseConfig.policy.watchSwitch && strcmp(phase,'pre_switch')
        [switchValue,~,~] = switchEvent(t,x,p);
        if switchValue <= 0
            phase = 'post_switch';
            eventLog(end+1) = logEvent(t,'switch','sail deployment commanded');
            eventLog = logSwitchFault(eventLog,t,caseConfig.policy);
        end
    end
    fuelAvailable = x(7) > p.sc.dryMass_kg + 1e-10;
    [dutyOn,nextDuty] = dutySchedule(t,p);
    powerBoundary = inf;
    if supervised
        if deploymentModel
            deployment=deploymentState(t,deployStarted_s,caseConfig);
            sailState=deployment.observation;
            if deployment.complete && ~deployFinished
                deployFinished=true;
                eventLog(end+1)=logEvent(t,'deployment_actual_complete','simulated mechanism ended; not sensor evidence');
            end
            if deployment.confirmed && ~any(strcmp({eventLog.type},'deployment_confirmed'))
                eventLog(end+1)=logEvent(t,'deployment_confirmed',char(sailState));
            end
            if deployment.timeout && ~any(strcmp({eventLog.type},'deployment_timeout'))
                eventLog(end+1)=logEvent(t,'deployment_timeout','feedback unknown; no automatic thrust fallback');
            end
        end
        obs = struct('retirementAuthorized',caseConfig.supervisor.retirementAuthorized, ...
            'powerAvailable_W',caseConfig.supervisor.powerAvailable_W, ...
            'attitudeReady',caseConfig.supervisor.attitudeReady, ...
            'thrusterHealthy',caseConfig.supervisor.thrusterHealthy, ...
            'fuelAvailable',fuelAvailable,'switchReached',strcmp(phase,'post_switch'), ...
            'reentryReached',false,'sailState',sailState);
        if powerCoupled
            if improvedControl
                decisionQ=q;
                decisionQ.step_s=q.controlPeriod_s;
                [candidatePower,generation_W,nextEclipse]=powerAvailability(t,battery_Wh,decisionQ);
                if t>=nextPowerDecision_s-1e-7
                    heldPower_W=candidatePower;
                    nextPowerDecision_s=min([t+q.controlPeriod_s,nextEclipse,nextDuty]);
                end
                obs.powerAvailable_W=heldPower_W;
            else
                [obs.powerAvailable_W,generation_W,nextEclipse] = powerAvailability(t,battery_Wh,q);
            end
            powerBoundary = min(t+q.step_s,nextEclipse);
            if improvedControl, powerBoundary=min(powerBoundary,nextPowerDecision_s); end
        end
        decisionLimits=limits;
        if unifiedLoads, decisionLimits.coastLoad_W=q.coastLoad_W; end
        if deploymentModel && sailState=="partial"
            decisionLimits.thrustLoad_W=limits.thrustLoad_W+5;
        end
        previousMemory=memory;
        [command,memory,reason] = deorbitSupervisor(obs,memory,decisionLimits);
        if deploymentModel && command.deploySail && ~canStartDeployment(battery_Wh,q,caseConfig)
            memory=previousMemory;
            command.deploySail=false; command.thrustOn=false; command.mode="safe";
            reason="DEPLOY_ENERGY_INSUFFICIENT";
        end
        if command.deploySail
            eventLog(end+1) = logEvent(t,'supervisor',char(reason));
            if deploymentModel
                deployStarted_s = t;
                eventLog(end+1) = logEvent(t,'deployment_started','waiting for simulated confirmation');
            else
                sailState = "deployed";
            end
            if ~strcmp(phase,'post_switch')
                phase = 'post_switch';
                eventLog(end+1) = logEvent(t,'deploy_early',char(reason));
            end
            obs.sailState = sailState;
            obs.switchReached = strcmp(phase,'post_switch');
            [command,memory,reason] = deorbitSupervisor(obs,memory,limits);
        end
        if deploymentModel
            deployment=deploymentState(t,deployStarted_s,caseConfig);
            powerBoundary=min(powerBoundary,deployment.nextBoundary);
            if deployment.active
                command.mode="deploying"; command.thrustOn=false;
                reason="DEPLOYMENT_IN_PROGRESS";
            end
        end
        eligible = command.thrustOn && fuelAvailable && p.sim.useThrust && ...
            p.thruster.thrust_N > 0;
        mode = struct('phase',char(command.mode), ...
            'sailFraction',double(sailState == "deployed"), ...
            'thrustEligible',eligible,'thrustOn',eligible && dutyOn, ...
            'watchSwitch',strcmp(phase,'pre_switch'));
        if improvedControl && sailState=="partial", mode.sailFraction=0.5; end
        if deploymentModel, mode.sailFraction=deployment.fraction; end
        if isempty(eventLog) || ~strcmp(eventLog(end).type,'supervisor') || ...
                ~strcmp(eventLog(end).detail,char(reason))
            eventLog(end+1) = logEvent(t,'supervisor',char(reason));
        end
    else
        mode = deorbitStateMachine(caseConfig.policy,phase,dutyOn,fuelAvailable,p);
    end
    labels(end) = string(mode.phase);
    thrustHistory(end) = mode.thrustOn;
    sailHistory(end) = mode.sailFraction;
    % 没有推进资格时，无需在推力占空比边界中断积分。
    if ~mode.thrustEligible, nextDuty = inf; end
    tEnd = min([p.sim.maxDuration_s,nextDuty,powerBoundary]);
    % 避免浮点误差造成零长度的积分区间。
    if tEnd <= t + 1e-7
        tEnd = min(p.sim.maxDuration_s,t + p.thruster.dutyPeriod_s*1e-7);
    end
    enableSwitch = mode.watchSwitch;
    opts = odeset('RelTol',p.sim.relTol,'AbsTol',p.sim.absTol, ...
        'MaxStep',p.sim.maxStep_s, ...
        'Events',@(tt,xx) allEvents(tt,xx,p,enableSwitch,mode.thrustOn));
    dynamics=@(tt,xx) orbitalDynamics(tt,xx,mode,p);
    if deploymentModel && deployment.active
        dynamics=@(tt,xx) deploymentDynamics(tt,xx,mode,p,deployStarted_s,caseConfig);
    end
    [tt,xx,te,~,ie] = solver(dynamics, ...
        [t tEnd],x,opts);
    if numel(tt) < 2 || tt(end) <= t
        error('Propagation did not advance at t=%g s.',t);
    end
    if powerCoupled
        % 每个供电片段不超过 60 秒，保存片段端点；ODE内部步长及全部事件根不变。
        % 避免频繁重启的内部采样导致巨大输出。峰值/平均阻力仅为此采样分辨率的估计。
        xx = xx([1 end],:);
        tt = tt([1 end]);
    end
    % 当前片段的首点与上一片段末点重合，只追加后续采样点。
    time = [time;tt(2:end)]; %#ok<AGROW>
    state = [state;xx(2:end,:)]; %#ok<AGROW>
    labels = [labels;repmat(string(mode.phase),numel(tt)-1,1)]; %#ok<AGROW>
    thrustHistory = [thrustHistory;repmat(mode.thrustOn,numel(tt)-1,1)]; %#ok<AGROW>
    sailHistory = [sailHistory;repmat(mode.sailFraction,numel(tt)-1,1)]; %#ok<AGROW>
    if deploymentModel
        for sample=1:numel(tt)-1
            ds=deploymentState(tt(sample+1),deployStarted_s,caseConfig);
            sailHistory(end-numel(tt)+1+sample)=ds.fraction;
        end
    end
    if mode.thrustOn, thrustOn_s = thrustOn_s + tt(end)-t; end
    if powerCoupled
        load_W = q.coastLoad_W;
        if mode.thrustOn, load_W = q.thrustLoad_W; end
        if unifiedLoads
            load_W = modePowerLoad(string(mode.phase),mode.thrustOn,q);
            % 半展帆补推包含帆监测额外负载，避免沿用单独推进功率。
            if mode.thrustOn && sailState=="partial", load_W=load_W+5; end
        end
        [battery_Wh,unmet] = advanceBattery(battery_Wh,generation_W,load_W,tt(end)-t,q);
        powerTrace(end+1,:)=[t tt(end) generation_W load_W battery_Wh unmet double(mode.thrustOn)]; %#ok<AGROW>
        batteryMinimum_Wh = min(batteryMinimum_Wh,battery_Wh);
        unmetBase_Wh = unmetBase_Wh+unmet;
    end
    t = tt(end);
    x = xx(end,:).';
    % 再入、切换和燃料耗尽为控制事件；窗口穿越仅用于事后分析。
    if ~isempty(ie)
        for j = 1:numel(ie)
            switch ie(j)
                case 1
                    status = 'reentry';
                    eventLog(end+1) = logEvent(te(j),'reentry','downward 120 km crossing');
                case 2
                    phase = 'post_switch';
                    eventLog(end+1) = logEvent(te(j),'switch','sail deployment commanded');
                    eventLog = logSwitchFault(eventLog,te(j),caseConfig.policy);
                case 3
                    % 钳到干质量并停用后续推力，避免数值误差透支燃料。
                    x(7) = p.sc.dryMass_kg;
                    state(end,7) = x(7);
                    eventLog(end+1) = logEvent(te(j),'fuel_exhausted','thrust disabled');
                case 4
                    eventLog = appendUniqueEvent(eventLog,te(j),'window_down');
                case 5
                    eventLog = appendUniqueEvent(eventLog,te(j),'window_up');
            end
        end
    end
    if powerCoupled && unmetBase_Wh > 1e-7
        status = 'power_failure';
        eventLog(end+1) = logEvent(t,'power_failure','essential load could not be supplied');
        break;
    end
    if strcmp(status,'reentry'), break; end
end
% 同时保存案例配置、运行环境和各时刻状态，便于结果复现与绘图。
result.meta = struct('matlabVersion',version,'runTime',char(datetime('now')), ...
    'gitCommit',gitRevision(),'randomSeed',NaN);
result.config = struct('case',caseConfig,'parameters',p);
result.time_s = time;
result.state_SI = state;
result.mode = labels;
result.thrustOn = thrustHistory;
result.sailFraction = sailHistory;
result.eventLog = eventLog;
result.status = status;
result.thrustOn_s = thrustOn_s;
result.runtime_s = toc(clockStart);
if powerCoupled
    result.power = struct('assumptions',q,'finalBattery_Wh',battery_Wh, ...
        'minimumBattery_Wh',batteryMinimum_Wh,'unmetBaseEnergy_Wh',unmetBase_Wh, ...
        'status','team_assumption');
    result.power.history=array2table(powerTrace,'VariableNames', ...
        {'start_s','end_s','generation_W','load_W','batteryEnd_Wh','unmet_Wh','thrustOn'});
end
result.metrics = computeMetrics(result,p);
end

function [value,terminal,direction] = allEvents(t,x,p,enableSwitch,enableDry)
% 事件序号为再入、切换、干质量、窗口下穿和窗口上穿。
[r,tr,dr] = reentryEvent(t,x,p);
[w,tw,dw] = windowBoundaryEvents(t,x,p);
value = [r;1;1;w];
terminal = [tr;1;1;tw];
direction = [dr;-1;-1;dw];
if enableSwitch
    [s,ts,ds] = switchEvent(t,x,p);
    value(2) = s; terminal(2) = ts; direction(2) = ds;
end
if enableDry
    value(3) = x(7)-p.sc.dryMass_kg;
end
end

function e = logEvent(t,kind,detail)
e = struct('time_s',t,'type',kind,'detail',detail);
end

function events = appendUniqueEvent(events,t,kind)
% 相邻 ODE 片段可能在同一根处重复报告非终止事件。
if ~isempty(events)
    same = strcmp({events.type},kind) & abs([events.time_s]-t) < 1e-4;
    if any(same), return; end
end
events(end+1) = logEvent(t,kind,'osculating apogee at window lower boundary');
end

function events = logSwitchFault(events,t,policy)
if ~isempty(policy.switchEventType)
    events(end+1) = logEvent(t,policy.switchEventType, ...
        policy.switchEventDetail);
end
end

function revision = gitRevision()
% 仅在工程位于 Git 仓库中时记录提交号，其他情况不影响仿真。
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
[status,out] = system(sprintf('git -C "%s" rev-parse --short HEAD 2>nul',root));
revision = 'unavailable';
if status == 0, revision = strtrim(out); end
end
