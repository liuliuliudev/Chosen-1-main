function [results,summary] = run_fault_cases(p,outDir)
%RUN_FAULT_CASES 将正常 P 策略与四个预设故障情景对比。
if nargin < 1, p = baseline_case(); end
if nargin < 2
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'results','tables');
end
[faultResults,~] = runCaseGroup('faults',p,outDir);
normal = experiment_matrix('baselines');
% 故障组本身不含正常 P，比较表中额外补入正常案例。
results = [{propagateCase(normal(4),p)};faultResults];
summary = summarizeRuns(results);
save(fullfile(outDir,'fault_comparison.mat'),'results','summary','-v7.3');
writetable(summary,fullfile(outDir,'fault_comparison.csv'));
plotCoreResults(results,'faults',fileparts(outDir));
end
