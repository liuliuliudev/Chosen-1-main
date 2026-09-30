function allowed=canStartDeployment(energy,q,c)
%CANSTARTDEPLOYMENT 保守按展开期间无太阳供电核对完整动作与额外余量。
usable=max(0,energy-q.minimumFraction*q.capacity_Wh)*q.dischargeEfficiency;
needed=q.deployLoad_W*c.deploymentDelay_s/3600+ ...
    q.coastLoad_W*c.confirmationDelay_s/3600+q.safetyReserve_Wh;
allowed=q.dischargeLimit_W>=q.deployLoad_W && usable>=needed;
end
