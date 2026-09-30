function dx = orbitalDynamics(~, x, mode, p)
%ORBITALDYNAMICS 一个固定控制片段内的七维连续动力学。
r = x(1:3);
v = x(4:6);
% 依次叠加中心引力、可选 J2、大气阻力和受控推力。
a = gravityTwoBody(r,p);
if p.sim.useJ2, a = a + gravityJ2(r,p); end
a = a + atmosphericDrag(r,v,x(7),mode.sailFraction,p);
[aT, mdot] = lowThrust(v,x(7),mode.thrustOn,p);
% 七维状态为三维位置、三维速度和当前总质量。
dx = [v; a+aT; mdot];
end
