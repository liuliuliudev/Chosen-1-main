function testPowerPerturbation()
p=baseline_case(); c=experiment_matrix('uncertainty_u1');
combined=experiment_matrix('uncertainty_u2'); qc=powerScenario(p,combined);
assert(combined.supervisor.powerAvailable_W==585 && qc.capacity_Wh==270 && qc.initialFraction==0.7);
assert(abs(modePowerLoad("deploying",false,qc)-261)<1e-9);
assert(combined.reserveFraction==c(1).reserveFraction && combined.deploymentDelay_s==c(1).deploymentDelay_s);
q=powerScenario(p,c(1)); old=powerScenario(p);
assert(isequaln(q,old));
q=powerScenario(p,c(3)); assert(q.capacity_Wh==270 && q.initialFraction==0.8);
q=powerScenario(p,c(4)); assert(q.capacity_Wh==300 && q.initialFraction==0.7);
q=powerScenario(p,c(5));
assert(abs(modePowerLoad("safe",false,q)-251)<1e-9);
assert(abs(modePowerLoad("thrust",true,q)-581)<1e-9);
assert(abs(modePowerLoad("deploying",false,q)-261)<1e-9);
assert(q.ledger.value(q.ledger.itemId=="thruster_input")==350);
assert(q.ledger.value(q.ledger.itemId=="sail_deployment")==30);
bad=c(1); bad.powerPerturbation.initialFraction=0.1;
try
    powerScenario(p,bad); error('Test:ExpectedFailure','Invalid SOC accepted.');
catch e
    assert(strcmp(e.identifier,'PowerScenario:InvalidPerturbation'));
end
p.sim.maxDuration_s=3600;
r=propagateCase(c(5),p);
assert(all(ismember(round(r.power.history.load_W),[251 581])));
end
