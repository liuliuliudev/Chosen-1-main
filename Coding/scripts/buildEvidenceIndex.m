function [index, context] = buildEvidenceIndex(root, p, resultRoot)
%BUILDEVIDENCEINDEX 为当前一次运行建立结果到输入与脚本的索引。
% 索引只声明文件是否存在及其来源，不把候选物理输入标成已认证。
% 参数和预算表另存 MAT 快照，避免后来编辑配置后无法解释旧结果。
if nargin < 1 || isempty(root)
    root = fileparts(fileparts(mfilename('fullpath')));
end
if nargin < 2 || isempty(p), p = baseline_case(); end
if nargin < 3 || isempty(resultRoot)
    resultRoot = fullfile(root,'results');
end
root = char(root);
resultRoot = char(resultRoot);
if ~startsWith(resultRoot,[root filesep])
    error('EvidenceIndex:InvalidOutput','Result directory must be inside the project.');
end
resultPrefix = strrep(resultRoot(numel(root)+2:end),filesep,'/');
outDir = fullfile(resultRoot,'tables');
if ~isfolder(outDir), mkdir(outDir); end
ledger = loadEngineeringBudget();
budget = computeEngineeringBudget(p,ledger);
revision = 'unavailable';
[gitStatus,gitOutput] = system(sprintf( ...
    'git -C "%s" rev-parse HEAD 2>nul',fileparts(root)));
if gitStatus == 0, revision = strtrim(gitOutput); end
[treeStatus,treeOutput] = system(sprintf( ...
    'git -C "%s" status --porcelain --untracked-files=no 2>nul',fileparts(root)));
workingTreeState = "unavailable";
if treeStatus == 0
    workingTreeState = "clean";
    if ~isempty(strtrim(treeOutput)), workingTreeState = "modified"; end
end
matlabVersion = string(version);
gitCommit = string(revision);
generatedAt = string(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
timeZone = "Asia/Shanghai";
atmosphereStatus = "candidate_unverified";
budgetStatus = budget.status;
supervisorStatus = "candidate_simulation";

artifact = strings(0,1); producer = strings(0,1); role = strings(0,1);
groups = ["baselines","switch","density","sail","thrust","faults","supervised","hardware","power"];
for k = 1:numel(groups)
    artifact(end+1,1) = resultPrefix+"/tables/"+groups(k)+"_results.mat";
    producer(end+1,1) = "runCaseGroup";
    role(end+1,1) = "case_config_and_trajectory";
    artifact(end+1,1) = resultPrefix+"/tables/"+groups(k)+"_summary.csv";
    producer(end+1,1) = "runCaseGroup";
    role(end+1,1) = "case_metrics";
end
tableNames = ["fault_comparison.csv","numerical_check.csv", ...
    "switch_diagnostic.csv","switch_tradeoff.csv", ...
    "engineering_mass.csv","engineering_power.csv", ...
    "engineering_thruster.csv","engineering_conditions.csv", ...
    "engineering_operations.csv","engineering_summary.csv", ...
    "resource_case_audit.csv","supervisor_scenarios.csv","input_audit.csv", ...
    "power_screen.csv","power_resources.csv","power_numerical_check.csv"];
tableProducers = ["run_fault_cases","run_numerical_check", ...
    "analyzeSwitchNeighborhood","run_switch_scan", ...
    repmat("run_engineering_audit",1,6), ...
    "run_case_resource_audit","run_supervisor_scenarios","run_input_audit", ...
    "run_power_screen","runProjectExperiments","run_power_numerical_check"];
for k = 1:numel(tableNames)
    artifact(end+1,1) = resultPrefix+"/tables/"+tableNames(k);
    producer(end+1,1) = tableProducers(k);
    role(end+1,1) = "analysis_table";
end
figures = ["baselines.png","baseline_metrics.png","P_timeline.png", ...
    "window_exit.png","tradeoff.png","switch_window_scan.png", ...
    "switch_tradeoff.png","density.png","sail.png", ...
    "thrust.png","faults.png"];
figureProducers = [repmat("plotCoreResults",1,3), ...
    "plotWindowResults","plotCoreResults", ...
    "plotSwitchWindowScan","plotSwitchTradeoff", ...
    repmat("plotCoreResults",1,4)];
for k = 1:numel(figures)
    artifact(end+1,1) = resultPrefix+"/figures/"+figures(k);
    producer(end+1,1) = figureProducers(k);
    role(end+1,1) = "result_figure";
end
artifact(end+1,1) = resultPrefix+"/videos/P_altitude.mp4";
producer(end+1,1) = "makeOrbitVideo";
role(end+1,1) = "result_video";
inputs = ["config/baseline_case.m", ...
    "config/powerScenario.m", ...
    "config/parameter_sources.csv", ...
    "config/engineering_budget_candidate.csv", ...
    "data/processed/exponential_atmosphere_candidate.csv", ...
    "data/processed/atmosphere_source_comparison.csv", ...
    "data/raw/public_20260930_130029/vallado_data.dat", ...
    "data/raw/public_20260930_130029/BHT_200_v10.pdf"];
for k = 1:numel(inputs)
    artifact(end+1,1) = inputs(k);
    producer(end+1,1) = "project_input";
    role(end+1,1) = "candidate_input";
end

logs = dir(fullfile(resultRoot,'logs','*.txt'));
if ~isempty(logs)
    [~,latest] = max([logs.datenum]);
    artifact(end+1,1) = resultPrefix+"/logs/"+string(logs(latest).name);
    producer(end+1,1) = "MATLAB execution";
    role(end+1,1) = "execution_log";
end

snapshot = struct('parameters',p,'budgetLedger',ledger, ...
    'matlabVersion',matlabVersion,'gitCommit',gitCommit, ...
    'workingTreeState',workingTreeState, ...
    'generatedAt',generatedAt,'timeZone',timeZone);
save(fullfile(outDir,'evidence_snapshot.mat'),'snapshot');
artifact(end+1,1) = resultPrefix+"/tables/evidence_snapshot.mat";
producer(end+1,1) = "buildEvidenceIndex";
role(end+1,1) = "parameter_snapshot";

exists = false(numel(artifact),1);
bytes = NaN(numel(artifact),1);
for k = 1:numel(artifact)
    fullPath = fullfile(root,strrep(artifact(k),'/',filesep));
    if isfile(fullPath)
        info = dir(fullPath);
        exists(k) = true;
        bytes(k) = info.bytes;
    end
end
index = table(artifact,producer,role,exists,bytes);
writetable(index,fullfile(outDir,'evidence_index.csv'));
missingCount = sum(~exists);
indexStatus = "complete_with_candidates";
if missingCount > 0, indexStatus = "incomplete"; end
context = table(generatedAt,timeZone,matlabVersion,gitCommit,workingTreeState,atmosphereStatus, ...
    budgetStatus,supervisorStatus,missingCount,indexStatus);
writetable(context,fullfile(outDir,'evidence_context.csv'));
disp(context);
end
