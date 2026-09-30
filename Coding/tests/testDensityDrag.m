function testDensityDrag()
%TESTDENSITYDRAG 检查密度递减、展帆增阻和阻力方向。
p = baseline_case(); x = initialOrbitState(p);
heights = [120 200 350 550 650]*1e3;
rho = densityExponential(heights,p);
% 高度升高时密度应严格下降。
assert(all(rho > 0) && all(diff(rho) < 0));
[a0,vrel] = atmosphericDrag(x(1:3),x(4:6),x(7),0,p);
a1 = atmosphericDrag(x(1:3),x(4:6),x(7),1,p);
assert(dot(a1,vrel) < 0 && norm(a1) > norm(a0));
p.atmosphere.scale = 0;
% 密度倍率为零时，阻力也必须为零。
assert(norm(atmosphericDrag(x(1:3),x(4:6),x(7),1,p)) == 0);
end
