function comparison=compare_current_reproduction(referenceRoot,resultRoot)
%COMPARE_CURRENT_REPRODUCTION 比较当前24个案例，缺失事件与资源失败不混同。
paths={'a1/tables/power_a1_summary.csv','a2/tables/deployment_summary.csv','u1/tables/uncertainty_summary.csv','u2/tables/uncertainty_summary.csv'};
rows=cell(0,1);
for g=1:numel(paths)
    a=readtable(fullfile(referenceRoot,paths{g}),'TextType','string');
    b=readtable(fullfile(resultRoot,paths{g}),'TextType','string');
    assert(isequal(a.caseId,b.caseId),'CurrentCompare:Cases','Case identities differ.');
    for k=1:height(a)
        same=a.status(k)==b.status(k) && a.windowExitStatus(k)==b.windowExitStatus(k);
        td=delta(a.t120_d(k),b.t120_d(k))*86400;
        wd=delta(a.tWindowExit_d(k),b.tWindowExit_d(k))*86400;
        fd=delta(a.propUsed_kg(k),b.propUsed_kg(k));
        endDiff=abs(a.windowObservationEnd_d(k)-b.windowObservationEnd_d(k))*86400;
        timeLimit=60;
        if isfinite(a.t120_d(k)), timeLimit=max(60,0.01*a.t120_d(k)*86400); end
        pass=same && td<=timeLimit && wd<=6000 && ...
            fd<=max(1e-4,0.01*a.propUsed_kg(k)) && ...
            endDiff<=max(60,0.01*a.windowObservationEnd_d(k)*86400);
        rows{end+1,1}=table(a.caseId(k),td,wd,fd,endDiff,pass, ...
            'VariableNames',{'caseId','timeError_s','windowError_s','fuelError_kg','endError_s','pass'});
    end
end
comparison=vertcat(rows{:});
assert(all(comparison.pass),'CurrentCompare:Mismatch','Current reproduction differs; inspect comparison inputs.');
end
function d=delta(a,b)
if isnan(a)&&isnan(b), d=0; elseif isfinite(a)&&isfinite(b), d=abs(a-b); else, d=inf; end
end
