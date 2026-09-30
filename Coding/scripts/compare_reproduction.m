function comparison = compare_reproduction(referenceDir, resultDir)
%COMPARE_REPRODUCTION 跨机器指标核对；不比较电脑运行耗时。
groups = {'baselines','switch','density','sail','thrust','faults','supervised','hardware','power'};
rows = cell(0,1);
for g = 1:numel(groups)
    a = readtable(fullfile(referenceDir,[groups{g} '_summary.csv']),'TextType','string');
    b = readtable(fullfile(resultDir,[groups{g} '_summary.csv']),'TextType','string');
    assert(isequal(a.caseId,b.caseId),'Reproduction:CaseMismatch','Case IDs differ.');
    for k = 1:height(a)
        timeError_s = difference(a.t120_d(k),b.t120_d(k))*86400;
        windowError_s = difference(a.tWindowExit_d(k),b.tWindowExit_d(k))*86400;
        fuelError_kg = difference(a.propUsed_kg(k),b.propUsed_kg(k));
        pass = a.status(k)==b.status(k) && a.windowExitStatus(k)==b.windowExitStatus(k) && ...
            timeError_s <= max(60,0.01*abs(a.t120_d(k))*86400) && ...
            windowError_s <= 6000 && fuelError_kg <= max(1e-4,0.01*a.propUsed_kg(k));
        if isnan(a.t120_d(k)) && isnan(b.t120_d(k))
            pass = a.status(k)==b.status(k) && a.windowExitStatus(k)==b.windowExitStatus(k) && ...
                windowError_s<=6000 && fuelError_kg<=max(1e-4,0.01*a.propUsed_kg(k));
        end
        rows{end+1,1} = table(string(groups{g}),a.caseId(k),timeError_s, ...
            windowError_s,fuelError_kg,pass,'VariableNames', ...
            {'group','caseId','timeError_s','windowError_s','fuelError_kg','pass'});
    end
end
comparison = vertcat(rows{:});
if ~all(comparison.pass)
    disp(comparison(~comparison.pass,:));
    error('Reproduction:Mismatch','Some cases did not reproduce within declared tolerances.');
end
end

function d = difference(a,b)
if isnan(a) && isnan(b), d=0;
elseif isfinite(a) && isfinite(b), d=abs(a-b);
else, d=inf;
end
end
