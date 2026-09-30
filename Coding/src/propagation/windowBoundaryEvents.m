function [value, isterminal, direction] = windowBoundaryEvents(~, x, p)
%WINDOWBOUNDARYEVENTS 记录密切远地点穿越原轨道窗口下边界的方向。
elements = osculatingOrbit(x,p);
offset = elements.apogeeAltitude_m-p.mission.windowLowerAltitude_m;
value = [offset;offset];
isterminal = [0;0];
direction = [-1;1];
end
