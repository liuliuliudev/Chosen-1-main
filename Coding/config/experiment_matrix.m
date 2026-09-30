function cases = experiment_matrix(group)
%EXPERIMENT_MATRIX 定义各组实验案例；每次传播都从同一基准参数开始。
if nargin == 0, group = 'baselines'; end
switch lower(group)
    case 'baselines'
        % B0 不启用控制，B1 展帆，B2 推进，P 为推进与展帆协同。
        ids = {'B0','B1','B2','P'};
        cases = repmat(struct('id','','strategy','','fault','none', ...
            'switchAltitude_m',NaN,'densityScale',NaN, ...
            'sailAddedArea_m2',NaN,'thrust_N',NaN),1,numel(ids));
        for k = 1:numel(ids)
            cases(k).id = ids{k};
            cases(k).strategy = ids{k};
        end
    case 'switch'
        % 扫描 P 策略的展帆切换高度，单位为米。
        values = [300 325 350 375 400 425 450]*1e3;
        cases = repmat(baseP(''),1,numel(values));
        for k = 1:numel(values)
            cases(k) = baseP(sprintf('SW%03d',values(k)/1e3));
            cases(k).switchAltitude_m = values(k);
        end
    case 'density'
        % 每次只修改大气密度倍率，其余参数保持基准值。
        values = [0.5 0.75 1 1.5 2];
        cases = repmat(baseP(''),1,numel(values));
        for k = 1:numel(values)
            cases(k) = baseP(sprintf('RHO_%g',values(k)));
            cases(k).densityScale = values(k);
        end
    case 'sail'
        % 扫描帆相对卫星本体增加的迎风面积。
        values = [5 10 15 20];
        cases = repmat(baseP(''),1,numel(values));
        for k = 1:numel(values)
            cases(k) = baseP(sprintf('SAIL_%g',values(k)));
            cases(k).sailAddedArea_m2 = values(k);
        end
    case 'thrust'
        % 扫描推力大小；案例名称中的数字单位为毫牛。
        values = [10 20 30 40]*1e-3;
        cases = repmat(baseP(''),1,numel(values));
        for k = 1:numel(values)
            cases(k) = baseP(sprintf('T_%g',values(k)*1e3));
            cases(k).thrust_N = values(k);
        end
    case 'faults'
        % 故障行为由 controlPolicy 根据 F1 至 F4 进一步定义。
        names = {'F1','F2','F3','F4'};
        cases = repmat(baseP(''),1,numel(names));
        for k = 1:numel(names)
            cases(k) = baseP(names{k});
            cases(k).fault = names{k};
        end
    case 'supervised'
        cases = baseP('SUP_NOMINAL');
        cases.supervisor = struct('enabled',true, ...
            'retirementAuthorized',true,'powerAvailable_W',650, ...
            'attitudeReady',true,'thrusterHealthy',true);
    otherwise
        error('Unknown experiment group: %s',group);
end
end

function c = baseP(id)
c = struct('id',id,'strategy','P','fault','none', ...
    'switchAltitude_m',NaN,'densityScale',NaN, ...
    'sailAddedArea_m2',NaN,'thrust_N',NaN);
end
