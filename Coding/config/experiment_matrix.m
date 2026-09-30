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
        nominal = baseP('SUP_NOMINAL');
        nominal.supervisor = struct('enabled',true, ...
            'retirementAuthorized',true,'powerAvailable_W',650, ...
            'attitudeReady',true,'thrusterHealthy',true);
        cases = repmat(nominal,1,4);
        cases(1) = nominal;
        cases(2).id = 'SUP_THRUSTER_FAILED';
        cases(2).supervisor.thrusterHealthy = false;
        cases(3).id = 'SUP_THRUST_POWER_LOW';
        cases(3).supervisor.powerAvailable_W = 500;
        cases(4).id = 'SUP_ATTITUDE_UNAVAILABLE';
        cases(4).supervisor.attitudeReady = false;
    case 'hardware'
        c = baseP('HW_BHT200');
        c.thrust_N = 0.013;
        c.Isp_s = 1390;
        c.effectiveAreaFactor = 1;
        cases = c;
        for factor = [0.75 0.5 0.25]
            c = baseP(sprintf('AREA_FACTOR_%g',factor));
            c.Isp_s = NaN;
            c.effectiveAreaFactor = factor;
            cases(end+1) = c;
        end
    case 'power'
        base = experiment_matrix('supervised');
        cases = base(1);
        cases.id = 'SUP_POWER_650';
        cases.powerModel = true;
        cases(2) = cases(1);
        cases(2).id = 'SUP_POWER_500';
        cases(2).supervisor.powerAvailable_W = 500;
    case 'control_a'
        cases = experiment_matrix('power');
        for k=1:2
            cases(k).id = sprintf('A_POWER_%d',cases(k).supervisor.powerAvailable_W);
            cases(k).improvedControl = true;
            cases(k).deploymentDelay_s = 120;
            cases(k).deploymentTimeout_s = 300;
            cases(k).deploymentOutcome = 'deployed';
        end
        cases(3) = cases(1);
        cases(3).id = 'A_DEPLOY_TIMEOUT';
        cases(3).deploymentOutcome = 'timeout';
        cases(4) = cases(1);
        cases(4).id = 'A_DEPLOY_PARTIAL';
        cases(4).deploymentOutcome = 'partial';
    case 'power_a1'
        base = experiment_matrix('power');
        template=base(1);
        template.unifiedLoads=true;
        template.improvedControl=false;
        template.reserveFraction=0;
        template.deploymentModel=false;
        cases=repmat(template,1,8);
        n=0;
        for solar=[650 500]
            n=n+1; cases(n)=template;
            cases(n).id=sprintf('A1_OLD_%d',solar);
            cases(n).supervisor.powerAvailable_W=solar;
            for reserve=[0 0.1 0.2]
                n=n+1; cases(n)=template;
                cases(n).id=sprintf('A1_NEW_%d_R%02d',solar,round(100*reserve));
                cases(n).supervisor.powerAvailable_W=solar;
                cases(n).improvedControl=true;
                cases(n).reserveFraction=reserve;
            end
        end
    case 'deployment_a2'
        a=experiment_matrix('power_a1'); base=a(3);
        base.deploymentModel=true;
        base.deploymentDelay_s=120; base.confirmationDelay_s=10;
        base.deploymentTimeout_s=600; base.deploymentActualFraction=1;
        base.deploymentFeedback=true; base.deploymentAreaRamp=true;
        cases=repmat(base,1,10);
        cases(1).id='A2_IDEAL'; cases(1).deploymentModel=false;
        for k=2:4
            seconds=[60 120 300]; cases(k).id=sprintf('A2_NORMAL_%d',seconds(k-1));
            cases(k).deploymentDelay_s=seconds(k-1);
        end
        cases(5).id='A2_PARTIAL'; cases(5).deploymentActualFraction=0.5;
        cases(6).id='A2_FAILED'; cases(6).deploymentActualFraction=0;
        cases(7).id='A2_LOST_DEPLOYED'; cases(7).deploymentFeedback=false;
        cases(8).id='A2_LOST_STOWED'; cases(8).deploymentFeedback=false; cases(8).deploymentActualFraction=0;
        cases(9).id='A2_STEP_AREA'; cases(9).deploymentAreaRamp=false;
        cases(10).id='A2_NORMAL_500'; cases(10).supervisor.powerAvailable_W=500;
    case 'uncertainty_u1'
        a=experiment_matrix('deployment_a2'); base=a(3);
        base.powerPerturbation=struct('capacityFactor',1,'initialFraction',0.8,'commonLoadFactor',1);
        cases=repmat(base,1,5);
        cases(1).id='U1_BASE';
        cases(2).id='U1_SOLAR_585'; cases(2).supervisor.powerAvailable_W=585;
        cases(3).id='U1_CAPACITY_270'; cases(3).powerPerturbation.capacityFactor=0.9;
        cases(4).id='U1_INITIAL_70'; cases(4).powerPerturbation.initialFraction=0.7;
        cases(5).id='U1_LOAD_110'; cases(5).powerPerturbation.commonLoadFactor=1.1;
    case 'uncertainty_u2'
        a=experiment_matrix('uncertainty_u1'); cases=a(1);
        cases.id='U2_COMBINED';
        cases.supervisor.powerAvailable_W=585;
        cases.powerPerturbation=struct('capacityFactor',0.9,'initialFraction',0.7,'commonLoadFactor',1.1);
    otherwise
        error('Unknown experiment group: %s',group);
end
end

function c = baseP(id)
c = struct('id',id,'strategy','P','fault','none', ...
    'switchAltitude_m',NaN,'densityScale',NaN, ...
    'sailAddedArea_m2',NaN,'thrust_N',NaN);
end
