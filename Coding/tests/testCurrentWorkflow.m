function testCurrentWorkflow()
project=fileparts(fileparts(mfilename('fullpath')));
try
    runCurrentExperiments(fullfile(project,'results'));
    error('Test:ExpectedFailure','Existing output accepted.');
catch e
    assert(strcmp(e.identifier,'CurrentRun:UnsafeOutput'));
end
a=tempname; b=tempname;
paths={'a1/tables/power_a1_summary.csv','a2/tables/deployment_summary.csv','u1/tables/uncertainty_summary.csv','u2/tables/uncertainty_summary.csv'};
t=table("case","power_failure","not_observed",NaN,NaN,0.1,0.2, ...
    'VariableNames',{'caseId','status','windowExitStatus','t120_d','tWindowExit_d','propUsed_kg','windowObservationEnd_d'});
for k=1:numel(paths)
    mkdir(fileparts(fullfile(a,paths{k}))); mkdir(fileparts(fullfile(b,paths{k})));
    writetable(t,fullfile(a,paths{k})); writetable(t,fullfile(b,paths{k}));
end
c=compare_current_reproduction(a,b); assert(all(c.pass));
t.windowObservationEnd_d=2; writetable(t,fullfile(b,paths{4}));
try
    compare_current_reproduction(a,b);
    error('Test:ExpectedFailure','Different failure time accepted.');
catch e
    assert(strcmp(e.identifier,'CurrentCompare:Mismatch'));
end
empty=tempname; mkdir(empty);
try
    buildCurrentEvidence(empty);
    error('Test:ExpectedFailure','Missing evidence accepted.');
catch e
    assert(strcmp(e.identifier,'CurrentEvidence:Missing'));
end
end
