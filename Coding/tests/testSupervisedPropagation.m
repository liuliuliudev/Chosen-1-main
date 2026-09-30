function testSupervisedPropagation()
%TESTSUPERVISEDPROPAGATION Check the separate supervised trajectory path.
p = baseline_case();
p.sc.initialAltitude_m = 140e3;
p.mission.switchAltitude_m = 130e3;
p.sim.maxDuration_s = 2*86400;
c = experiment_matrix('supervised');
r = propagateCase(c(1),p);
assert(strcmp(r.status,'reentry'));
assert(sum(strcmp({r.eventLog.type},'switch')) == 1);
assert(any(strcmp({r.eventLog.detail},'THRUST_PERMITTED')));
assert(any(strcmp({r.eventLog.detail},'SAIL_CONFIRMED')));
assert(any(r.sailFraction == 1) && all(diff(r.time_s) > 0));
assert(all(r.state_SI(:,7) >= p.sc.dryMass_kg-1e-7));
safe = propagateCase(c(3),p);
assert(all(~safe.thrustOn) && any(safe.sailFraction == 1));
assert(any(strcmp({safe.eventLog.detail},'THRUST_POWER_INSUFFICIENT')));
failed = propagateCase(c(2),p);
assert(all(~failed.thrustOn) && any(failed.sailFraction == 1));
assert(any(strcmp({failed.eventLog.detail},'THRUSTER_FAILED_DEPLOY_EARLY')));
attitude = propagateCase(c(4),p);
assert(all(~attitude.thrustOn) && all(attitude.sailFraction == 0));
assert(any(strcmp({attitude.eventLog.detail},'ATTITUDE_UNAVAILABLE')));
end
