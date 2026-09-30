function testDeploymentProcess()
c=experiment_matrix('deployment_a2'); q=powerScenario(baseline_case());
q.deployLoad_W=240; q.safetyReserve_Wh=15;
assert(~canStartDeployment(60,q,c(3)) && canStartDeployment(240,q,c(3)));
d=deploymentState(60,0,c(3)); assert(d.fraction==0.5 && d.observation=="unknown" && d.active);
d=deploymentState(120,0,c(3)); assert(d.fraction==1 && ~d.active && ~d.confirmed);
d=deploymentState(130,0,c(3)); assert(d.confirmed && d.observation=="deployed");
a=deploymentState(600,0,c(7)); b=deploymentState(600,0,c(8));
assert(a.timeout && b.timeout && a.observation==b.observation && a.fraction==1 && b.fraction==0);
p=baseline_case(); p.sc.initialAltitude_m=160e3; p.mission.switchAltitude_m=159e3;
% 展开结束后的固定面积受力与原通用适配器完全相同。
x=initialOrbitState(p); mode=struct('sailFraction',1,'thrustOn',false);
assert(isequal(deploymentDynamics(700,x,mode,p,0,c(3)),orbitalDynamics(700,x,mode,p)));
p.sim.maxDuration_s=86400;
for k=[3 5 6 7 8]
    r=propagateCase(c(k),p);
    ev=r.eventLog; started=find(strcmp({ev.type},'deployment_started'));
    assert(numel(started)==1);
    t=ev(started).time_s;
    h=r.power.history;
    active=h.start_s>=t-1e-6 & h.start_s<t+120-1e-6;
    assert(all(h.load_W(active)==240) && all(h.thrustOn(active)==0));
    assert(abs(sum((h.end_s(active)-h.start_s(active))*30/3600)-1)<1e-5);
    if k>=7
        assert(~any(r.thrustOn(r.time_s>=t)));
        assert(~any(strcmp({ev.type},'deployment_confirmed')));
    end
end
end
