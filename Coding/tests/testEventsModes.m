function testEventsModes()
%TESTEVENTSMODES 检查切换、120 km 终止和燃料耗尽事件。
p = baseline_case();
% 低轨短时案例能快速触发事件，避免测试依赖长期积分。
p.sc.initialAltitude_m = 140e3;
p.mission.switchAltitude_m = 130e3;
p.sim.maxDuration_s = 2*86400;
cases = experiment_matrix('baselines');
passive = propagateCase(cases(2),p);
% B1 必须在下降穿过再入界面时终止，保存的时间严格递增。
assert(strcmp(passive.status,'reentry'));
assert(abs(norm(passive.state_SI(end,1:3))-p.earth.RE- ...
    p.mission.reentryAltitude_m) < 1);
assert(all(diff(passive.time_s) > 0));
active = propagateCase(cases(4),p);
% P 策略只应切换一次，且轨迹质量不能低于干质量。
assert(sum(strcmp({active.eventLog.type},'switch')) == 1);
assert(all(active.state_SI(:,7) >= p.sc.dryMass_kg-1e-7));
assert(all(diff(active.time_s) > 0));
faults = experiment_matrix('faults');
[f2,~] = faultInjection(faults(2),p);
[f3,~] = faultInjection(faults(3),p);
assert(f2.policy.sailAfter == 0.5 && f2.policy.thrustAfter);
assert(f3.policy.sailAfter == 0 && f3.policy.thrustAfter);
fuelCase = p;
% 故意缩小燃料量，确认耗尽事件只记录一次并停止耗油。
fuelCase.sc.propellant_kg = 0.001;
fuelCase.sc.dryMass_kg = fuelCase.sc.initialMass_kg-0.001;
fuelCase.sim.maxDuration_s = 2*fuelCase.thruster.dutyPeriod_s;
exhausted = propagateCase(cases(3),fuelCase);
assert(sum(strcmp({exhausted.eventLog.type},'fuel_exhausted')) == 1);
assert(all(exhausted.state_SI(:,7) >= fuelCase.sc.dryMass_kg-1e-7));
assert(abs(exhausted.state_SI(end,7)-fuelCase.sc.dryMass_kg) < 1e-7);
end
