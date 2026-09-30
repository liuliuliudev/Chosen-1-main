function mode = deorbitStateMachine(policy, phase, dutyOn, fuelAvailable, p)
%DEORBITSTATEMACHINE 根据当前阶段和策略确定一个积分片段内的控制状态。
% 占空比关闭期间仍保留推进资格，传播器才能安排下一个开启边界。
% 本函数只生成命令，不改变轨道状态。
post = strcmp(phase,'post_switch');
if post
    sailFraction = policy.sailAfter;
    thrustRequested = policy.thrustAfter;
else
    sailFraction = policy.sailBefore;
    thrustRequested = policy.thrustBefore;
end
eligible = thrustRequested && fuelAvailable && p.sim.useThrust && ...
    p.thruster.thrust_N > 0;
% 实际点火还必须处在占空比开启窗口内。
mode = struct('phase',phase,'sailFraction',sailFraction, ...
    'thrustEligible',eligible,'thrustOn',eligible && dutyOn, ...
    'watchSwitch',policy.watchSwitch && strcmp(phase,'pre_switch'));
end
