function plot_deployment_a2(root)
out=fullfile(root,'tables'); folder=fullfile(root,'figures');
if ~isfolder(folder), mkdir(folder); end
ids={'A2_NORMAL_120','A2_PARTIAL','A2_LOST_DEPLOYED','A2_LOST_STOWED'};
f=figure('Visible','off','Color','w','Position',[100 100 1100 700]);
for k=1:4
    s=load(fullfile(out,[ids{k} '.mat']),'r'); r=s.r;
    e=r.eventLog; start=e(find(strcmp({e.type},'deployment_started'),1)).time_s;
    t=(0:1:650)'; d=arrayfun(@(dt) deploymentState(start+dt,start,r.config.case),t);
    subplot(2,2,k);
    plot(t,[d.fraction],'LineWidth',1.5); hold on;
    stairs(t,double([d.confirmed]),'--','LineWidth',1.5);
    xline(600,':','Timeout'); ylim([-0.05 1.1]); grid on;
    xlabel('Seconds after deployment command'); ylabel('Fraction / confirmation flag');
    title(strrep(ids{k},'_',' ')); legend('Actual area fraction','Feedback received','Location','best');
end
exportgraphics(f,fullfile(folder,'area_and_feedback.png'),'Resolution',140); close(f);
end
