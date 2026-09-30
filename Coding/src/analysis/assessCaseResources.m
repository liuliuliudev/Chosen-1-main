function row = assessCaseResources(pCase, pBase, ledger, facts)
%ASSESSCASERESOURCES 对一个已传播案例做保守的资源一致性检查。
% facts 是与 result 结构解耦的简表：caseId、group、thrustOn_s、
% propUsed_kg、maxSailFraction、concurrentThrustSail。调用者从轨迹提取。
% 基准预算只描述 20 mN 和 10 m2。扫描改变这些设计点时，相关数值
% 退回 unknown，避免把 350 W 或 3 kg 静默移植到另一套硬件方案。
required = {'caseId','group','thrustOn_s','propUsed_kg', ...
    'maxSailFraction','concurrentThrustSail'};
if ~isstruct(facts) || ~all(isfield(facts,required)) || ...
        ~isscalar(facts.thrustOn_s) || ~isfinite(facts.thrustOn_s) || ...
        facts.thrustOn_s < 0 || ~isscalar(facts.propUsed_kg) || ...
        ~isfinite(facts.propUsed_kg) || facts.propUsed_kg < 0 || ...
        ~isscalar(facts.maxSailFraction) || ...
        ~isfinite(facts.maxSailFraction) || ...
        facts.maxSailFraction < 0 || facts.maxSailFraction > 1 || ...
        ~isscalar(facts.concurrentThrustSail)
    error('CaseResources:InvalidFacts','Case resource facts are incomplete or invalid.');
end
caseLedger = ledger;
reasons = strings(0,1);
thrustChanged = abs(pCase.thruster.thrust_N-pBase.thruster.thrust_N) > 1e-12;
sailChanged = abs(pCase.sail.addedArea_m2-pBase.sail.addedArea_m2) > 1e-9;
if thrustChanged
    selected = ismember(caseLedger.itemId,["thruster_input","propulsion_dry"]);
    caseLedger.value(selected) = NaN;
    caseLedger.status(selected) = "unknown";
    reasons(end+1) = "thrust_workpoint_unmapped";
end
if sailChanged
    selected = caseLedger.itemId == "sail_mechanism";
    caseLedger.value(selected) = NaN;
    caseLedger.status(selected) = "unknown";
    reasons(end+1) = "sail_mass_unmapped";
end

operations = table(string(facts.caseId),facts.thrustOn_s,facts.propUsed_kg, ...
    'VariableNames',{'caseId','thrustOn_s','propUsed_kg'});
report = computeEngineeringBudget(pCase,caseLedger,operations);
status = report.status;
thrustModeMargin_W = report.power.margin_W(report.power.mode == "S1");
if logical(facts.concurrentThrustSail)
    % 原账本分别列推进与帆模式，没有覆盖两者同时工作的真实峰值。
    thrustModeMargin_W = NaN;
    reasons(end+1) = "combined_power_mode_unassessed";
    if status == "pass", status = "unverified"; end
end
if status == "unverified"
    reasons(end+1) = "candidate_or_unknown_inputs";
elseif status == "fail"
    reasons(end+1) = "resource_limit_failed";
end
reasonCodes = strjoin(unique(reasons,'stable'),';');
caseId = string(facts.caseId);
group = string(facts.group);
thrust_mN = pCase.thruster.thrust_N*1e3;
hardwareAddedArea_m2 = pCase.sail.addedArea_m2;
maxUsedAddedArea_m2 = hardwareAddedArea_m2*facts.maxSailFraction;
thrustOn_h = facts.thrustOn_s/3600;
propUsed_kg = facts.propUsed_kg;
inputPower_W = report.thruster.inputPower_W;
candidateInputEnergy_Wh = report.operations.candidateInputEnergy_Wh;
massMargin_kg = report.mass.margin_kg;
concurrentThrustSail = logical(facts.concurrentThrustSail);
if facts.thrustOn_s == 0
    % 没有点火的案例不展示未使用推进器的输入功率和推进模式余量。
    inputPower_W = NaN;
    thrustModeMargin_W = NaN;
end
row = table(caseId,group,thrust_mN,hardwareAddedArea_m2, ...
    maxUsedAddedArea_m2,thrustOn_h,propUsed_kg,inputPower_W, ...
    candidateInputEnergy_Wh,massMargin_kg,thrustModeMargin_W, ...
    concurrentThrustSail,status,reasonCodes);
end
