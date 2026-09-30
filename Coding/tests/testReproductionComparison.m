function testReproductionComparison()
a = tempname; b = tempname; mkdir(a); mkdir(b);
groups = {'baselines','switch','density','sail','thrust','faults','supervised','hardware','power'};
t = table("case","time_limit","not_observed",NaN,NaN,0, ...
    'VariableNames',{'caseId','status','windowExitStatus','t120_d','tWindowExit_d','propUsed_kg'});
for k=1:numel(groups)
    writetable(t,fullfile(a,[groups{k} '_summary.csv']));
    writetable(t,fullfile(b,[groups{k} '_summary.csv']));
end
ok = compare_reproduction(a,b);
assert(all(ok.pass));
t.status = "reentry"; t.t120_d = 1;
writetable(t,fullfile(b,'baselines_summary.csv'));
try
    compare_reproduction(a,b);
    error('Test:ExpectedFailure','Missing-vs-observed event should fail.');
catch err
    assert(strcmp(err.identifier,'Reproduction:Mismatch'));
end
end
