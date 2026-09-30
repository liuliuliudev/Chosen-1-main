function validateCase(p)
%VALIDATECASE 检查参数范围、相互约束及模型支持情况。
% 质量、几何面积和推力必须符合基本物理约束。
assert(p.earth.mu > 0 && p.earth.RE > 0 && p.earth.g0 > 0);
assert(p.sc.initialMass_kg > p.sc.dryMass_kg && p.sc.dryMass_kg > 0);
assert(abs(p.sc.initialMass_kg-p.sc.dryMass_kg- ...
    p.sc.propellant_kg) < 1e-9);
assert(p.sc.initialAltitude_m > p.mission.reentryAltitude_m);
assert(p.sc.Cd >= 0 && p.sc.bodyArea_m2 >= 0 && p.sail.addedArea_m2 >= 0);
assert(p.thruster.thrust_N >= 0 && p.thruster.Isp_s > 0);
assert(p.thruster.dutyFraction >= 0 && p.thruster.dutyFraction <= 1);
assert(p.thruster.dutyPeriod_s > 0);
assert(p.atmosphere.scale >= 0);
assert(any(strcmp(p.atmosphere.model,{'exponential'})), ...
    'Unsupported atmosphere model.');
% 再入高度必须低于切换高度，切换高度必须低于初始轨道。
assert(p.mission.reentryAltitude_m < p.mission.switchAltitude_m && ...
    p.mission.switchAltitude_m < p.sc.initialAltitude_m);
assert(p.mission.windowLowerAltitude_m > p.mission.reentryAltitude_m && ...
    p.mission.windowUpperAltitude_m > p.mission.windowLowerAltitude_m);
assert((isnan(p.mission.deadline_s) || ...
    (isfinite(p.mission.deadline_s) && p.mission.deadline_s > 0)) && ...
    p.sim.maxDuration_s > 0);
assert(p.sim.relTol > 0 && numel(p.sim.absTol) == 7 && ...
    all(p.sim.absTol > 0) && p.sim.maxStep_s > 0);
assert(any(strcmp(p.sim.solver,{'ode113','ode45'})), ...
    'Unsupported ODE solver.');
assert(p.analysis.windowTolerance_s >= 0 && ...
    p.analysis.reentryTolerance_s >= 0 && ...
    p.analysis.propellantTolerance_kg >= 0);
% 大气表按高度递增，且至少覆盖再入界面到初始高度。
a = p.atmosphere.table_SI;
assert(size(a,2) == 3 && size(a,1) >= 2 && all(isfinite(a),'all'));
assert(all(diff(a(:,1)) > 0) && all(a(:,2) > 0) && all(a(:,3) > 0));
assert(a(1,1) <= p.mission.reentryAltitude_m && ...
    a(end,1) >= p.sc.initialAltitude_m);
end
