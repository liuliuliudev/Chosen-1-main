function [value, isterminal, direction] = reentryEvent(~, x, p)
%REENTRYEVENT 在向下穿过设定的再入高度时终止积分。
value = norm(x(1:3))-p.earth.RE-p.mission.reentryAltitude_m;
isterminal = 1;
% 只接受由正变负的穿越，避免向上经过同一高度时误触发。
direction = -1;
end
