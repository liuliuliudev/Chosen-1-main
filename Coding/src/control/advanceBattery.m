function [nextEnergy_Wh, unmet_Wh] = advanceBattery(energy_Wh,generation_W,load_W,dt,q)
%ADVANCEBATTERY 能量守恒、充放电功率限制；不能供出的负载单列为缺供。
assert(all(isfinite([energy_Wh generation_W load_W dt])) && dt >= 0);
net = generation_W-load_W;
unmet_Wh = 0;
if net >= 0
    nextEnergy_Wh = min(q.capacity_Wh, ...
        energy_Wh+min(net,q.chargeLimit_W)*q.chargeEfficiency*dt/3600);
else
    available = max(0,energy_Wh-q.minimumFraction*q.capacity_Wh);
    delivered = min([-net*dt/3600,q.dischargeLimit_W*dt/3600, ...
        available*q.dischargeEfficiency]);
    nextEnergy_Wh = energy_Wh-delivered/q.dischargeEfficiency;
    unmet_Wh = -net*dt/3600-delivered;
end
end
