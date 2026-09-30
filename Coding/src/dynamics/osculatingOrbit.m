function elements = osculatingOrbit(x, p)
%OSCULATINGORBIT 从 ECI 位置速度计算二体密切轨道诊断量。
r = x(1:3); v = x(4:6);
rr = norm(r); vv2 = dot(v,v);
specificEnergy = vv2/2-p.earth.mu/rr;
hvec = cross(r,v);
evec = cross(v,hvec)/p.earth.mu-r/rr;
elements.a_m = -p.earth.mu/(2*specificEnergy);
elements.e = norm(evec);
elements.perigeeAltitude_m = elements.a_m*(1-elements.e)-p.earth.RE;
elements.apogeeAltitude_m = elements.a_m*(1+elements.e)-p.earth.RE;
elements.specificEnergy_Jkg = specificEnergy;
elements.angularMomentum_m2s = norm(hvec);
end
