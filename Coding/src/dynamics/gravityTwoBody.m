function a = gravityTwoBody(r, p)
%GRAVITYTWOBODY 计算地心惯性系中的地球中心引力加速度。
rr = norm(r);
a = -p.earth.mu * r / rr^3;
end
