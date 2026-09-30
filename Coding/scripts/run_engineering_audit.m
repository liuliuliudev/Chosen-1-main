function report = run_engineering_audit(p, results, outDir, budgetFile)
%RUN_ENGINEERING_AUDIT 将独立预算与已有案例结果合成为可检查的报告。
% 本脚本是传播结果到预算计算的适配层；预算算法不认识 result 结构。
if nargin < 1 || isempty(p), p = baseline_case(); end
if nargin < 2, results = {}; end
if nargin < 3 || isempty(outDir)
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
        'results','tables');
end
if nargin < 4, budgetFile = []; end
if ~isfolder(outDir), mkdir(outDir); end
ledger = loadEngineeringBudget(budgetFile);
n = numel(results);
caseId = strings(n,1);
thrustOn_s = zeros(n,1);
propUsed_kg = zeros(n,1);
for k = 1:n
    caseId(k) = string(results{k}.config.case.id);
    thrustOn_s(k) = results{k}.thrustOn_s;
    propUsed_kg(k) = results{k}.metrics.propUsed_kg;
end
operations = table(caseId,thrustOn_s,propUsed_kg);
report = computeEngineeringBudget(p,ledger,operations);

% 固定文件名使后续图表和证据索引能够引用；原始预算表保持独立。
writetable(report.mass,fullfile(outDir,'engineering_mass.csv'));
writetable(report.power,fullfile(outDir,'engineering_power.csv'));
writetable(report.thruster,fullfile(outDir,'engineering_thruster.csv'));
writetable(report.conditions,fullfile(outDir,'engineering_conditions.csv'));
writetable(report.operations,fullfile(outDir,'engineering_operations.csv'));
summary = table(report.status,report.effectiveAddedArea_m2, ...
    'VariableNames',{'status','assumedEffectiveAddedArea_m2'});
writetable(summary,fullfile(outDir,'engineering_summary.csv'));
disp(summary);
end
