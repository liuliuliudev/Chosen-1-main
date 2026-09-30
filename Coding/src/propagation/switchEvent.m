function [value, isterminal, direction] = switchEvent(~, x, p)
%SWITCHEVENT 当密切半长轴对应高度向下越过阈值时触发控制切换。
r = norm(x(1:3));
v2 = dot(x(4:6),x(4:6));
% 由瞬时位置和速度通过活力公式求密切半长轴。
a = 1/(2/r-v2/p.earth.mu);
value = a-p.earth.RE-p.mission.switchAltitude_m;
isterminal = 1;
direction = -1;
end
