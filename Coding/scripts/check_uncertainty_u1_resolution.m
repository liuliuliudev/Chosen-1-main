function check=check_uncertainty_u1_resolution(root)
out=fullfile(root,'tables'); saved=load(fullfile(out,'uncertainty_results.mat'),'results');
rows=cell(4,1);
for j=1:4
    base=saved.results{j+1}; c=base.config.case; c.powerStep_s=30;
    fprintf('U1 resolution %s\n',c.id);
    refined=propagateCase(c,base.config.parameters);
    save(fullfile(out,[c.id '_refined.mat']),'refined','-v7.3');
    timeError_s=abs(base.time_s(end)-refined.time_s(end));
    fuelError_kg=abs(base.metrics.propUsed_kg-refined.metrics.propUsed_kg);
    sameStatus=strcmp(base.status,refined.status);
    pass=sameStatus && timeError_s<=max(60,0.01*base.time_s(end)) && ...
        fuelError_kg<=max(1e-4,0.01*base.metrics.propUsed_kg);
    rows{j}=table(string(c.id),sameStatus,timeError_s,fuelError_kg,pass, ...
        'VariableNames',{'caseId','sameStatus','timeError_s','fuelError_kg','pass'});
end
check=vertcat(rows{:}); writetable(check,fullfile(out,'resolution_check.csv'));
disp(check); assert(all(check.pass),'U1:Resolution','Resolution check failed.');
end
