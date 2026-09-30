function [results,summary] = run_switch_scan(p,outDir)
%RUN_SWITCH_SCAN 比较七个预设展帆切换高度的结果。
if nargin < 1, p = baseline_case(); end
if nargin < 2
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'results','tables');
end
[results,summary] = runCaseGroup('switch',p,outDir);
tradeoff = classifySwitchTradeoff(summary,p);
writetable(tradeoff,fullfile(outDir,'switch_tradeoff.csv'));
disp(tradeoff(:,{'caseId','selectionStatus','dominatedBy'}));
plotCoreResults(results,'tradeoff',fileparts(outDir));
plotSwitchWindowScan(results,fileparts(outDir));
plotSwitchTradeoff(tradeoff,fileparts(outDir));
end
