function plotCoreResults(results, kind, resultsRoot)
%PLOTCORESULTS 只根据已有结果绘图，不重新计算轨道。
if nargin < 3
    resultsRoot = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
        'results');
end
figDir = fullfile(resultsRoot,'figures');
if ~isfolder(figDir), mkdir(figDir); end
figureHandle = figure('Visible','off','Color','w');
switch lower(kind)
    case {'baselines','faults'}
        % 多案例叠加高度历程，未再入的轨迹末端用叉号标记。
        hold on
        for k = 1:numel(results)
            r = results{k};
            h = vecnorm(r.state_SI(:,1:3),2,2) - ...
                r.config.parameters.earth.RE;
            plot(r.time_s/86400,h/1e3,'DisplayName',r.config.case.id);
            if strcmp(r.status,'time_limit')
                plot(r.time_s(end)/86400,h(end)/1e3,'x', ...
                    'HandleVisibility','off');
            end
        end
        yline(results{1}.config.parameters.mission.reentryAltitude_m/1e3, ...
            ':','HandleVisibility','off');
        xlabel('Time since command (day)'); ylabel('Altitude (km)');
        legend('Location','best'); grid on
    case 'tradeoff'
        % 用颜色表示切换高度，横纵轴分别为再入时间和燃料消耗。
        [x,y,c] = scanValues(results,'switchAltitude_m');
        scatter(y,c,50,x/1e3,'filled');
        cb = colorbar; cb.Label.String = 'Switch altitude (km)';
        xlabel('Time to 120 km (day)'); ylabel('Propellant used (kg)');
        grid on
    case {'density','sail','thrust'}
        % 单因素扫描统一绘制参数值与到达 120 km 的时间。
        field = struct('density','densityScale','sail','sailAddedArea_m2', ...
            'thrust','thrust_N');
        [x,y,~] = scanValues(results,field.(kind));
        switch kind
            case 'density'
                axisLabel = 'Density multiplier';
            case 'sail'
                axisLabel = 'Added sail area (m^2)';
            case 'thrust'
                x = x*1e3;
                axisLabel = 'Thrust (mN)';
        end
        plot(x,y,'o-'); grid on
        xlabel(axisLabel); ylabel('Time to 120 km (day)');
    otherwise
        close(figureHandle);
        error('Unknown plot kind: %s',kind);
end
title(sprintf('%s | candidate atmosphere',kind));
styleFigure(figureHandle);
exportgraphics(figureHandle,fullfile(figDir,[kind '.png']),'Resolution',180);
close(figureHandle);
if strcmpi(kind,'baselines')
    % 基准组另外输出资源柱状图和 P 策略控制时间线。
    baselineExtras(results,figDir);
end
end

function [x,y,fuel] = scanValues(results,field)
n = numel(results);
x = zeros(n,1); y = NaN(n,1); fuel = NaN(n,1);
for k = 1:n
    x(k) = results{k}.config.case.(field);
    y(k) = results{k}.metrics.t_120_d;
    fuel(k) = results{k}.metrics.propUsed_kg;
end
end

function baselineExtras(results,figDir)
% 单独展示完成时间、燃料消耗和 P 策略的控制状态。
summary = summarizeRuns(results);
f = figure('Visible','off','Color','w');
tiledlayout(1,2);
nexttile;
times = summary.t120_d;
% 对未在时限内再入的案例，柱高取计算上限并标注删失符号。
times(isnan(times)) = results{1}.metrics.censorLimit_d;
bar(categorical(summary.caseId),times);
ylabel('Time to 120 km (day; censored at limit)'); grid on
for k = find(isnan(summary.t120_d)).'
    text(k,times(k),sprintf('>%.0f',times(k)), ...
        'HorizontalAlignment','center','VerticalAlignment','bottom');
end
nexttile;
bar(categorical(summary.caseId),summary.propUsed_kg);
ylabel('Propellant used (kg)'); grid on
styleFigure(f);
exportgraphics(f,fullfile(figDir,'baseline_metrics.png'),'Resolution',180);
close(f);
idx = find(cellfun(@(r) strcmpi(r.config.case.strategy,'P'),results),1);
if isempty(idx), return; end
r = results{idx};
f = figure('Visible','off','Color','w');
stairs(r.time_s/86400,double(r.thrustOn),'DisplayName','Thrust on'); hold on
stairs(r.time_s/86400,r.sailFraction,'DisplayName','Sail fraction');
xlabel('Time since command (day)'); ylabel('Control state');
ylim([-0.1 1.1]); grid on; legend('Location','best');
styleFigure(f);
exportgraphics(f,fullfile(figDir,'P_timeline.png'),'Resolution',180);
close(f);
end
