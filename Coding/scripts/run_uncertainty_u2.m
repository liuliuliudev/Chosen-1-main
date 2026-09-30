function root=run_uncertainty_u2(root)
%RUN_UNCERTAINTY_U2 已确认中等不利组合；固定控制规则，不为通过调整输入。
project=fileparts(fileparts(mfilename('fullpath')));
if nargin<1
    root=fullfile(project,'results',['u2_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
end
assert(~isfolder(root)); mkdir(root); out=fullfile(root,'tables'); mkdir(out);
diary(fullfile(root,'validation.txt')); cleanup=onCleanup(@() diary('off')); %#ok<NASGU>
run_tests(); p=baseline_case(); c=experiment_matrix('uncertainty_u2'); q=powerScenario(p,c);
assert(q.capacity_Wh==270 && q.initialFraction==0.7 && c.supervisor.powerAvailable_W==585);
assert(abs(modePowerLoad("safe",false,q)-251)<1e-9 && abs(modePowerLoad("thrust",true,q)-581)<1e-9);
fprintf('U2 combined: 585 W, 270 Wh, initial 70%%, common load +10%%\n');
r=propagateCase(c,p); results={r}; summary=summarizeRuns(results);
save(fullfile(out,'uncertainty_results.mat'),'results','summary','-v7.3');
writetable(summary,fullfile(out,'uncertainty_summary.csv'));
writetable(struct2table(r.eventLog),fullfile(out,'combined_events.csv'));
writetable(r.power.history,fullfile(out,'combined_power.csv'));
q=r.power.assumptions;
resources=table(q.solarEol_W,q.capacity_Wh,q.initialFraction,q.coastLoad_W,q.thrustLoad_W, ...
    r.power.minimumBattery_Wh,r.power.minimumBattery_Wh-q.minimumFraction*q.capacity_Wh,r.power.unmetBaseEnergy_Wh, ...
    'VariableNames',{'solar_W','capacity_Wh','initialFraction','safeLoad_W','thrustLoad_W', ...
    'minimumBattery_Wh','marginAboveFloor_Wh','unmetEnergy_Wh'});
writetable(resources,fullfile(out,'uncertainty_resources.csv'));
verify_uncertainty_u1(root);
c.powerStep_s=30; refined=propagateCase(c,p);
save(fullfile(out,'combined_refined.mat'),'refined','-v7.3');
sameStatus=strcmp(r.status,refined.status);
timeError_s=abs(r.time_s(end)-refined.time_s(end));
fuelError_kg=abs(r.metrics.propUsed_kg-refined.metrics.propUsed_kg);
pass=sameStatus && timeError_s<=max(60,0.01*r.time_s(end)) && fuelError_kg<=max(1e-4,0.01*r.metrics.propUsed_kg);
check=table(sameStatus,timeError_s,fuelError_kg,pass); writetable(check,fullfile(out,'resolution_check.csv'));
disp(summary); disp(resources); disp(check);
fprintf('U2 output: %s\n',root);
assert(pass,'U2:Resolution','Combined-case resolution check failed.');
end
