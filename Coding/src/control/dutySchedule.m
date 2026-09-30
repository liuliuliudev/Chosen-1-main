function [on, nextBoundary_s] = dutySchedule(t, p)
%DUTYSCHEDULE 计算当前推力占空比状态和下一次开关边界。
f = p.thruster.dutyFraction;
period = p.thruster.dutyPeriod_s;
% 0 和 1 对应常关、常开，不需要安排下一次边界。
if f == 0
    on = false; nextBoundary_s = inf; return
elseif f == 1
    on = true; nextBoundary_s = inf; return
end
k = floor(t/period);
phase = t-k*period;
% 每个周期的前 f 部分开启推进器，其余时间关闭。
if phase < f*period - 1e-8
    on = true;
    nextBoundary_s = k*period + f*period;
else
    on = false;
    nextBoundary_s = (k+1)*period;
end
if nextBoundary_s <= t
    % 浮点舍入时仍需保证下一个边界严格晚于当前时刻。
    nextBoundary_s = t + period*1e-10;
end
end
