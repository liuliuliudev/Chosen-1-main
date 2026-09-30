function plotWindowResults(results, resultsRoot)
%PLOTWINDOWRESULTS 对照原窗口退出与到达 120 km 的时间及删失。
if nargin < 2
    resultsRoot = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
        'results');
end
figDir = fullfile(resultsRoot,'figures');
if ~isfolder(figDir), mkdir(figDir); end
f = figure('Visible','off','Color','w');
hold on
hExit = semilogx(NaN,NaN,'o','Color',[0.05 0.48 0.35], ...
    'MarkerFaceColor',[0.05 0.48 0.35],'DisplayName','Window exit');
hReentry = semilogx(NaN,NaN,'s','Color',[0.12 0.26 0.54], ...
    'MarkerFaceColor',[0.12 0.26 0.54],'DisplayName','120 km crossing');
hCensored = semilogx(NaN,NaN,'>','Color',[0.48 0.48 0.48], ...
    'DisplayName','Not observed by limit');
for k = 1:numel(results)
    m = results{k}.metrics;
    if m.windowExitObserved && m.t_window_exit_d > 0
        semilogx(m.t_window_exit_d,k,'o','Color',hExit.Color, ...
            'MarkerFaceColor',hExit.Color,'HandleVisibility','off');
    elseif ~m.windowExitObserved
        semilogx(m.windowObservationEnd_d,k,'>','Color',hCensored.Color, ...
            'HandleVisibility','off');
    end
    if isfinite(m.t_120_d)
        semilogx(m.t_120_d,k,'s','Color',hReentry.Color, ...
            'MarkerFaceColor',hReentry.Color,'HandleVisibility','off');
    else
        semilogx(m.censorLimit_d,k,'>','Color',hCensored.Color, ...
            'HandleVisibility','off');
    end
end
set(gca,'YTick',1:numel(results), ...
    'YTickLabel',cellfun(@(r) r.config.case.id,results,'UniformOutput',false), ...
    'YDir','reverse','XScale','log');
xlabel('Time since command (day, log scale)');
ylabel('Strategy');
title('Window exit and 120 km crossing | candidate atmosphere');
legend([hExit hReentry hCensored],'Location','best');
grid on
styleFigure(f);
exportgraphics(f,fullfile(figDir,'window_exit.png'),'Resolution',180);
close(f);
end
