function plot_power_a1(outRoot)
%PLOT_POWER_A1 保存本批电量、点火与资源取舍图；未完成案例不填完成时间。
out=fullfile(outRoot,'tables'); s=load(fullfile(out,'power_a1_results.mat'),'results','summary','resources');
folder=fullfile(outRoot,'figures'); if ~isfolder(folder), mkdir(folder); end
colors=lines(4);
f=figure('Visible','off','Color','w','Position',[100 100 1100 700]);
for panel=1:2
    subplot(2,1,panel); hold on;
    for j=1:4
        k=(panel-1)*4+j; r=s.results{k}; h=r.power.history;
        orbit=floor(h.end_s/r.power.assumptions.period_s)+1;
        minimum=accumarray(orbit,h.batteryEnd_Wh,[],@min,NaN);
        at=accumarray(orbit,h.end_s,[],@max,NaN)/86400;
        plot(at,minimum,'Color',colors(j,:), 'LineWidth',1.5, ...
            'DisplayName',strrep(r.config.case.id,'_',' '));
    end
    yline(60,'k--','DisplayName','Protection floor');
    xlabel('Simulation time (day)'); ylabel('Minimum battery per model orbit (Wh)');
    title(sprintf('%d W; same battery and mode loads',650-(panel-1)*150));
    legend('Location','best'); grid on;
end
exportgraphics(f,fullfile(folder,'battery_history.png'),'Resolution',140); close(f);
f=figure('Visible','off','Color','w','Position',[100 100 1100 700]);
for panel=1:2
    subplot(2,1,panel); hold on;
    for j=1:4
        k=(panel-1)*4+j; r=s.results{k}; h=r.power.history;
        cumulative=cumsum((h.end_s-h.start_s).*h.thrustOn)/3600;
        plot(h.end_s/86400,cumulative,'Color',colors(j,:), ...
            'DisplayName',strrep(r.config.case.id,'_',' '));
    end
    xlabel('Simulation time (day)'); ylabel('Cumulative thrust (hour)');
    title(sprintf('%d W; failed trajectories end at failure',650-(panel-1)*150));
    legend('Location','best'); grid on;
end
exportgraphics(f,fullfile(folder,'thrust_history.png'),'Resolution',140); close(f);
end
