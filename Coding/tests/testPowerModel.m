function testPowerModel()
p = baseline_case(); q = powerScenario(p);
[e,unmet] = advanceBattery(150,0,90,3600,q);
assert(abs(e-60)<1e-9 && abs(unmet-9)<1e-9);
[e,unmet] = advanceBattery(150,200,100,3600,q);
assert(abs(e-240)<1e-9 && unmet==0);
[e,~] = advanceBattery(299,1000,0,3600,q);
assert(e==q.capacity_Wh);
[~,g,~] = powerAvailability(q.period_s/2,240,q);
assert(g==0);
[~,g,~] = powerAvailability(0,240,q);
assert(g==650);
c = experiment_matrix('power');
p.sim.maxDuration_s = 2*q.period_s;
r = propagateCase(c(1),p);
assert(r.power.minimumBattery_Wh >= q.minimumFraction*q.capacity_Wh-1e-7);
assert(r.power.unmetBaseEnergy_Wh < 1e-7);
assert(r.thrustOn_s > 0 && r.thrustOn_s <= p.sim.maxDuration_s*0.5+1);
p.sim.maxDuration_s = 10*q.period_s;
failed = propagateCase(c(2),p);
assert(strcmp(failed.status,'power_failure') && isnan(failed.metrics.t_120_d));
assert(failed.power.unmetBaseEnergy_Wh > 1e-7);
eng = experiment_matrix('hardware');
[~,device] = faultInjection(eng(1),p);
assert(device.thruster.Isp_s==1390 && device.thruster.thrust_N==0.013);
[area,pa] = faultInjection(eng(end),p);
assert(pa.sail.addedArea_m2==p.sail.addedArea_m2 && area.policy.sailAfter==0.25);
end
