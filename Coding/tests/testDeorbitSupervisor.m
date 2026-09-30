function testDeorbitSupervisor()
%TESTDEORBITSUPERVISOR 检查许可、能源、故障和一次性展帆的优先级。
limits = struct('coastLoad_W',215,'thrustLoad_W',560,'deployLoad_W',240);
obs = struct('retirementAuthorized',true,'powerAvailable_W',650, ...
    'attitudeReady',true,'thrusterHealthy',true,'fuelAvailable',true, ...
    'switchReached',false,'reentryReached',false,'sailState',"stowed");
memory = struct('phase',"idle",'deploymentIssued',false);
[command,next,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.thrustOn && ~command.deploySail && reason == "THRUST_PERMITTED");
assert(~next.deploymentIssued && memory.phase == "idle");

obs.switchReached = true;
[command,next,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.deploySail && ~command.thrustOn && reason == "SWITCH_REACHED");
assert(next.deploymentIssued);
[command,~,reason] = deorbitSupervisor(obs,next,limits);
assert(~command.deploySail && command.safeMode && ...
    reason == "DEPLOYMENT_UNCONFIRMED");
obs.sailState = "deployed";
[command,~,reason] = deorbitSupervisor(obs,next,limits);
assert(~command.thrustOn && ~command.safeMode && reason == "SAIL_CONFIRMED");

obs = resetObservation(obs);
obs.retirementAuthorized = false;
[command,~,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.safeMode && ~command.thrustOn && reason == "AUTHORIZATION_DENIED");
obs.retirementAuthorized = true;
obs.attitudeReady = false;
[command,~,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.safeMode && reason == "ATTITUDE_UNAVAILABLE");
obs.attitudeReady = true;
obs.powerAvailable_W = 500;
[command,~,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.safeMode && reason == "THRUST_POWER_INSUFFICIENT");
obs.powerAvailable_W = 650;
obs.thrusterHealthy = false;
[command,~,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.deploySail && reason == "THRUSTER_FAILED_DEPLOY_EARLY");
obs.thrusterHealthy = true;
obs.fuelAvailable = false;
[command,~,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.deploySail && reason == "FUEL_EXHAUSTED_DEPLOY_EARLY");

obs.fuelAvailable = true;
obs.sailState = "partial";
[command,~,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.thrustOn && reason == "SAIL_FAULT_THRUST_FALLBACK");
obs.sailState = "failed";
obs.fuelAvailable = false;
[command,~,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.safeMode && reason == "NO_RECOVERY_RESOURCE");
obs.fuelAvailable = true;
obs.powerAvailable_W = NaN;
[command,~,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.safeMode && reason == "POWER_UNKNOWN");
obs.reentryReached = true;
[command,~,reason] = deorbitSupervisor(obs,memory,limits);
assert(command.mode == "complete" && reason == "MODEL_ENDPOINT_REACHED");
end

function obs = resetObservation(obs)
obs.switchReached = false;
obs.sailState = "stowed";
end
