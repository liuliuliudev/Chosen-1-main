function tradeoff = classifySwitchTradeoff(summary, p)
%CLASSIFYSWITCHTRADEOFF 对窗口退出、120 km 时间和燃料做容差非劣比较。
n = height(summary);
tradeoff = summary;
tradeoff.isNondominated = false(n,1);
tradeoff.dominatedBy = strings(n,1);
tradeoff.selectionStatus = repmat("excluded",n,1);
objective = [summary.tWindowExit_d,summary.t120_d,summary.propUsed_kg];
valid = summary.windowExitObserved & ...
    strcmp(summary.status,'reentry') & all(isfinite(objective),2);
tol = [p.analysis.windowTolerance_s/86400, ...
    p.analysis.reentryTolerance_s/86400, ...
    p.analysis.propellantTolerance_kg];
for k = find(valid).'
    tradeoff.isNondominated(k) = true;
    tradeoff.selectionStatus(k) = "nondominated";
    for j = find(valid).'
        if j == k, continue; end
        noWorse = all(objective(j,:) <= objective(k,:)+tol);
        clearlyBetter = any(objective(j,:) < objective(k,:)-tol);
        if noWorse && clearlyBetter
            tradeoff.isNondominated(k) = false;
            tradeoff.selectionStatus(k) = "dominated";
            tradeoff.dominatedBy(k) = string(summary.caseId(j));
            break
        end
    end
end
end
