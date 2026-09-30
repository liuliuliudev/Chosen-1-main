function decisions = run_supervisor_scenarios(p, outDir, budgetFile)
%RUN_SUPERVISOR_SCENARIOS 用人工观测展示监督器的确定性动作和理由。
% 这些观测并非实测遥测；输出只验证逻辑，不生成新的轨道案例。
if nargin < 1 || isempty(p), p = baseline_case(); end
if nargin < 2 || isempty(outDir)
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
        'results','tables');
end
if nargin < 3, budgetFile = []; end
ledger = loadEngineeringBudget(budgetFile);
budget = computeEngineeringBudget(p,ledger);
mode = budget.power.mode;
limits = struct('coastLoad_W',budget.power.peakLoad_W(mode == "S3"), ...
    'thrustLoad_W',budget.power.peakLoad_W(mode == "S1"), ...
    'deployLoad_W',budget.power.peakLoad_W(mode == "S2"));
if ~all(isfinite([limits.coastLoad_W,limits.thrustLoad_W, ...
        limits.deployLoad_W]))
    error('Supervisor:MissingBudget','Candidate power loads must be available.');
end
available = budget.power.available_W(mode == "S1");
base = struct('retirementAuthorized',true,'powerAvailable_W',available, ...
    'attitudeReady',true,'thrusterHealthy',true,'fuelAvailable',true, ...
    'switchReached',false,'reentryReached',false,'sailState',"stowed");
memory = struct('phase',"idle",'deploymentIssued',false);
id = ["nominal_thrust";"switch_deploy";"deploy_unconfirmed"; ...
    "sail_confirmed";"authorization_denied";"low_power"; ...
    "attitude_fault";"thruster_fault";"half_sail"; ...
    "sail_failed";"fuel_exhausted";"unknown_power";"endpoint"];
n = numel(id);
observations = repmat(base,n,1);
memories = repmat(memory,n,1);
observations(2).switchReached = true;
observations(3).switchReached = true;
memories(3).deploymentIssued = true;
observations(4).sailState = "deployed";
observations(5).retirementAuthorized = false;
observations(6).powerAvailable_W = limits.coastLoad_W-1;
observations(7).attitudeReady = false;
observations(8).thrusterHealthy = false;
observations(9).sailState = "partial";
observations(10).sailState = "failed";
observations(11).fuelAvailable = false;
observations(12).powerAvailable_W = NaN;
observations(13).reentryReached = true;

commandMode = strings(n,1);
thrustOn = false(n,1); deploySail = false(n,1);
safeMode = false(n,1); nextPhase = strings(n,1);
reasonCode = strings(n,1); inputSailState = strings(n,1);
inputPower_W = NaN(n,1);
for k = 1:n
    [command,nextMemory,reasonCode(k)] = deorbitSupervisor( ...
        observations(k),memories(k),limits);
    commandMode(k) = command.mode;
    thrustOn(k) = command.thrustOn;
    deploySail(k) = command.deploySail;
    safeMode(k) = command.safeMode;
    nextPhase(k) = nextMemory.phase;
    inputSailState(k) = observations(k).sailState;
    inputPower_W(k) = observations(k).powerAvailable_W;
end
scenarioId = id;
assumptionStatus = repmat("candidate_simulation",n,1);
decisions = table(scenarioId,inputSailState,inputPower_W,commandMode, ...
    thrustOn,deploySail,safeMode,nextPhase,reasonCode,assumptionStatus);
writetable(decisions,fullfile(outDir,'supervisor_scenarios.csv'));
disp(decisions(:,{'scenarioId','commandMode','reasonCode'}));
end
