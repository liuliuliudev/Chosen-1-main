function p = baseline_case()
%BASELINE_CASE 概念仿真的统一基准参数入口。
root = fileparts(fileparts(mfilename('fullpath')));
p.earth = constants();
% 卫星质量由干质量和推进剂质量组成，初始状态为 550 km 圆轨道。
p.sc.initialMass_kg = 50;
p.sc.propellant_kg = 0.8;
p.sc.dryMass_kg = p.sc.initialMass_kg - p.sc.propellant_kg;
p.sc.initialAltitude_m = 550e3;
p.sc.inclination_rad = deg2rad(53);
p.sc.Cd = 2.2;
p.sc.bodyArea_m2 = 0.5;
p.sail.addedArea_m2 = 10;
p.thruster.thrust_N = 0.020;
p.thruster.Isp_s = 1200;
p.thruster.dutyFraction = 0.5;
% 用初始圆轨道周期作为推力开关周期。
r0 = p.earth.RE + p.sc.initialAltitude_m;
p.thruster.dutyPeriod_s = 2*pi*sqrt(r0^3/p.earth.mu);
p.atmosphere.scale = 1;
p.atmosphere.model = 'exponential';
% 该大气表只是候选输入，正式结论前必须核对来源。
p.atmosphere.table_SI = loadAtmosphereTable(fullfile(root,'data','processed', ...
    'exponential_atmosphere_candidate.csv'));
p.mission.switchAltitude_m = 350e3;
p.mission.reentryAltitude_m = 120e3;
% 原轨道窗口仅用于事后评价，不参与控制切换。
p.mission.windowLowerAltitude_m = 500e3;
p.mission.windowUpperAltitude_m = 600e3;
% 没有已冻结的硬性期限；365 天只限制数值传播时长。
p.mission.deadline_s = NaN;
p.mission.deadlineSource = 'No fixed deadline in current research definition';
p.sim.maxDuration_s = 365*86400;
p.sim.useJ2 = true;
p.sim.useDrag = true;
p.sim.useThrust = true;
p.sim.relTol = 1e-9;
p.sim.absTol = [1e-3;1e-3;1e-3;1e-6;1e-6;1e-6;1e-9];
p.sim.maxStep_s = 1800;
p.sim.solver = 'ode113';
% 设计取舍比较容差，避免把微小数值差解释成物理优势。
p.analysis.windowTolerance_s = 60;
p.analysis.reentryTolerance_s = 60;
p.analysis.propellantTolerance_kg = 1e-4;
validateCase(p);
end
