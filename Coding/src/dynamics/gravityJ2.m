function a = gravityJ2(r, p)
%GRAVITYJ2 在地心惯性系中计算地球扁率的一阶 J2 摄动加速度。
rr = norm(r);
z2r2 = (r(3)/rr)^2;
% 公共系数与各坐标分量分开计算，便于核对 J2 公式。
c = 1.5*p.earth.J2*p.earth.mu*p.earth.RE^2/rr^5;
a = c * [r(1)*(5*z2r2-1);r(2)*(5*z2r2-1); ...
    r(3)*(5*z2r2-3)];
end
