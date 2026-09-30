function testWindowExit()
%TESTWINDOWEXIT 检查窗口穿越、回升、删失及两种主动策略的一致性。
events = [makeEvent(10,'window_down'),makeEvent(20,'window_up'), ...
    makeEvent(30,'window_down')];
w = windowExitMetrics(events,550e3,490e3,500e3,40);
assert(w.observed && w.time_s == 30 && w.returnCount == 1);
w = windowExitMetrics(events(1:2),550e3,510e3,500e3,40);
assert(~w.observed && isnan(w.time_s) && strcmp(w.status,'not_observed'));
w = windowExitMetrics(events([]),550e3,540e3,500e3,40);
assert(~w.observed && w.observationEnd_s == 40);
w = windowExitMetrics(events([]),160e3,150e3,500e3,40);
assert(w.observed && w.time_s == 0 && strcmp(w.status,'initially_below'));
w = windowExitMetrics(events([]),550e3,490e3,500e3,40);
assert(~w.observed && strcmp(w.status,'inconsistent'));
w = windowExitMetrics(events([]),550e3,500e3,500e3,40);
assert(~w.observed && strcmp(w.status,'ambiguous_boundary'));

p = baseline_case();
p.sim.maxDuration_s = 4*86400;
cases = experiment_matrix('baselines');
b2 = propagateCase(cases(3),p);
cooperative = propagateCase(cases(4),p);
assert(b2.metrics.windowExitObserved && cooperative.metrics.windowExitObserved);
assert(abs(b2.metrics.t_window_exit_d- ...
    cooperative.metrics.t_window_exit_d)*86400 < 1);
assert(any(strcmp({cooperative.eventLog.type},'window_down')));
assert(isnan(cooperative.metrics.deadlineMet));
end

function event = makeEvent(t,kind)
event = struct('time_s',t,'type',kind,'detail','test');
end
