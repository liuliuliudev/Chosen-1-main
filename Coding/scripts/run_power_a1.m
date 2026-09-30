function outRoot=run_power_a1(outRoot)
%RUN_POWER_A1 单独的已冻结供电对照；不改旧组或展帆规则。
root=fileparts(fileparts(mfilename('fullpath')));
if nargin<1
    outRoot=fullfile(root,'results',['a1_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
end
assert(~isfolder(outRoot)); mkdir(outRoot);
out=fullfile(outRoot,'tables'); mkdir(out);
diary(fullfile(outRoot,'validation.txt')); cleanup=onCleanup(@() diary('off')); %#ok<NASGU>
run_tests();
p=baseline_case(); cases=experiment_matrix('power_a1');
results=cell(numel(cases),1); rows=cell(numel(cases),1);
for k=1:numel(cases)
    fprintf('A1 %d/%d %s\n',k,numel(cases),cases(k).id);
    r=propagateCase(cases(k),p); results{k}=r;
    rows{k}=table(string(cases(k).id),cases(k).reserveFraction, ...
        r.power.minimumBattery_Wh,r.power.finalBattery_Wh,r.power.unmetBaseEnergy_Wh, ...
        'VariableNames',{'caseId','reserveFraction','minimumBattery_Wh','finalBattery_Wh','unmetBaseEnergy_Wh'});
    writetable(r.power.history,fullfile(out,[cases(k).id '_power.csv']));
end
summary=summarizeRuns(results); resources=vertcat(rows{:});
writetable(summary,fullfile(out,'power_a1_summary.csv'));
writetable(resources,fullfile(out,'power_a1_resources.csv'));
save(fullfile(out,'power_a1_results.mat'),'results','summary','resources','-v7.3');
verify_power_a1(outRoot);
disp(summary); disp(resources); fprintf('A1 output: %s\n',outRoot);
end
