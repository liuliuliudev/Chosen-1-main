# 受控离轨 MATLAB 仿真工程

## 当前新增的审计与监督案例

`run_input_audit()` 检查候选大气表，并在 `results/tables/input_audit.csv` 逐项标明来源状态。原始大气表尚未核对，状态保持 `unverified`；通过格式和趋势检查不等于物理来源已认证。

`experiment_matrix('supervised')` 生成独立的 `SUP_NOMINAL` 概念案例。它用预置的退役许可、650 W 候选可用功率、姿态与推进器健康标志驱动监督器，再进入轨道传播；这些标志并非真实传感器读数，也没有食期或姿态动力学模型。`run_all` 将其与原 B0/B1/B2/P 分开保存为 `supervised_results.mat` 和 `supervised_summary.csv`。原四策略的控制定义不变。

适用 MATLAB **R2025a**，只依赖 MATLAB 本体。工程内部统一使用 m、s、kg、N、rad。当前是可运行的概念仿真框架；大气表和硬件参数仍是待核实的研究输入，不能直接用于正式物理结论。

## 使用

在 MATLAB 中将当前目录设为 `Coding`，运行：

```matlab
run_quick_demo    % 基础测试 + 短时事件案例 + 对比图
run_all           % 全部 P0 技术实验，长期积分可能耗时
```

单独运行一个案例：

```matlab
startup
p = baseline_case();
cases = experiment_matrix('baselines');
result = propagateCase(cases(4), p);  % P：帆推协同
result.metrics
```

输出写入 `results/tables`、`results/figures`、`results/videos`、`results/logs`。`time_limit` 表示计算上限内未到 120 km；其 `t_120_d=NaN`，不能当作完成时间。窗口指标 `t_window_exit_d` 是密切远地点最后一次降过 500 km 且在剩余已计算轨迹中未回升的时刻；未观测到时为 `NaN`，另报 `windowObservationEnd_d`。`run_quick_demo` 使用 160 km 演示初态，其窗口状态为 `initially_below`，不代表 550 km 主案例。

## 模块与修改入口

| 位置 | 作用 | 常见改动 |
|---|---|---|
| `config/baseline_case.m` | 唯一基准参数 `p` | 卫星、任务、求解器设置 |
| `config/experiment_matrix.m` | 试验案例与扫描值 | 增加情景或扫描点 |
| `src/control/controlPolicy.m` | 策略/故障到动作的映射 | 增加控制策略 |
| `src/control/deorbitStateMachine.m` | 当前阶段的帆/推力命令 | 改变阶段动作接口 |
| `src/propagation/propagateCase.m` | 事件、占空比边界与 ODE 分段 | 增加事件类型 |
| `src/dynamics/`、`src/environment/` | 连续物理模型；大气由 `densityAtAltitude` 分派 | 更换力或大气模型 |
| `src/dynamics/osculatingOrbit.m` | 共享的密切轨道几何计算 | 增加轨道诊断量 |
| `src/propagation/windowBoundaryEvents.m` | 仅记录窗口上下穿越 | 增加观察事件 |
| `src/analysis/`、`src/visualization/` | 指标、表和图 | 增加输出 |

新增策略时，在 `experiment_matrix` 给案例命名，并在 `controlPolicy` 定义各阶段动作；传播器和动力学模块不依赖策略名称。新大气模型在 `densityAtAltitude` 和 `validateCase` 登记；求解器由 `p.sim.solver` 选择。新物理力通过 `p` 和 `orbitalDynamics` 接入，并增加方向、极限或守恒测试。所有图表只读取 `result`；请勿在绘图脚本重新计算或改写轨迹。

## 必须核实的输入

当前研究**不设单一硬性完成期限**：`mission.deadline_s=NaN`、`deadlineMet=NaN` 表示不适用；`sim.maxDuration_s=365` 天只是计算上限。`data/processed/exponential_atmosphere_candidate.csv` 是待原表核对的候选分段指数数据。输入状态记录于 `docs/parameters.md`。正式结果前请先完成出处核对，再运行 `run_all` 和跨机复现。

