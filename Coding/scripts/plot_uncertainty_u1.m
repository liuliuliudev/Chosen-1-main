function plot_uncertainty_u1(root)
out=fullfile(root,'tables'); s=readtable(fullfile(out,'uncertainty_summary.csv'),'TextType','string');
r=readtable(fullfile(out,'uncertainty_resources.csv'),'TextType','string');
folder=fullfile(root,'figures'); if ~isfolder(folder), mkdir(folder); end
f=figure('Visible','off','Color','w','Position',[100 100 1150 650]);
names={'Baseline','Solar 585 W','Battery 270 Wh','Initial 70%','Common load +10%'};
subplot(2,1,1); bar(s.t120_d); ylabel('Time to 120 km (day)');
set(gca,'XTick',1:5,'XTickLabel',names); grid on;
for k=1:5
    if ~isfinite(s.t120_d(k)), text(k,0,char(s.status(k)),'Rotation',90); end
end
title('One-factor research scenarios; missing events are not zero-day completion');
subplot(2,1,2); bar(r.marginAboveFloor_Wh); ylabel('Minimum battery margin above protection (Wh)');
set(gca,'XTick',1:5,'XTickLabel',names); grid on;
title('Protection floor changes with available capacity; compare margin, not just absolute energy');
exportgraphics(f,fullfile(folder,'uncertainty_comparison.png'),'Resolution',140); close(f);
end
