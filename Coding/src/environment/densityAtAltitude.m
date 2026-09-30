function rho = densityAtAltitude(h,p)
%DENSITYATALTITUDE 根据配置选择大气模型。
% 接口统一使用高度 m 和输出密度 kg/m^3，阻力计算无需了解具体模型。
switch p.atmosphere.model
    case 'exponential'
        rho = densityExponential(h,p);
    otherwise
        error('Unsupported atmosphere model: %s',p.atmosphere.model);
end
end
