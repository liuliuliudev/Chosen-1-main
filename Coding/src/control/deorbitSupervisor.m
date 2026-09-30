function [command, nextMemory, reasonCode] = deorbitSupervisor(obs, memory, limits)
%DEORBITSUPERVISOR 基于模拟观测给出一次离轨监督决策。
% 输入不是传感器实测：obs 由外部情景提供，limits 由资源预算提供。
% 本函数不读取轨迹或未来窗口退出时刻，也不改变连续动力学。
% 展帆命令只发一次；发令后仍未确认展开时进入安全模式。
requiredObs = {'retirementAuthorized','powerAvailable_W','attitudeReady', ...
    'thrusterHealthy','fuelAvailable','switchReached','reentryReached','sailState'};
requiredLimits = {'coastLoad_W','thrustLoad_W','deployLoad_W'};
if ~isstruct(obs) || ~all(isfield(obs,requiredObs)) || ...
        ~isstruct(memory) || ~all(isfield(memory,{'phase','deploymentIssued'})) || ...
        ~isstruct(limits) || ~all(isfield(limits,requiredLimits)) || ...
        ~all(isfinite([limits.coastLoad_W,limits.thrustLoad_W, ...
        limits.deployLoad_W])) || ...
        any([limits.coastLoad_W,limits.thrustLoad_W,limits.deployLoad_W] < 0)
    error('Supervisor:InvalidInput','Supervisor input or limits are incomplete.');
end
flags = {'retirementAuthorized','attitudeReady','thrusterHealthy', ...
    'fuelAvailable','switchReached','reentryReached'};
for k = 1:numel(flags)
    v = obs.(flags{k});
    if ~isscalar(v) || ~(isnumeric(v) || islogical(v)) || ...
            (~isnan(double(v)) && ~ismember(double(v),[0 1]))
        error('Supervisor:InvalidInput','Observation flag is invalid.');
    end
end
if ~isscalar(obs.powerAvailable_W) || ~isnumeric(obs.powerAvailable_W) || ...
        (~isnan(obs.powerAvailable_W) && obs.powerAvailable_W < 0) || ...
        ~isscalar(memory.deploymentIssued) || ...
        ~islogical(memory.deploymentIssued) || ...
        ~ismember(string(obs.sailState),["stowed","deployed","partial", ...
        "failed","unknown"])
    error('Supervisor:InvalidInput','Observation state or memory is invalid.');
end

command = struct('mode',"safe",'thrustOn',false, ...
    'deploySail',false,'safeMode',true);
nextMemory = memory;
nextMemory.phase = "safe";
reasonCode = "OBSERVATION_UNKNOWN";

% 终点优先于其他条件；随后检查许可、姿态及维持基础负载的电力。
if isnan(double(obs.reentryReached)), return; end
if obs.reentryReached
    command = makeCommand("complete",false,false,false);
    reasonCode = "MODEL_ENDPOINT_REACHED";
elseif isnan(double(obs.retirementAuthorized))
    return
elseif ~obs.retirementAuthorized
    reasonCode = "AUTHORIZATION_DENIED";
elseif isnan(double(obs.attitudeReady))
    return
elseif ~obs.attitudeReady
    reasonCode = "ATTITUDE_UNAVAILABLE";
elseif ~isfinite(obs.powerAvailable_W)
    reasonCode = "POWER_UNKNOWN";
elseif obs.powerAvailable_W < limits.coastLoad_W
    reasonCode = "BASE_POWER_INSUFFICIENT";
else
    sailState = string(obs.sailState);
    if sailState == "unknown"
        reasonCode = "SAIL_STATE_UNKNOWN";
    elseif sailState == "deployed"
        command = makeCommand("sail",false,false,false);
        reasonCode = "SAIL_CONFIRMED";
    elseif memory.deploymentIssued && sailState == "stowed"
        reasonCode = "DEPLOYMENT_UNCONFIRMED";
    elseif sailState == "partial" || sailState == "failed"
        [command,reasonCode] = fallbackThrust(obs,limits);
    elseif isnan(double(obs.switchReached)) || ...
            isnan(double(obs.thrusterHealthy)) || ...
            isnan(double(obs.fuelAvailable))
        reasonCode = "OBSERVATION_UNKNOWN";
    elseif obs.switchReached || ~obs.thrusterHealthy || ~obs.fuelAvailable
        if obs.powerAvailable_W >= limits.deployLoad_W
            command = makeCommand("deploy",false,true,false);
            nextMemory.deploymentIssued = true;
            if obs.switchReached
                reasonCode = "SWITCH_REACHED";
            elseif ~obs.thrusterHealthy
                reasonCode = "THRUSTER_FAILED_DEPLOY_EARLY";
            else
                reasonCode = "FUEL_EXHAUSTED_DEPLOY_EARLY";
            end
        else
            reasonCode = "DEPLOY_POWER_INSUFFICIENT";
        end
    elseif obs.powerAvailable_W >= limits.thrustLoad_W
        command = makeCommand("thrust",true,false,false);
        reasonCode = "THRUST_PERMITTED";
    else
        reasonCode = "THRUST_POWER_INSUFFICIENT";
    end
end
nextMemory.phase = command.mode;
end

function [command, reasonCode] = fallbackThrust(obs, limits)
% 半展或失展后的补推只在健康、燃料、电力全部可用时发出。
command = makeCommand("safe",false,false,true);
reasonCode = "NO_RECOVERY_RESOURCE";
if isnan(double(obs.thrusterHealthy)) || isnan(double(obs.fuelAvailable))
    reasonCode = "OBSERVATION_UNKNOWN";
elseif obs.thrusterHealthy && obs.fuelAvailable
    if obs.powerAvailable_W >= limits.thrustLoad_W
        command = makeCommand("fallback_thrust",true,false,false);
        reasonCode = "SAIL_FAULT_THRUST_FALLBACK";
    else
        reasonCode = "THRUST_POWER_INSUFFICIENT";
    end
end
end

function command = makeCommand(mode, thrustOn, deploySail, safeMode)
command = struct('mode',mode,'thrustOn',thrustOn, ...
    'deploySail',deploySail,'safeMode',safeMode);
end
