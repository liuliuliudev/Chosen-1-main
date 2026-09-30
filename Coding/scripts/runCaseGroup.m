function [results,summary] = runCaseGroup(group,p,outDir)
%RUNCASEGROUP 逐个运行固定案例组，并保留每个案例的完整结果。
if nargin < 2 || isempty(p), p = baseline_case(); end
if nargin < 3 || isempty(outDir)
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
        'results','tables');
end
if ~isfolder(outDir), mkdir(outDir); end
cases = experiment_matrix(group);
results = cell(numel(cases),1);
% 每个案例独立传播，避免上一个案例的状态影响下一个案例。
for k = 1:numel(cases)
    fprintf('%s: %s (%d/%d)\n',group,cases(k).id,k,numel(cases));
    results{k} = propagateCase(cases(k),p);
end
summary = summarizeRuns(results);
% MAT 保存轨迹等完整结果，CSV 只保存便于查看的指标汇总。
save(fullfile(outDir,[group '_results.mat']),'results','summary','-v7.3');
writetable(summary,fullfile(outDir,[group '_summary.csv']));
disp(summary);
end
