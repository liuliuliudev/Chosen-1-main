function comparison = run_power_numerical_check(p,outDir)
%RUN_POWER_NUMERICAL_CHECK 60/30秒调度分辨率对照，预设1%时间/燃料阈值。
saved = load(fullfile(outDir,'power_results.mat'),'results');
cases = experiment_matrix('power');
rows = cell(numel(cases),1);
for k=1:numel(cases)
    cases(k).powerStep_s = 30;
    refined = propagateCase(cases(k),p);
    base = saved.results{k};
    sameStatus = strcmp(base.status,refined.status);
    endTimeError_s = abs(base.time_s(end)-refined.time_s(end));
    fuelError_kg = abs(base.metrics.propUsed_kg-refined.metrics.propUsed_kg);
    pass = sameStatus && endTimeError_s <= max(60,0.01*base.time_s(end)) && ...
        fuelError_kg <= max(1e-4,0.01*base.metrics.propUsed_kg);
    rows{k} = table(string(cases(k).id),sameStatus,endTimeError_s,fuelError_kg,pass, ...
        'VariableNames',{'caseId','sameStatus','endTimeError_s','fuelError_kg','pass'});
end
comparison = vertcat(rows{:});
writetable(comparison,fullfile(outDir,'power_numerical_check.csv'));
disp(comparison);
assert(all(comparison.pass),'PowerCheck:Failed','Power timestep comparison failed.');
end
