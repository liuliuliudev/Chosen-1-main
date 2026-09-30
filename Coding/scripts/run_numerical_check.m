function summary = run_numerical_check(p,outDir)
%RUN_NUMERICAL_CHECK 比较默认与更严格的求解器设置，检查数值稳定性。
if nargin < 1, p = baseline_case(); end
if nargin < 2
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'results','tables');
end
if ~isfolder(outDir), mkdir(outDir); end
baselines = experiment_matrix('baselines');
switchCases = experiment_matrix('switch');
% SW450 在退出窗口前就切换，必须与三个关键基线一起检查。
cases = [baselines([2 3 4]),switchCases(end)];
n = numel(cases);
id = strings(n,1); sameStatus = false(n,1);
eventDiff_d = NaN(n,1); fuelDiff_kg = NaN(n,1);
sameWindowStatus = false(n,1); windowDiff_d = NaN(n,1);
switchDiff_d = NaN(n,1); sameWindowEventCount = false(n,1);
sameSwitchOccurrence = false(n,1);
pass = false(n,1);
for k = 1:n
    id(k) = string(cases(k).id);
    base = propagateCase(cases(k),p);
    tight = p;
    % 收紧相对/绝对误差并减小最大步长，重新计算同一案例。
    tight.sim.relTol = p.sim.relTol/10;
    tight.sim.absTol = p.sim.absTol/10;
    tight.sim.maxStep_s = p.sim.maxStep_s/2;
    refined = propagateCase(cases(k),tight);
    sameStatus(k) = strcmp(base.status,refined.status);
    sameWindowStatus(k) = ...
        base.metrics.windowExitStatus == refined.metrics.windowExitStatus;
    sameWindowEventCount(k) = sum(startsWith({base.eventLog.type},'window_')) == ...
        sum(startsWith({refined.eventLog.type},'window_'));
    if base.metrics.windowExitObserved && refined.metrics.windowExitObserved
        windowDiff_d(k) = abs(base.metrics.t_window_exit_d- ...
            refined.metrics.t_window_exit_d);
    end
    if isfinite(base.metrics.t_switch_d) && isfinite(refined.metrics.t_switch_d)
        switchDiff_d(k) = abs(base.metrics.t_switch_d- ...
            refined.metrics.t_switch_d);
    end
    sameSwitchOccurrence(k) = ...
        isfinite(base.metrics.t_switch_d) == isfinite(refined.metrics.t_switch_d);
    % 只有两次都触发 120 km 再入事件时，完成时间差才有定义。
    if sameStatus(k) && strcmp(base.status,'reentry')
        eventDiff_d(k) = abs(base.metrics.t_120_d-refined.metrics.t_120_d);
    end
    fuelDiff_kg(k) = abs(base.metrics.propUsed_kg-refined.metrics.propUsed_kg);
    % 完成时间和燃料差分别以 1% 为主要判据，燃料另设绝对下限。
    timeOK = isnan(eventDiff_d(k)) || ...
        eventDiff_d(k) <= 0.01*max(base.metrics.t_120_d,eps);
    fuelOK = fuelDiff_kg(k) <= ...
        max(1e-4,0.01*base.metrics.propUsed_kg);
    % J2 近切穿越可能使“最后一圈”跳变，窗口时间按一圈上限验收。
    orbitPeriod_s = 2*pi*sqrt((p.earth.RE+p.sc.initialAltitude_m)^3/p.earth.mu);
    validWindowStatus = ~ismember(base.metrics.windowExitStatus, ...
        ["inconsistent","ambiguous_boundary"]) && ...
        ~ismember(refined.metrics.windowExitStatus, ...
        ["inconsistent","ambiguous_boundary"]);
    windowOK = validWindowStatus && sameWindowStatus(k) && sameWindowEventCount(k) && ...
        (isnan(windowDiff_d(k)) || windowDiff_d(k)*86400 <= orbitPeriod_s);
    switchOK = sameSwitchOccurrence(k) && ...
        (isnan(switchDiff_d(k)) || switchDiff_d(k)*86400 <= 60);
    pass(k) = sameStatus(k) && timeOK && fuelOK && windowOK && switchOK;
end
summary = table(id,sameStatus,sameWindowStatus,sameWindowEventCount, ...
    sameSwitchOccurrence,eventDiff_d,windowDiff_d,switchDiff_d,fuelDiff_kg,pass, ...
    'VariableNames',{'caseId','sameStatus','sameWindowStatus', ...
    'sameWindowEventCount','sameSwitchOccurrence','eventDiff_d','windowDiff_d', ...
    'switchDiff_d','fuelDiff_kg','pass'});
writetable(summary,fullfile(outDir,'numerical_check.csv'));
disp(summary);
assert(all(pass),'Numerical consistency failed; inspect numerical_check.csv.');
end
