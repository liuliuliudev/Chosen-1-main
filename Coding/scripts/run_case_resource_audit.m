function audit = run_case_resource_audit(outDir, pBase, budgetFile)
%RUN_CASE_RESOURCE_AUDIT 从已有 MAT 结果生成全案例资源边界表。
% 只读取 runCaseGroup 已保存的轨迹；不重新积分或改动实验配置。
if nargin < 1 || isempty(outDir)
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
        'results','tables');
end
if nargin < 2 || isempty(pBase), pBase = baseline_case(); end
if nargin < 3, budgetFile = []; end
ledger = loadEngineeringBudget(budgetFile);
groups = {'baselines','switch','density','sail','thrust','faults'};
rows = cell(0,1);
for g = 1:numel(groups)
    source = fullfile(outDir,[groups{g} '_results.mat']);
    saved = load(source,'results');
    for k = 1:numel(saved.results)
        result = saved.results{k};
        facts = struct('caseId',string(result.config.case.id), ...
            'group',string(groups{g}), ...
            'thrustOn_s',result.thrustOn_s, ...
            'propUsed_kg',result.metrics.propUsed_kg, ...
            'maxSailFraction',max(result.sailFraction), ...
            'concurrentThrustSail', ...
            any(result.thrustOn & result.sailFraction > 0));
        rows{end+1,1} = assessCaseResources( ...
            result.config.parameters,pBase,ledger,facts); %#ok<AGROW>
    end
end
audit = vertcat(rows{:});
writetable(audit,fullfile(outDir,'resource_case_audit.csv'));
disp(audit(:,{'caseId','status','reasonCodes'}));
end
