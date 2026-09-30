function testTwoBody()
%TESTTWOBODY 检查纯两体模型运行十圈后是否保持守恒量。
p = baseline_case();
% 关闭摄动、阻力和推力，单独验证中心引力积分。
p.sim.useJ2 = false; p.sim.useDrag = false; p.sim.useThrust = false;
x0 = initialOrbitState(p);
period = p.thruster.dutyPeriod_s;
mode = struct('sailFraction',0,'thrustOn',false);
opts = odeset('RelTol',1e-11,'AbsTol',p.sim.absTol/100, ...
    'MaxStep',period/30);
[~,x] = ode113(@(t,s) orbitalDynamics(t,s,mode,p), ...
    [0 10*period],x0,opts);
e0 = stateToElements(x0,p);
e1 = stateToElements(x(end,:).',p);
% 比机械能、比角动量和一整圈后的相对位置误差均需在阈值内。
assert(abs(e1.specificEnergy_Jkg/e0.specificEnergy_Jkg-1) < 1e-5);
assert(abs(e1.angularMomentum_m2s/e0.angularMomentum_m2s-1) < 1e-5);
assert(norm(x(end,1:3).'-x0(1:3))/norm(x0(1:3)) < 1e-3);
end
