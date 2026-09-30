function [a, mdot] = lowThrust(v, mass, thrustOn, p)
%LOWTHRUST 计算逆行低推力和燃料消耗；干质量限制由传播器处理。
a = zeros(3,1);
mdot = 0;
if ~thrustOn || ~p.sim.useThrust || p.thruster.thrust_N == 0
    return
end
speed = norm(v);
if speed > 0
    % 推力沿速度反方向，质量流率由推力、比冲和标准重力确定。
    a = -p.thruster.thrust_N/mass * v/speed;
    mdot = -p.thruster.thrust_N/(p.thruster.Isp_s*p.earth.g0);
end
end
