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
if supervised
    ledger = loadEngineeringBudget();
    budget = computeEngineeringBudget(p,ledger);
    powerMode = budget.power.mode;
    limits = struct('coastLoad_W',budget.power.peakLoad_W(powerMode == "S3"), ...
        'thrustLoad_W',budget.power.peakLoad_W(powerMode == "S1"), ...
        'deployLoad_W',budget.power.peakLoad_W(powerMode == "S2"));
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
    if supervised
        obs = struct('retirementAuthorized',caseConfig.supervisor.retirementAuthorized, ...
            'powerAvailable_W',caseConfig.supervisor.powerAvailable_W, ...
            'attitudeReady',caseConfig.supervisor.attitudeReady, ...
            'thrusterHealthy',caseConfig.supervisor.thrusterHealthy, ...
            'fuelAvailable',fuelAvailable,'switchReached',strcmp(phase,'post_switch'), ...
            'reentryReached',false,'sailState',sailState);
        [command,memory,reason] = deorbitSupervisor(obs,memory,limits);
        if command.deploySail
            eventLog(end+1) = logEvent(t,'supervisor',char(reason));
            sailState = "deployed";
            if ~strcmp(phase,'post_switch')
                phase = 'post_switch';
                eventLog(end+1) = logEvent(t,'deploy_early',char(reason));
            end
            obs.sailState = sailState;
            obs.switchReached = strcmp(phase,'post_switch');
            [command,memory,reason] = deorbitSupervisor(obs,memory,limits);
        end
        eligible = command.thrustOn && fuelAvailable && p.sim.useThrust && ...
            p.thruster.thrust_N > 0;
        mode = struct('phase',char(command.mode), ...
            'sailFraction',double(sailState == "deployed"), ...
            'thrustEligible',eligible,'thrustOn',eligible && dutyOn, ...
            'watchSwitch',strcmp(phase,'pre_switch'));
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
    tEnd = min(p.sim.maxDuration_s,nextDuty);
    % 避免浮点误差造成零长度的积分区间。
    if tEnd <= t + 1e-7
        tEnd = min(p.sim.maxDuration_s,t + p.thruster.dutyPeriod_s*1e-7);
    end
    enableSwitch = mode.watchSwitch;
    opts = odeset('RelTol',p.sim.relTol,'AbsTol',p.sim.absTol, ...
        'MaxStep',p.sim.maxStep_s, ...
        'Events',@(tt,xx) allEvents(tt,xx,p,enableSwitch,mode.thrustOn));
    [tt,xx,te,~,ie] = solver(@(tt,xx) orbitalDynamics(tt,xx,mode,p), ...
        [t tEnd],x,opts);
    if numel(tt) < 2 || tt(end) <= t
        error('Propagation did not advance at t=%g s.',t);
    end
    % 当前片段的首点与上一片段末点重合，只追加后续采样点。
    time = [time;tt(2:end)]; %#ok<AGROW>
    state = [state;xx(2:end,:)]; %#ok<AGROW>
    labels = [labels;repmat(string(mode.phase),numel(tt)-1,1)]; %#ok<AGROW>
    thrustHistory = [thrustHistory;repmat(mode.thrustOn,numel(tt)-1,1)]; %#ok<AGROW>
    sailHistory = [sailHistory;repmat(mode.sailFraction,numel(tt)-1,1)]; %#ok<AGROW>
    if mode.thrustOn, thrustOn_s = thrustOn_s + tt(end)-t; end
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
