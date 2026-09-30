function report = computeEngineeringBudget(p, ledger, operations)
%COMPUTEENGINEERINGBUDGET 对静态工程资源做只读审计。
% 输入 p 仅提供当前卫星总质量、推进剂、推力、比冲和重力常数。
% ledger 是与动力学分离的预算表；operations 是可选的案例汇总表，列为
% caseId、thrustOn_s、propUsed_kg。调用者负责把传播结果转换为这三列。
% 输出中的 pass 仅表示给定数据通过算术检查，不代表器件或飞行认证。
if nargin < 3 || isempty(operations)
    operations = table(strings(0,1),zeros(0,1),zeros(0,1), ...
        'VariableNames',{'caseId','thrustOn_s','propUsed_kg'});
end
validateLedger(ledger,p);
validateOperations(operations);

mass = ledger(ledger.kind == "mass",:);
knownMass_kg = sum(mass.value(isfinite(mass.value)));
completeMass = all(isfinite(mass.value));
totalMass_kg = NaN;
margin_kg = NaN;
if completeMass
    totalMass_kg = knownMass_kg;
    margin_kg = p.sc.initialMass_kg-totalMass_kg;
end
% 即使仍有缺项，已知质量超过总质量也足以判定失败。
massStatus = checkLimit(p.sc.initialMass_kg,knownMass_kg, ...
    completeMass,all(mass.status == "confirmed"));
report.mass = table(p.sc.initialMass_kg,knownMass_kg,totalMass_kg, ...
    margin_kg,massStatus,'VariableNames', ...
    {'initialMass_kg','knownMass_kg','totalMass_kg','margin_kg','status'});

available = ledger(ledger.kind == "power_available",:);
loads = ledger(ledger.kind == "power_load",:);
nModes = height(available);
mode = available.mode;
available_W = available.value;
knownLoad_W = zeros(nModes,1);
peakLoad_W = NaN(nModes,1);
powerMargin_W = NaN(nModes,1);
powerStatus = strings(nModes,1);
for k = 1:nModes
    % all 表示每个模式共用的负载；具体模式负载由数据表扩展。
    active = loads.mode == "all" | loads.mode == mode(k);
    selected = loads(active,:);
    knownLoad_W(k) = sum(selected.value(isfinite(selected.value)));
    complete = isfinite(available_W(k)) && all(isfinite(selected.value));
    if complete
        peakLoad_W(k) = knownLoad_W(k);
        powerMargin_W(k) = available_W(k)-peakLoad_W(k);
    end
    evidenceConfirmed = available.status(k) == "confirmed" && ...
        all(selected.status == "confirmed");
    powerStatus(k) = checkLimit(available_W(k),knownLoad_W(k), ...
        complete,evidenceConfirmed);
end
report.power = table(mode,available_W,knownLoad_W,peakLoad_W, ...
    powerMargin_W,powerStatus,'VariableNames', ...
    {'mode','available_W','knownLoad_W','peakLoad_W','margin_W','status'});

thrusterInput = loads(loads.itemId == "thruster_input",:);
inputPower_W = thrusterInput.value;
idealJetPower_W = 0.5*p.thruster.thrust_N*p.thruster.Isp_s*p.earth.g0;
jetToInputRatio = NaN;
if isfinite(inputPower_W) && inputPower_W > 0
    jetToInputRatio = idealJetPower_W/inputPower_W;
end
workpoint = ledger(ledger.itemId == "same_thruster_workpoint",:);
thrusterStatus = "unverified";
if isfinite(inputPower_W) && idealJetPower_W > inputPower_W + 1e-9
    thrusterStatus = "fail";
elseif isfinite(inputPower_W) && thrusterInput.status == "confirmed" && ...
        workpoint.status == "confirmed" && workpoint.value == 1
    thrusterStatus = "pass";
elseif workpoint.status == "confirmed" && workpoint.value == 0
    thrusterStatus = "fail";
end
report.thruster = table(p.thruster.thrust_N,p.thruster.Isp_s, ...
    idealJetPower_W,inputPower_W,jetToInputRatio,thrusterStatus, ...
    'VariableNames',{'thrust_N','Isp_s','idealJetPower_W', ...
    'inputPower_W','jetToInputRatio','status'});

