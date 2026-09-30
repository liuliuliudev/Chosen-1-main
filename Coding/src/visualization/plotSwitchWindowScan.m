function plotSwitchWindowScan(results, resultsRoot)
%PLOTSWITCHWINDOWSCAN 展示切换高度对窗口退出及终点时间的不同影响。
if nargin < 2
    resultsRoot = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
        'results');
end
figDir = fullfile(resultsRoot,'figures');
if ~isfolder(figDir), mkdir(figDir); end
n = numel(results);
height_km = zeros(n,1);
window_d = NaN(n,1);
reentry_d = NaN(n,1);
for k = 1:n
    height_km(k) = results{k}.config.parameters.mission.switchAltitude_m/1e3;
    window_d(k) = results{k}.metrics.t_window_exit_d;
    reentry_d(k) = results{k}.metrics.t_120_d;
end
f = figure('Visible','off','Color','w');
tiledlayout(1,2);
nexttile;
plot(height_km,window_d,'o-','Color',[0.05 0.48 0.35]);
xlabel('Switch altitude (km)'); ylabel('Window exit (day)'); grid on
nexttile;
plot(height_km,reentry_d,'s-','Color',[0.12 0.26 0.54]);
xlabel('Switch altitude (km)'); ylabel('120 km crossing (day)'); grid on
sgtitle('Switch scan | candidate atmosphere','Color',[0.12 0.15 0.18]);
styleFigure(f);
exportgraphics(f,fullfile(figDir,'switch_window_scan.png'),'Resolution',180);
close(f);
end
