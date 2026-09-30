function rho = densityExponential(h, p)
%DENSITYEXPONENTIAL 分段指数大气模型，输入高度 h 的单位为 m。
% 大气表每行依次为参考高度 m、参考密度 kg/m^3、尺度高度 m；当前数据待核源。
% 事件求根可能试探到 120 km 以下；只将查表高度钳到首行，轨迹仍应在界面终止。
if ~p.sim.useDrag || p.atmosphere.scale == 0
    rho = zeros(size(h));
    return
end
tab = p.atmosphere.table_SI;
% 高于表格上限时直接报错，避免无依据的高空外推。
if any(h(:) > tab(end,1))
    error('Atmosphere:OutsideTable','Altitude outside atmosphere table coverage.');
end
h = max(h,tab(1,1));
rho = zeros(size(h));
for k = 1:numel(h)
    % 在不超过当前高度的参考行上应用指数衰减。
    idx = find(tab(:,1) <= h(k),1,'last');
    rho(k) = p.atmosphere.scale * tab(idx,2) * ...
        exp(-(h(k)-tab(idx,1))/tab(idx,3));
end
end
