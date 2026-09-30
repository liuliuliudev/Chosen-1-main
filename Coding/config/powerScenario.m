function q = powerScenario(p,c)
%POWERSCENARIO 显式的候选供电情景；不是器件选型或真实日照预报。
q.period_s = p.thruster.dutyPeriod_s;
q.eclipseFraction = asin(p.earth.RE/(p.earth.RE+p.sc.initialAltitude_m))/pi;
q.solarEol_W = 650;             % 沿用向阳候选值；beta=0 圆轨道阴影近似
q.capacity_Wh = 300;            % 新研究假设，不代表现有电池
q.initialFraction = 0.8;
q.minimumFraction = 0.2;
q.chargeEfficiency = 0.9;
q.dischargeEfficiency = 0.9;
q.chargeLimit_W = 400;
q.dischargeLimit_W = 600;
q.step_s = 60;
q.controlPeriod_s = 60; % 新策略固定决策周期，与计算细分间隔分离
q.coastLoad_W = 215;
q.thrustLoad_W = 560;
q.status = 'team_assumption';
q.improvedControl = false; % 旧供电案例保持原定义，A路线新案例单独启用
q.safetyReserve_Wh = NaN; % 新策略必须显式指定研究余量，不能使用未确认默认值
ledger=loadEngineeringBudget();
if nargin>1 && isfield(c,'powerPerturbation')
    u=c.powerPerturbation;
    assert(all(isfinite([u.capacityFactor u.initialFraction u.commonLoadFactor])) && ...
        u.capacityFactor>0 && u.initialFraction>=q.minimumFraction && u.initialFraction<=1 && u.commonLoadFactor>0, ...
        'PowerScenario:InvalidPerturbation','Invalid power scenario override.');
    q.capacity_Wh=q.capacity_Wh*u.capacityFactor;
    q.initialFraction=u.initialFraction;
    selected=ledger.kind=="power_load" & ledger.mode=="all";
    ledger.value(selected)=ledger.value(selected)*u.commonLoadFactor;
end
budget = computeEngineeringBudget(p,ledger);
q.modeLoads = budget.power(:,{'mode','peakLoad_W'});
q.ledger=ledger;
end
