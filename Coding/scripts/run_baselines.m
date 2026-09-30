function [results,summary] = run_baselines(p,outDir)
%RUN_BASELINES 用同一套基准参数比较 B0、B1、B2 和 P 策略。
if nargin < 1, p = baseline_case(); end
if nargin < 2, outDir = defaultOutput(); end
[results,summary] = runCaseGroup('baselines',p,outDir);
plotCoreResults(results,'baselines',fileparts(outDir));
plotWindowResults(results,fileparts(outDir));
end

function out = defaultOutput()
out = fullfile(fileparts(fileparts(mfilename('fullpath'))),'results','tables');
end
