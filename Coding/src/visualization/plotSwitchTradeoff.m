function plotSwitchTradeoff(tradeoff, resultsRoot)
%PLOTSWITCHTRADEOFF 将非劣设计点与受支配点明确区分。
if nargin < 2
    resultsRoot = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
        'results');
end
figDir = fullfile(resultsRoot,'figures');
if ~isfolder(figDir), mkdir(figDir); end
f = figure('Visible','off','Color','w');
hold on
keep = logical(tradeoff.isNondominated);
drop = string(tradeoff.selectionStatus) == "dominated";
scatter(tradeoff.t120_d(keep),tradeoff.propUsed_kg(keep),70, ...
    tradeoff.tWindowExit_d(keep),'filled','DisplayName','Nondominated');
scatter(tradeoff.t120_d(drop),tradeoff.propUsed_kg(drop),70, ...
    [0.55 0.55 0.55],'x','DisplayName','Dominated');
for k = 1:height(tradeoff)
    if ~(keep(k) || drop(k)), continue; end
    text(tradeoff.t120_d(k),tradeoff.propUsed_kg(k), ...
        [' ' char(string(tradeoff.caseId(k)))], ...
        'VerticalAlignment','middle');
end
cb = colorbar;
cb.Label.String = 'Window exit (day)';
pad = 0.08*(max(tradeoff.t120_d)-min(tradeoff.t120_d));
xlim([min(tradeoff.t120_d)-pad,max(tradeoff.t120_d)+pad]);
xlabel('Time to 120 km (day)');
ylabel('Propellant used (kg)');
title('Switch design tradeoff | candidate atmosphere');
legend('Location','best');
grid on
styleFigure(f);
cb.Color = [0.12 0.15 0.18];
cb.Label.Color = [0.12 0.15 0.18];
exportgraphics(f,fullfile(figDir,'switch_tradeoff.png'),'Resolution',180);
close(f);
end
