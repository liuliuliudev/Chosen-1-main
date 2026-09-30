function m = computeMetrics(result, p)
%COMPUTEMETRICS 统一计算成功判定、资源消耗和未完成案例的指标。
m.status = string(result.status);
% 未发生的事件返回 NaN，不能把计算时限误当作完成时间。
m.t_switch_d = eventTime(result.eventLog,'switch')/86400;
m.t_120_d = eventTime(result.eventLog,'reentry')/86400;
m.t_fuel_d = eventTime(result.eventLog,'fuel_exhausted')/86400;
firstOrbit = stateToElements(result.state_SI(1,:).',p);
lastOrbit = stateToElements(result.state_SI(end,:).',p);
w = windowExitMetrics(result.eventLog,firstOrbit.apogeeAltitude_m, ...
    lastOrbit.apogeeAltitude_m,p.mission.windowLowerAltitude_m,result.time_s(end));
m.t_window_exit_d = w.time_s/86400;
m.windowExitObserved = w.observed;
m.windowExitStatus = string(w.status);
m.windowReturnCount = w.returnCount;
m.windowObservationEnd_d = w.observationEnd_s/86400;
m.propUsed_kg = p.sc.initialMass_kg-result.state_SI(end,7);
m.thrustOn_h = result.thrustOn_s/3600;
m.dryMassReached = m.propUsed_kg >= p.sc.propellant_kg-1e-8;
% 未设研究期限时用 NaN 表示不适用，不能把计算上限当成期限。
m.deadlineMet = NaN;
if isfinite(p.mission.deadline_s)
    m.deadlineMet = double(strcmp(result.status,'reentry') && ...
        m.t_120_d*86400 <= p.mission.deadline_s);
end
m.censorLimit_d = p.sim.maxDuration_s/86400;
m.runtime_s = result.runtime_s;
dragAccel = zeros(numel(result.time_s),1);
% 沿已保存轨迹重新计算阻力大小，用于峰值和时间平均值。
for k = 1:numel(dragAccel)
    x = result.state_SI(k,:).';
    a = atmosphericDrag(x(1:3),x(4:6),x(7),result.sailFraction(k),p);
    dragAccel(k) = norm(a);
end
m.maxDragAccel_mps2 = max(dragAccel);
% 用不等间隔采样点上的梯形积分计算时间平均值。
m.meanDragAccel_mps2 = trapz(result.time_s,dragAccel)/ ...
    max(result.time_s(end)-result.time_s(1),eps);
end

function t = eventTime(events,kind)
t = NaN;
if isempty(events), return; end
idx = find(strcmp({events.type},kind),1,'first');
if ~isempty(idx), t = events(idx).time_s; end
end
