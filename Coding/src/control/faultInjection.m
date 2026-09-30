function [c, p] = faultInjection(c, p)
%FAULTINJECTION 在轨道传播前把案例参数和故障设置应用到基准参数。
% 案例字段与目标参数一一对应，NaN 表示沿用基准值。
fields = {'switchAltitude_m','densityScale','sailAddedArea_m2','thrust_N'};
targets = {'mission.switchAltitude_m','atmosphere.scale', ...
    'sail.addedArea_m2','thruster.thrust_N'};
for k = 1:numel(fields)
    if isfield(c,fields{k}) && isfinite(c.(fields{k}))
        parts = strsplit(targets{k},'.');
        p.(parts{1}).(parts{2}) = c.(fields{k});
    end
end
if ~isfield(c,'fault'), c.fault = 'none'; end
switch upper(c.fault)
    case 'F4'
        % F4 模拟低密度环境，其余故障只改变控制策略。
        p.atmosphere.scale = 0.5;
    case {'NONE','F1','F2','F3'}
    otherwise
        error('Unknown fault: %s',c.fault);
end
validateCase(p);
% 将案例名称转为传播器可以直接使用的控制策略。
c.policy = controlPolicy(c);
end
