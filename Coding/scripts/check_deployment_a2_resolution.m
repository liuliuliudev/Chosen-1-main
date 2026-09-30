function check=check_deployment_a2_resolution(root)
out=fullfile(root,'tables'); ids={'A2_NORMAL_120','A2_PARTIAL','A2_NORMAL_500'};
rows=cell(3,1);
for k=1:3
    base=load(fullfile(out,[ids{k} '.mat']),'r'); base=base.r;
    c=base.config.case; c.powerStep_s=30;
    fprintf('A2 resolution %s\n',c.id);
    file=fullfile(out,[c.id '_refined.mat']);
    if isfile(file)
        cache=load(file,'refined'); refined=cache.refined;
        assert(isequaln(refined.config.parameters,base.config.parameters) && ...
            isequaln(refined.config.case,c),'Deployment:CacheMismatch','Refined configuration differs.');
    else
        refined=propagateCase(c,base.config.parameters);
        save(file,'refined','-v7.3');
    end
    timeError_s=abs(base.time_s(end)-refined.time_s(end));
    fuelError_kg=abs(base.metrics.propUsed_kg-refined.metrics.propUsed_kg);
    pass=strcmp(base.status,refined.status) && timeError_s<=max(60,0.01*base.time_s(end)) && ...
        fuelError_kg<=max(1e-4,0.01*base.metrics.propUsed_kg);
    rows{k}=table(string(c.id),timeError_s,fuelError_kg,pass, ...
        'VariableNames',{'caseId','timeError_s','fuelError_kg','pass'});
end
check=vertcat(rows{:}); writetable(check,fullfile(out,'resolution_check.csv'));
disp(check); assert(all(check.pass),'Deployment:Resolution','Resolution check failed.');
end
