# 资料登记

- 主设计依据：`../../Document/受控离轨_MATLAB仿真最终总方案.md`，版本 v1.0。
- MATLAB 求解器：MathWorks `ode113` 官方文档，https://www.mathworks.com/help/matlab/ref/ode113.html 。
- 比赛最新规则、120 km 和任务时限条款：待团队查证并记录版本、页码。
- 候选大气表原始出版物及逐行对照：待查证；当前表不得标为已验证来源。
- 推进器 20 mN / 1200 s / 350 W、帆面积与质量预算：待查证具体器件资料或明确为假设。

补资料时记录标题、作者/机构、版本或出版年、页码/表号、链接、访问日期及实际采用的数据行。

## 第 1 次补充（2026-09-27 00:51:24 +08:00）

- 当前研究定位以 `../../Reference/受控离轨_创新故事与论证主线.md` 的最新补充为准；动力学与原始 P0 清单参见 `../../Reference/受控离轨_MATLAB仿真最终总方案.md`。
- 上方“主设计依据”和“120 km 和任务时限条款”保留为历史记录。现行定义中，500–600 km 原轨道窗口和 120 km 模型终点由团队选择，不是已核实的比赛规定；不设单一任务期限，365 天只是计算上限。最新赛事文件仍待核查。

## 第 2 次补充（2026-09-27 13:43:53 +08:00）：候选预算依据与适用范围

- 工程内部数值依据：`../../Document/受控离轨详细方案_四周MATLAB实施版.md` 第 2.3 节。其帆机构 2.0–3.5 kg、推进器/电源处理 2.0–4.0 kg、贮供 0.8–1.5 kg、展帆瞬时 10–30 W，以及 650 W 可用功率、180 W 平台负载、350 W 推进器输入和约 30 W 控制/热控，是**概念示例**，不是已选器件数据。新账本的 17 kg 平台、18 kg 供电、4 kg 姿态监测和 1 kg 其余质量为团队为 50 kg 闭合而设的分配额度，没有外部器件出处。
- NASA, *Small Spacecraft Technology State of the Art: In-Space Propulsion*, https://www.nasa.gov/smallsat-institute/sst-soa/in-space_propulsion/ ，访问日期 2026-09-27。文中 VENuS 的 IHET-300 在轨工作功率约 250–600 W，可作为数百瓦级电推进存在的例子；该卫星质量约 268 kg，并非本项目 50 kg 推进系统，不能证明 20 mN/1200 s/350 W 同时成立。
- NASA, *Small Spacecraft Technology State of the Art: Power*, https://www.nasa.gov/smallsat-institute/sst-soa/power/ ，访问日期 2026-09-27。文中强调太阳翼寿命末期输出、食期和太阳入射角；本项目 650 W 与 18 kg 只是向阳候选，不是从该网页提取的器件点值。
- NASA, *Small Spacecraft Technology State of the Art: Deorbit Systems*, https://www.nasa.gov/smallsat-institute/sst-soa/deorbit-systems/ ，访问日期 2026-09-27。文中指出部分帆方案依赖姿态控制；本项目 10 m² 有效迎风面积尚无姿态保持证明。

上述资料只约束估算的方向和数量级。`config/engineering_budget_candidate.csv` 的 `basis` 列标明原方案范围、原方案功率示例、`baseline_case` 或团队分配；未查到具体器件和实际任务资料的项目保持 `candidate/unknown`。本轮没有替换候选大气表，也没有把主办方未提供的完整规则文件标为已取得。
