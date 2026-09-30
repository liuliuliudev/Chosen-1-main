function testCaseResources()
%TESTCASERESOURCES 防止扫描案例误继承基准器件与帆机构预算。
p = baseline_case();
ledger = loadEngineeringBudget();
facts = struct('caseId',"P",'group',"baselines",'thrustOn_s',3600, ...
    'propUsed_kg',0.1,'maxSailFraction',1, ...
    'concurrentThrustSail',false);
normal = assessCaseResources(p,p,ledger,facts);
assert(normal.status == "unverified");
assert(normal.massMargin_kg == 2 && normal.thrustModeMargin_W == 90);
assert(normal.inputPower_W == 350);

% 推力扫描不能把 20 mN 对应的 350 W 自动当作 40 mN 的输入功率。
stronger = p;
stronger.thruster.thrust_N = 0.04;
changedThrust = assessCaseResources(stronger,p,ledger,facts);
assert(isnan(changedThrust.inputPower_W));
assert(isnan(changedThrust.candidateInputEnergy_Wh));
assert(isnan(changedThrust.massMargin_kg));
assert(contains(changedThrust.reasonCodes,"thrust_workpoint_unmapped"));

facts.thrustOn_s = 0;
noThrust = assessCaseResources(p,p,ledger,facts);
assert(isnan(noThrust.inputPower_W) && isnan(noThrust.thrustModeMargin_W));
assert(noThrust.candidateInputEnergy_Wh == 0);
facts.thrustOn_s = 3600;

% 帆面积变化后，10 m2 帆对应的机构质量不能继续用于总质量余量。
largerSail = p;
largerSail.sail.addedArea_m2 = 20;
changedSail = assessCaseResources(largerSail,p,ledger,facts);
assert(isnan(changedSail.massMargin_kg));
assert(changedSail.maxUsedAddedArea_m2 == 20);
assert(contains(changedSail.reasonCodes,"sail_mass_unmapped"));

% F2 的展帆后继续推进是组合工况，单独的 S1 余量不能代表它。
facts.concurrentThrustSail = true;
facts.maxSailFraction = 0.5;
combined = assessCaseResources(p,p,ledger,facts);
assert(isnan(combined.thrustModeMargin_W));
assert(combined.maxUsedAddedArea_m2 == 5);
assert(contains(combined.reasonCodes,"combined_power_mode_unassessed"));
assert(ledger.value(ledger.itemId == "thruster_input") == 350);
end
