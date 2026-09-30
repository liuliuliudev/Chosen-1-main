function root=run_deployment_a2(root)
project=fileparts(fileparts(mfilename('fullpath')));
resume=nargin>0;
if ~resume
    root=fullfile(project,'results',['a2_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
    assert(~isfolder(root)); mkdir(root);
end
out=fullfile(root,'tables'); if ~isfolder(out), mkdir(out); end
logName=['validation_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')) '.txt'];
diary(fullfile(root,logName)); cleanup=onCleanup(@() diary('off')); %#ok<NASGU>
run_tests(); p=baseline_case(); cases=experiment_matrix('deployment_a2');
results=cell(numel(cases),1); rows=cell(numel(cases),1);
for k=1:numel(cases)
    fprintf('A2 %d/%d %s\n',k,numel(cases),cases(k).id);
    file=fullfile(out,[cases(k).id '.mat']);
    if resume && isfile(file)
        cached=load(file,'r'); r=cached.r;
        [expected,pExpected]=faultInjection(cases(k),p);
        assert(isequaln(r.config.case,expected) && isequaln(r.config.parameters,pExpected), ...
            'A2:ResumeMismatch','Saved case does not match this experiment.');
        fprintf('Reusing completed case %s\n',cases(k).id);
    else
        r=propagateCase(cases(k),p);
        save(file,'r','-v7.3');
        writetable(struct2table(r.eventLog),fullfile(out,[cases(k).id '_events.csv']));
    end
    results{k}=r;
    h=r.power.history; motor=h.load_W==240;
    motorEnergy_Wh=sum((h.end_s(motor)-h.start_s(motor))*30/3600);
    rows{k}=table(string(cases(k).id),r.power.minimumBattery_Wh, ...
        r.power.unmetBaseEnergy_Wh,motorEnergy_Wh, ...
        'VariableNames',{'caseId','minimumBattery_Wh','unmetEnergy_Wh','motorEnergy_Wh'});
end
summary=summarizeRuns(results); resources=vertcat(rows{:});
writetable(summary,fullfile(out,'deployment_summary.csv'));
writetable(resources,fullfile(out,'deployment_resources.csv'));
save(fullfile(out,'deployment_results.mat'),'results','summary','resources','-v7.3');
disp(summary); disp(resources); fprintf('A2 output: %s\n',root);
end
