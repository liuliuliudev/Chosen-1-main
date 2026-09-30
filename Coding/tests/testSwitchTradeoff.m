function testSwitchTradeoff()
%TESTSWITCHTRADEOFF 用可判定的人工案例检查多指标非劣分类。
p = baseline_case();
caseId = ["A";"B";"C";"D"];
status = ["reentry";"reentry";"reentry";"time_limit"];
tWindowExit_d = [2;2;3;NaN];
t120_d = [10;9;9;NaN];
propUsed_kg = [0.5;0.4;0.2;0];
windowExitObserved = [true;true;true;false];
summary = table(caseId,status,tWindowExit_d,t120_d, ...
    propUsed_kg,windowExitObserved);
tradeoff = classifySwitchTradeoff(summary,p);
assert(isequal(tradeoff.isNondominated,[false;true;true;false]));
assert(tradeoff.dominatedBy(1) == "B");
assert(tradeoff.selectionStatus(4) == "excluded");
end
