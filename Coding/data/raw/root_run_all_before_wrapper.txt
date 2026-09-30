%RUN_ALL 执行完整 P0 实验链，长期积分可能耗时较长。
root = startup();
logDir = fullfile(root,'results','logs');
if ~isfolder(logDir), mkdir(logDir); end
% 每次运行创建带时间戳的日志，便于回查命令窗口输出。
diary(fullfile(logDir,['run_all_' char(datetime('now','Format','yyyyMMdd_HHmmss')) '.txt']));
diary on
run_tests();
p = baseline_case();
out = fullfile(root,'results','tables');
% 先生成基准策略结果，再检查数值精度和各类参数、故障情景。
[baselineResults,~] = run_baselines(p,out);
% 工程预算只读取基准案例结果，不向传播器或控制策略反馈资源结论。
run_engineering_audit(p,baselineResults,out);
switchDiagnostic = analyzeSwitchNeighborhood(baselineResults{4});
writetable(switchDiagnostic,fullfile(out,'switch_diagnostic.csv'));
disp(switchDiagnostic);
run_numerical_check(p,out);
run_switch_scan(p,out);
run_sensitivity(p,out);
run_fault_cases(p,out);
% 扫描与故障均已落盘后，逐案例检查硬件假设是否仍适用。
run_case_resource_audit(out,p);
% 用候选功率数据驱动人工观测情景；决策日志不参与轨道传播。
run_supervisor_scenarios(p,out);
% 第四个基准案例 P 的轨迹用于生成高度随时间变化的动画。
makeOrbitVideo(baselineResults{4});
diary off
% 日志关闭后记录实际文件状态，并保存本次参数与预算快照。
buildEvidenceIndex(root,p);
