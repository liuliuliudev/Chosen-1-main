function x0 = initialOrbitState(p)
%INITIALORBITSTATE 构造升交点处的地心惯性系圆轨道初始状态。
r0 = p.earth.RE + p.sc.initialAltitude_m;
v0 = sqrt(p.earth.mu/r0);
i = p.sc.inclination_rad;
% 位置置于 x 轴，速度位于 yz 平面；末项为初始总质量。
x0 = [r0;0;0;0;v0*cos(i);v0*sin(i);p.sc.initialMass_kg];
end
