# 受控离轨 MATLAB 仿真工程

## 当前技术证据与答辩准备

阅读 `docs/最终证据总表.md` 获取分组结果、来源、关键图和未完成项；`docs/评委答辩问答稿_当前版.md` 提供可查证回答。机器可读总表与来源校验值在 `docs/defense_evidence/`。这是已完成实验的整理快照，不是新增仿真或硬件认证。U2已纳入当前24例入口和新版包定义，旧ZIP内容不变。

## 中等不利组合检查U2

`startup; root=run_uncertainty_u2;`仍可独立运行已确认的585 W、270 Wh、初始70%、公共负载＋10%组合，保留其余主案例参数；同时完成能量审计及60/30秒检查。结果与适用边界见 `docs/中等不利组合检查_U2.md`。run_current现在也调用该组。

## 主案例与关键输入检查

当前主案例的输入性质、系统关系图和控制流程见 `docs/主案例说明与系统图.md`。独立中等单因素研究入口为 `startup; root=run_uncertainty_u1;`，仅运行基准、585 W、270 Wh、初始70%、公共负载＋10%五例。使用 `verify_uncertainty_u1(root)` 审计能量和事件，`check_uncertainty_u1_resolution(root)`复算四个扰动，`plot_uncertainty_u1(root)`生成对照图。

U1与一个已确认的中等组合U2现已接入run_current及当前复现比较器，共24案例。较大扰动及其他组合未执行。不能将单因素或一个组合通过外推为真实成功概率；旧18/23案例ZIP不自动包含后续扩展。

## 当前主线的一键入口

根目录或Coding目录执行 `resultRoot=run_current;`，在新建的 `Coding/results/current_时间/` 中统一运行A1八案例、A2十案例、U1五案例、U2一案例、独立审计、必要的60/30秒对照及已有图表。四组分别保存在a1/a2/u1/u2子目录；全部必要产物齐全且审计通过后生成current_evidence.csv。预计比单案例耗时更长，日志在各子目录内。中途失败时目录保留，不能把部分产物称为完整通过。

`run_all`保留为基础四策略及原扩展实验入口，`run_current`不将不同配置下的基础结果混作当前主案例。跨机复现使用 `compare_current_reproduction`，步骤见 `docs/跨机复现说明.md`。

## 第二批展帆过程

`startup; run_deployment_a2;` 在新a2目录运行已确认的10个案例。主案例仍为650 W＋10%余量，加入60/120/300秒实际展开与10秒反馈延迟，600秒无确认进入未知状态。`verify_deployment_a2(outRoot)`独立核对面积、动作、反馈与能量；`check_deployment_a2_resolution(outRoot)`检查正常120秒、半展开及500 W的60/30秒分辨率。

仿真实际面积与控制观测分开：反馈丢失时仍按设定实际面积计算阻力，但控制器不知道面积，不能自动补推。展开期间额外30 W只持续所设动作时间；未确认等待使用SAFE负载。两份Reference文档尚未改写。

## A1第一批供电比较

在 Coding 目录运行 `startup; run_power_a1;`。八个案例在同一电池/日照/模式负载下比较旧调度与提前储能的0%/10%/20%额外余量，输出独立a1目录。可运行 `verify_power_a1(outRoot)` 核算能量账，`check_power_a1_resolution(outRoot)` 检查两种功率的10%余量在60/30秒计算间隔下的差异。详见 `docs/A1供电实验定义.md`。

A1不启用展帆延迟与确认草稿；两份Reference目标文档的拟议措辞单列在 `docs/目标文档修改草案_A1.md`，尚未写回目标原文。

## 当前新增的审计与监督案例

`run_input_audit()` 检查候选大气表，并在 `results/tables/input_audit.csv` 逐项标明来源状态。原始大气表尚未核对，状态保持 `unverified`；通过格式和趋势检查不等于物理来源已认证。

`experiment_matrix('supervised')` 生成独立的正常、初始推进器失效、推进功率不足、姿态不可用四个概念案例。它们用预置的许可、候选功率和健康标志驱动监督器，再进入轨道传播；这些标志并非真实传感器读数，也没有食期或姿态动力学模型。`run_all` 将其与原 B0/B1/B2/P 分开保存为 `supervised_results.mat` 和 `supervised_summary.csv`，并纳入逐案例资源审计。原四策略的控制定义不变。

当前答辩用的提问、证据和未验证边界见 `docs/评委提问与证据边界.md`。监督器已驱动独立的轨道案例，但尚未模拟真实传感器、电源时序或姿态动力学。

固定异常情景的功率只表示一个研究条件，不模拟功率随日照变化。若只复算这组案例，可运行 `runCaseGroup('supervised',baseline_case(),outDir)`，其中 `outDir` 指向新的表格目录；`time_limit` 仍表示在计算上限内没有观察到目标事件。

适用 MATLAB **R2025a**，只依赖 MATLAB 本体。工程内部统一使用 m、s、kg、N、rad。当前是可运行的概念仿真框架；大气表和硬件参数仍是待核实的研究输入，不能直接用于正式物理结论。

## 使用

在 MATLAB 中将当前目录设为 `Coding`，运行：

```matlab
run_quick_demo    % 基础测试 + 短时事件案例 + 对比图
run_all           % 全部 P0 技术实验，长期积分可能耗时
```

现在 `resultRoot = run_all;` 从根目录或 Coding 目录都调用同一完整入口，自动写入 `Coding/results/run_时间戳/` 新目录。可显式传入 Coding/results 下尚不存在的绝对目录；已有目录或范围外路径会被拒绝。历史固定目录输出继续保留。运行结束返回本次结果根目录，图、表、视频、日志和索引均在其中。

本轮补证说明见 `docs/资料核对与工程补证报告.md`，跨机步骤见 `docs/跨机复现说明.md`。新增 `hardware` 组含 BHT-200 厂家参数对照及同帆有效面积折减；`power` 组含显式电池/阴影假设下的供电受限监督轨道。`power_failure` 表示基础用电无法保障，仿真停止。这些不是新增硬件认证。

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