conditions = ledger(ledger.kind == "condition",:);
conditionStatus = repmat("unverified",height(conditions),1);
conditionStatus(conditions.status == "confirmed" & conditions.value == 1) = "pass";
conditionStatus(conditions.status == "confirmed" & conditions.value == 0) = "fail";
report.conditions = table(conditions.itemId,conditions.value, ...
    conditions.status,conditionStatus,'VariableNames', ...
    {'itemId','value','inputStatus','status'});
report.effectiveAddedArea_m2 = p.sail.addedArea_m2;

caseId = string(operations.caseId);
thrustOn_h = operations.thrustOn_s/3600;
propUsed_kg = operations.propUsed_kg;
candidateInputEnergy_Wh = inputPower_W*thrustOn_h;
report.operations = table(caseId,thrustOn_h,propUsed_kg, ...
    candidateInputEnergy_Wh);

allStatus = [massStatus;powerStatus;thrusterStatus;conditionStatus];
report.status = "pass";
if any(allStatus == "fail")
    report.status = "fail";
elseif any(allStatus == "unverified")
    report.status = "unverified";
end
end

function status = checkLimit(limit,known,complete,evidenceConfirmed)
% 缺项不能制造虚假的正余量，但已知部分超额可以直接失败。
if isfinite(limit) && known > limit + 1e-9
    status = "fail";
elseif ~complete || ~evidenceConfirmed
    status = "unverified";
else
    status = "pass";
end
end

function validateLedger(ledger,p)
required = {'itemId','kind','mode','value','unit','status'};
if ~istable(ledger) || ~all(ismember(required,ledger.Properties.VariableNames))
    error('EngineeringBudget:InvalidInput','Budget table is missing required columns.');
end
kind = string(ledger.kind);
mode = string(ledger.mode);
status = string(ledger.status);
id = string(ledger.itemId);
unit = string(ledger.unit);
if any(ismissing(id)) || any(id == "") || ...
        numel(unique(id)) ~= height(ledger) || ...
        ~all(ismember(kind,["mass","power_available","power_load","condition"])) || ...
        ~all(ismember(status,["unknown","candidate","confirmed"])) || ...
        ~isnumeric(ledger.value) || any(isinf(ledger.value)) || ...
        any(ledger.value(isfinite(ledger.value)) < 0) || ...
        any((status == "unknown") ~= isnan(ledger.value))
    error('EngineeringBudget:InvalidInput','Budget rows have invalid IDs, values or statuses.');
end
if any(unit(kind == "mass") ~= "kg") || ...
        any(unit(kind == "power_available" | kind == "power_load") ~= "W") || ...
        any(unit(kind == "condition") ~= "bool") || ...
        any(mode(kind == "mass" | kind == "condition") ~= "all") || ...
        any(~ismember(ledger.value(kind == "condition" & isfinite(ledger.value)),[0 1]))
    error('EngineeringBudget:InvalidInput','Budget unit, mode or condition value is invalid.');
end
availableMode = mode(kind == "power_available");
if isempty(availableMode) || any(availableMode == "all") || ...
        numel(unique(availableMode)) ~= numel(availableMode) || ...
        any(~ismember(mode(kind == "power_load"),["all";availableMode]))
    error('EngineeringBudget:InvalidInput','Power modes must have one availability row each.');
end
propellant = ledger(id == "propellant" & kind == "mass",:);
if height(propellant) ~= 1 || ~isfinite(propellant.value) || ...
        abs(propellant.value-p.sc.propellant_kg) > 1e-9 || ...
        sum(id == "thruster_input" & kind == "power_load") ~= 1 || ...
        sum(id == "same_thruster_workpoint" & kind == "condition") ~= 1
    error('EngineeringBudget:InvalidInput', ...
        'Propellant, thruster input or workpoint condition is inconsistent.');
end
end

function validateOperations(operations)
required = {'caseId','thrustOn_s','propUsed_kg'};
if ~istable(operations) || ~all(ismember(required,operations.Properties.VariableNames)) || ...
        any(ismissing(string(operations.caseId))) || ...
        any(~isfinite(operations.thrustOn_s)) || ...
        any(~isfinite(operations.propUsed_kg)) || ...
        any(operations.thrustOn_s < 0) || any(operations.propUsed_kg < 0)
    error('EngineeringBudget:InvalidInput','Operation summary is invalid.');
end
end
