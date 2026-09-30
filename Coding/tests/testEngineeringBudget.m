function testEngineeringBudget()
%TESTENGINEERINGBUDGET 检查预算的缺失、超额、条件和结果适配边界。
p = baseline_case();
ledger = loadEngineeringBudget();
candidate = computeEngineeringBudget(p,ledger);
% 候选质量和向阳功率已填，但器件与姿态条件未认证，不能输出总体通过。
assert(candidate.status == "unverified");
assert(candidate.mass.knownMass_kg == 48);
assert(candidate.mass.totalMass_kg == 48 && candidate.mass.margin_kg == 2);
assert(all(candidate.power.available_W == 650));
assert(candidate.power.margin_W(candidate.power.mode == "S1") == 90);
assert(height(candidate.operations) == 0);
expectedJet_W = 0.5*p.thruster.thrust_N*p.thruster.Isp_s*p.earth.g0;
assert(abs(candidate.thruster.idealJetPower_W-expectedJet_W) < 1e-9);
assert(candidate.thruster.status == "unverified");

% 用人工完整账本核对计算边界；这些数值只存在于测试内，不作物理输入。
complete = ledger;
unknown = isnan(complete.value);
complete.value(unknown & complete.kind == "mass") = 1;
complete.value(unknown & complete.kind == "power_available") = 1000;
complete.value(unknown & complete.kind == "power_load") = 10;
complete.value(unknown & complete.kind == "condition") = 1;
complete.status(:) = "confirmed";
operation = table("P",3600,0.1,'VariableNames', ...
    {'caseId','thrustOn_s','propUsed_kg'});
ok = computeEngineeringBudget(p,complete,operation);
assert(ok.status == "pass" && all(ok.power.status == "pass"));
assert(abs(ok.operations.candidateInputEnergy_Wh-350) < 1e-9);
assert(ok.operations.thrustOn_h == 1 && ok.operations.propUsed_kg == 0.1);

% 已知质量超出 50 kg，或已知负载超过可用功率，不能被缺项掩盖。
partialHeavy = ledger;
partialHeavy.value(partialHeavy.itemId == "other_mass") = NaN;
partialHeavy.status(partialHeavy.itemId == "other_mass") = "unknown";
partialHeavy.value(partialHeavy.itemId == "platform_structure") = 51;
partialHeavy.status(partialHeavy.itemId == "platform_structure") = "candidate";
assert(computeEngineeringBudget(p,partialHeavy).mass.status == "fail");
heavy = complete;
heavy.value(heavy.itemId == "platform_structure") = 51;
assert(computeEngineeringBudget(p,heavy).mass.status == "fail");
partialPower = ledger;
partialPower.value(partialPower.itemId == "health_monitor") = NaN;
partialPower.status(partialPower.itemId == "health_monitor") = "unknown";
partialPower.value(partialPower.mode == "S1" & ...
    partialPower.kind == "power_available") = 100;
partialPower.status(partialPower.mode == "S1" & ...
    partialPower.kind == "power_available") = "candidate";
partialReport = computeEngineeringBudget(p,partialPower);
assert(partialReport.power.status(partialReport.power.mode == "S1") == "fail");
weakPower = complete;
weakPower.value(weakPower.mode == "S1" & ...
    weakPower.kind == "power_available") = 100;
powerReport = computeEngineeringBudget(p,weakPower);
assert(powerReport.power.status(powerReport.power.mode == "S1") == "fail");

% 帆姿态条件明确失败时，总体不能报告通过。
badAttitude = complete;
badAttitude.value(badAttitude.itemId == "sail_attitude_maintained") = 0;
assert(computeEngineeringBudget(p,badAttitude).status == "fail");

% 账本推进剂必须与轨道初始质量中的推进剂一致，避免重复计入。
badFuel = ledger;
badFuel.value(badFuel.itemId == "propellant") = 1.6;
try
    computeEngineeringBudget(p,badFuel);
    error('Test:MissingError','Mismatched propellant should be rejected.');
catch err
    assert(strcmp(err.identifier,'EngineeringBudget:InvalidInput'));
end
end
