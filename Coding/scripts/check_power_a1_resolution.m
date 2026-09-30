function comparison=check_power_a1_resolution(outRoot)
%CHECK_POWER_A1_RESOLUTION 对每种供电水平的10%余量做60/30秒对照。
out=fullfile(outRoot,'tables'); s=load(fullfile(out,'power_a1_results.mat'),'results');
rows=cell(2,1); selected=[3 7];
cache=fullfile(out,'refined_results.mat');
if isfile(cache), cached=load(cache,'refined'); else, cached=[]; end
for j=1:2
    base=s.results{selected(j)};
    c=base.config.case; c.powerStep_s=30;
    if isempty(cached)
        refined=propagateCase(c,base.config.parameters);
    else
        refined=cached.refined{j};
        assert(isequaln(refined.config.parameters,base.config.parameters) && ...
            strcmp(refined.config.case.id,c.id) && refined.config.case.powerStep_s==30, ...
            'A1:CacheMismatch','Refined cache inputs differ.');
    end
    sameStatus=strcmp(base.status,refined.status);
    timeError_s=abs(base.time_s(end)-refined.time_s(end));
    fuelError_kg=abs(base.metrics.propUsed_kg-refined.metrics.propUsed_kg);
    pass=sameStatus && timeError_s<=max(60,0.01*base.time_s(end)) && ...
        fuelError_kg<=max(1e-4,0.01*base.metrics.propUsed_kg);
    rows{j}=table(string(c.id),sameStatus,timeError_s,fuelError_kg,pass, ...
        'VariableNames',{'caseId','sameStatus','timeError_s','fuelError_kg','pass'});
end
comparison=vertcat(rows{:}); writetable(comparison,fullfile(out,'resolution_check.csv'));
disp(comparison); assert(all(comparison.pass),'A1:Resolution','Resolution check failed.');
end
