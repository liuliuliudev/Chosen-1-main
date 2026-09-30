function testAdvanceReserve()
%TESTADVANCERESERVE 人工测试值只验证逻辑，不指定正式实验余量。
p=baseline_case(); q=powerScenario(p);
q.improvedControl=true; q.safetyReserve_Wh=0;
q.coastLoad_W=modePowerLoad("safe",false,q);
q.thrustLoad_W=modePowerLoad("thrust",true,q);
assert(q.coastLoad_W==230 && q.thrustLoad_W==560);
assert(modePowerLoad("sail",false,q)==215);
assert(modePowerLoad("deploying",false,q)==240);
start=q.period_s*(1-q.eclipseFraction)/2;
% 日照中仅有少量储能，必须为即将到来的阴影让出充电功率。
[allowed,solar]=powerAvailability(start-120,65,q);
assert(allowed<q.thrustLoad_W && allowed<=solar);
% 增加预留不能反而增加允许推进的功率。
[a,~,~]=powerAvailability(0,240,q);
q.safetyReserve_Wh=30;
[b,~,~]=powerAvailability(0,240,q);
assert(b<=a);
% 旧策略与新预留值无关。
q.improvedControl=false;
[old1,~,~]=powerAvailability(0,240,q);
q.safetyReserve_Wh=NaN;
[old2,~,~]=powerAvailability(0,240,q);
assert(old1==old2);
c=experiment_matrix('power_a1'); p.sim.maxDuration_s=2*q.period_s;
a=propagateCase(c(7),p); c(7).powerStep_s=30;
b=propagateCase(c(7),p);
assert(abs(a.thrustOn_s-b.thrustOn_s)<1e-4);
end
