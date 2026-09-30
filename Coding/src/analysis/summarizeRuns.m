function summary = summarizeRuns(results)
%SUMMARIZERUNS 每个案例汇总为一行；NaN 表示对应事件未发生。
n = numel(results);
id = strings(n,1); status = strings(n,1);
t120 = NaN(n,1); tswitch = NaN(n,1); fuel = NaN(n,1);
onHours = NaN(n,1); runtime = NaN(n,1);
windowExit = NaN(n,1); windowStatus = strings(n,1);
windowObserved = false(n,1); windowReturnCount = zeros(n,1);
windowObservationEnd = NaN(n,1);
deadline = NaN(n,1);
for k = 1:n
    % 只提取便于跨案例比较的状态、时间和资源指标。
    r = results{k}; m = r.metrics;
    id(k) = string(r.config.case.id);
    status(k) = m.status;
    t120(k) = m.t_120_d;
    windowExit(k) = m.t_window_exit_d;
    windowStatus(k) = m.windowExitStatus;
    windowObserved(k) = m.windowExitObserved;
    windowReturnCount(k) = m.windowReturnCount;
    windowObservationEnd(k) = m.windowObservationEnd_d;
    tswitch(k) = m.t_switch_d;
    fuel(k) = m.propUsed_kg;
    onHours(k) = m.thrustOn_h;
    deadline(k) = m.deadlineMet;
    runtime(k) = m.runtime_s;
end
summary = table(id,status,windowExit,windowStatus,windowObserved, ...
    windowReturnCount,windowObservationEnd,t120,tswitch,fuel,onHours, ...
    deadline,runtime,'VariableNames',{'caseId','status','tWindowExit_d', ...
    'windowExitStatus','windowExitObserved','windowReturnCount', ...
    'windowObservationEnd_d','t120_d','tSwitch_d','propUsed_kg', ...
    'thrustOn_h','deadlineMet','runtime_s'});
end
