function testThrustMass()
%TESTTHRUSTMASS 检查逆行推力、燃料消耗和占空比边界。
p = baseline_case(); x = initialOrbitState(p);
[a,mdot] = lowThrust(x(4:6),x(7),true,p);
% 点火时加速度应与速度反向，同时质量减小。
assert(dot(a,x(4:6)) < 0 && mdot < 0);
[a,mdot] = lowThrust(x(4:6),x(7),false,p);
assert(norm(a) == 0 && mdot == 0);
p.thruster.thrust_N = 0;
[a,mdot] = lowThrust(x(4:6),x(7),true,p);
assert(norm(a) == 0 && mdot == 0);
[on,next] = dutySchedule(0,p);
% 默认占空比为 50%，第一段开启窗口应持续半个周期。
assert(on && abs(next-p.thruster.dutyPeriod_s/2) < 1e-6);
end
