%RUN_QUICK_DEMO 用短时案例检查完整流程，不能代替基准实验。
root = startup();
run_tests();
p = baseline_case();
% 降低初始高度并缩短计算时限，让切换和再入事件快速出现。
p.sc.initialAltitude_m = 160e3;
p.mission.switchAltitude_m = 145e3;
p.sim.maxDuration_s = 3*86400;
validateCase(p);
cases = experiment_matrix('baselines');
% 只比较单独展帆的 B1 和先推后展帆的 P。
results = {propagateCase(cases(2),p),propagateCase(cases(4),p)};
summary = summarizeRuns(results);
disp(summary);
% 演示初态为 160 km，输出单独存放，避免覆盖 550 km 正式案例图。
plotCoreResults(results,'baselines',fullfile(root,'results','quick_demo'));
