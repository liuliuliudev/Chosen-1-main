function summaries = run_sensitivity(p,outDir)
%RUN_SENSITIVITY 分别扫描大气密度、帆面积和推力的单因素变化。
if nargin < 1, p = baseline_case(); end
if nargin < 2
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'results','tables');
end
groups = {'density','sail','thrust'};
summaries = struct();
% 每组只改变一个参数，并分别保存汇总表和图。
for k = 1:numel(groups)
    [results,summary] = runCaseGroup(groups{k},p,outDir);
    summaries.(groups{k}) = summary;
    plotCoreResults(results,groups{k},fileparts(outDir));
end
end
