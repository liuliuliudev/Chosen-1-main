function policy = controlPolicy(c)
%CONTROLPOLICY 将策略和故障名称转换为各阶段的控制命令。
% 策略名称只在此处解释，传播器只读取返回的控制字段。
policy = struct('initialPhase','coast','watchSwitch',false, ...
    'sailBefore',0,'sailAfter',0,'thrustBefore',false, ...
    'thrustAfter',false,'initialEventType','','initialEventDetail','', ...
    'switchEventType','','switchEventDetail','');
switch upper(c.strategy)
    case 'B0'
        % 无推进、无展帆，仅受环境力影响。
    case 'B1'
        % 从一开始就全部展帆。
        policy.initialPhase = 'sail';
        policy.sailBefore = 1;
    case 'B2'
        % 仅在占空比允许时使用逆行推力。
        policy.initialPhase = 'thrust';
        policy.thrustBefore = true;
    case 'P'
        % 到切换高度前推进，之后全部展帆。
        policy.initialPhase = 'pre_switch';
        policy.watchSwitch = true;
        policy.thrustBefore = true;
        policy.sailAfter = 1;
    otherwise
        error('Unknown strategy: %s',c.strategy);
end
switch upper(c.fault)
    case 'NONE'
    case 'F1'
        % 推进器立即失效，直接改为全部展帆。
        assert(strcmpi(c.strategy,'P'),'Faults require strategy P.');
        policy.initialPhase = 'sail';
        policy.watchSwitch = false;
        policy.sailBefore = 1;
        policy.thrustBefore = false;
        policy.initialEventType = 'thruster_failure';
        policy.initialEventDetail = 'immediate full sail';
    case 'F2'
        % 只展开一半帆，同时继续按占空比推进。
        assert(strcmpi(c.strategy,'P'),'Faults require strategy P.');
        policy.sailAfter = 0.5;
        policy.thrustAfter = true;
        policy.switchEventType = 'sail_partial';
        policy.switchEventDetail = 'half sail; continue duty-cycled thrust';
    case 'F3'
        % 帆无法展开，只能继续推进。
        assert(strcmpi(c.strategy,'P'),'Faults require strategy P.');
        policy.sailAfter = 0;
        policy.thrustAfter = true;
        policy.switchEventType = 'sail_failed';
        policy.switchEventDetail = 'no sail; continue duty-cycled thrust';
    case 'F4'
        % 大气密度折半由 faultInjection 修改参数实现。
        assert(strcmpi(c.strategy,'P'),'Faults require strategy P.');
        policy.initialEventType = 'low_density';
        policy.initialEventDetail = 'atmosphere scale fixed at 0.5';
    otherwise
        error('Unknown fault: %s',c.fault);
end
end
