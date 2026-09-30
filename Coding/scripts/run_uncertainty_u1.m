function root=run_uncertainty_u1(root)
project=fileparts(fileparts(mfilename('fullpath')));
if nargin<1
    root=fullfile(project,'results',['u1_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
end
assert(~isfolder(root)); mkdir(root); out=fullfile(root,'tables'); mkdir(out);
diary(fullfile(root,'validation.txt')); cleanup=onCleanup(@() diary('off')); %#ok<NASGU>
run_tests(); p=baseline_case(); cases=experiment_matrix('uncertainty_u1');
results=cell(5,1); rows=cell(5,1);
for k=1:5
    fprintf('U1 %d/5 %s\n',k,cases(k).id);
    r=propagateCase(cases(k),p); results{k}=r; q=r.power.assumptions;
    save(fullfile(out,[cases(k).id '.mat']),'r','-v7.3');
    writetable(struct2table(r.eventLog),fullfile(out,[cases(k).id '_events.csv']));
    rows{k}=table(string(cases(k).id),q.solarEol_W,q.capacity_Wh,q.initialFraction, ...
        q.coastLoad_W,q.thrustLoad_W,r.power.minimumBattery_Wh, ...
        r.power.minimumBattery_Wh-q.minimumFraction*q.capacity_Wh,r.power.unmetBaseEnergy_Wh, ...
        'VariableNames',{'caseId','solar_W','capacity_Wh','initialFraction','safeLoad_W','thrustLoad_W', ...
        'minimumBattery_Wh','marginAboveFloor_Wh','unmetEnergy_Wh'});
end
summary=summarizeRuns(results); resources=vertcat(rows{:});
writetable(summary,fullfile(out,'uncertainty_summary.csv'));
writetable(resources,fullfile(out,'uncertainty_resources.csv'));
save(fullfile(out,'uncertainty_results.mat'),'results','summary','resources','-v7.3');
disp(summary); disp(resources); fprintf('U1 output: %s\n',root);
end
