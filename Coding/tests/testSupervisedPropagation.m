function testSupervisedPropagation()
%TESTSUPERVISEDPROPAGATION Check the separate supervised trajectory path.
p = baseline_case();
p.sc.initialAltitude_m = 140e3;
p.mission.switchAltitude_m = 130e3;
p.sim.maxDuration_s = 2*86400;
c = experiment_matrix('supervised');
r = propagateCase(c,p);
assert(strcmp(r.status,'reentry'));
assert(sum(strcmp({r.eventLog.type},'switch')) == 1);
assert(any(strcmp({r.eventLog.detail},'THRUST_PERMITTED')));
assert(any(strcmp({r.eventLog.detail},'SAIL_CONFIRMED')));
assert(any(r.sailFraction == 1) && all(diff(r.time_s) > 0));
assert(all(r.state_SI(:,7) >= p.sc.dryMass_kg-1e-7));
c.supervisor.powerAvailable_W = 200;
safe = propagateCase(c,p);
assert(all(~safe.thrustOn) && all(safe.sailFraction == 0));
assert(any(strcmp({safe.eventLog.detail},'BASE_POWER_INSUFFICIENT')));
end