`run_all` 会重建窗口退出、切换前后一圈诊断、七点切换非劣筛选、数值对照、扫描、故障、图和动画。非劣筛选输出 `results/tables/switch_tradeoff.csv`，未完成案例单列为 `excluded`；它不是连续切换高度的全局优化。**软件运行验收不是物理参数认证**；大气原表、完整赛题文件和硬件预算仍待核实，且需要另一台电脑复现。J2 使瞬时切换不等于整圈已降到切换高度，诊断见 `results/tables/switch_diagnostic.csv`。模块依赖和二次开发入口见 `docs/architecture.md`。

研究定位依据：`../Reference/受控离轨_创新故事与论证主线.md`；原技术计划见 `../Reference/受控离轨_MATLAB仿真最终总方案.md`。本工程只传播至首次下降穿过 120 km，不模拟其后的再入、烧蚀或落区。

## 第 1 次补充（2026-09-27 12:49:35 +08:00）：工程资源预算审计

`run_all` 现会在基准策略传播后调用 `run_engineering_audit`，把独立的候选预算表与 B0/B1/B2/P 已有点火和燃料结果合并。预算只读轨迹，不限制推力、不改变控制策略，也不修改传播器。单独检查静态预算时，可在 `startup` 后运行 `run_engineering_audit()`；若要同时输出案例点火负担，调用 `run_engineering_audit(p,baselineResults,outDir)`。

预算输入在 `config/engineering_budget_candidate.csv`，输出为 `results/tables/engineering_mass.csv`、`engineering_power.csv`、`engineering_thruster.csv`、`engineering_conditions.csv`、`engineering_operations.csv` 和 `engineering_summary.csv`。其中 `knownMass_kg`、`knownLoad_W` 只汇总已填写项；只要有缺项，完整合计和余量保留 `NaN`。`pass` 仅表示账本给定值通过算术检查；当前总体结果为 `unverified`，不表示硬件可行性已认证。功率模式 S0/S1/S2/S3/SAFE 是预算用的概念模式，不是新增的传播器状态或供电模型。接口和扩展规则见 `docs/architecture.md` 末尾补充。

## 第 2 次补充（2026-09-27 13:43:53 +08:00）：候选资源与概念监督

预算表现已填入一组用于方案比较的候选分配：50 kg 中列项合计 48 kg，账面余量 2 kg；向阳条件下假定寿命末期可用 650 W，S1 推进静态负载 560 W，账面余量 90 W。数值来自原四周方案的范围/示例与团队分配假设，不是选型后的器件性能。食期、热约束、供电退化、推进器同工作点和帆有效面积仍未验证，因此总状态继续为 `unverified`。详细逐项依据及外部资料见 `docs/parameters.md` 与 `docs/references.md` 的末尾补充。

`run_all` 现在额外输出 `resource_case_audit.csv`、`supervisor_scenarios.csv`、`evidence_index.csv`、`evidence_context.csv` 和 `evidence_snapshot.mat`。逐案例审计覆盖 B0/B1/B2/P、七点切换、密度/帆面积/推力扫描及 F1-F4；改变推力时，基准推进器功率和干质量不再自动适用；改变帆面积时，基准帆机构质量不再自动适用。监督器只处理人工模拟观测、输出命令与理由码，不参与轨道积分。证据索引记录结果与生成函数，并保存参数快照；当前 Git 仓库没有首个提交，`gitCommit=unavailable`。本次没有修改 `propagateCase`、动力学或原四策略。

## 第 3 次补充（2026-09-27 13:47:57 +08:00）：快速演示图与主案例隔离

`run_quick_demo` 的 160 km 短时图现在写入 `results/quick_demo/figures`。此前它会覆盖 `results/figures` 中同名的 550 km 基准图，可能使证据索引中的图片与主案例结果不一致。主案例图仍由 `run_all` 输出到 `results/figures`；快速演示输出不作为正式主案例证据。本次发现后，已从已保存的 `baselines_results.mat` 恢复主案例图。
