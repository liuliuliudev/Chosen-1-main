function [a, vrel] = atmosphericDrag(r, v, mass, sailFraction, p)
%ATMOSPHERICDRAG 按与地球共同旋转的大气计算阻力加速度。
% 相对速度扣除大气随地球自转的速度。
vrel = v - cross([0;0;p.earth.omegaE],r);
if ~p.sim.useDrag
    a = zeros(3,1);
    return
end
rho = densityAtAltitude(norm(r)-p.earth.RE,p);
% 展帆比例仅作用于额外帆面积，本体迎风面积始终存在。
area = p.sc.bodyArea_m2 + sailFraction*p.sail.addedArea_m2;
% 二次阻力方向与相对速度相反，除以当前质量得到加速度。
a = -0.5*rho*p.sc.Cd*area/mass*norm(vrel)*vrel;
end
