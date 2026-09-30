function [available_W, generation_W, nextBoundary_s] = powerAvailability(t,energy_Wh,q)
%POWERAVAILABILITY 初始固定圆轨道代理；阴影居于每圈中间。
start = q.period_s*(1-q.eclipseFraction)/2;
finish = q.period_s*(1+q.eclipseFraction)/2;
cycle = floor(t/q.period_s);
phase = t-cycle*q.period_s;
sunlit = ~(phase >= start-1e-7 && phase < finish-1e-7);
generation_W = q.solarEol_W*sunlit;
remaining = max(0,energy_Wh-q.minimumFraction*q.capacity_Wh);
deliverable_Wh = remaining*q.dischargeEfficiency;
if q.improvedControl
    % 为下个阴影预存完整基础能量；日照中不靠电池补推进功率。
    fullReserve = q.coastLoad_W*(finish-start)/3600 + q.safetyReserve_Wh;
    if sunlit
        if phase < start, timeToEclipse = start-phase;
        else, timeToEclipse = q.period_s-phase+start;
        end
        deficit = max(0,fullReserve-deliverable_Wh);
        chargeNeeded = deficit*3600/(max(q.step_s,timeToEclipse)* ...
            q.chargeEfficiency*q.dischargeEfficiency);
        available_W = max(0,generation_W-min(q.chargeLimit_W,chargeNeeded));
    else
        reserve = q.coastLoad_W*(finish-phase)/3600+q.safetyReserve_Wh;
        available_W = min(q.dischargeLimit_W,min(deliverable_Wh*3600/q.step_s, ...
            q.coastLoad_W+max(0,deliverable_Wh-reserve)*3600/q.step_s));
    end
elseif ~sunlit
    % 阴影内优先保留基础负载直到下一次日照，不用未来真实轨迹。
    baseReserve_Wh = q.coastLoad_W*(finish-phase)/3600;
    extra_W = max(0,deliverable_Wh-baseReserve_Wh)*3600/q.step_s;
    available_W = min(q.dischargeLimit_W, ...
        min(deliverable_Wh*3600/q.step_s,q.coastLoad_W+extra_W));
else
    available_W = generation_W+min(q.dischargeLimit_W, ...
        deliverable_Wh*3600/q.step_s);
end
edges = cycle*q.period_s+[start finish q.period_s];
nextBoundary_s = min(edges(edges > t+1e-7));
if isempty(nextBoundary_s), nextBoundary_s = (cycle+1)*q.period_s+start; end
end
