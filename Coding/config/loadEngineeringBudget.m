function ledger = loadEngineeringBudget(filename)
%LOADENGINEERINGBUDGET 读取独立的工程预算候选表，不修改轨道模型参数。
% 表内 value 的 NaN 表示尚无可信数值；status 用于区分候选、未知和已核对。
% 读取与计算分开，便于后续替换预算表而不改预算算法或传播器。
if nargin < 1 || isempty(filename)
    root = fileparts(mfilename('fullpath'));
    filename = fullfile(root,'engineering_budget_candidate.csv');
end
ledger = readtable(filename,'TextType','string');
ledger.itemId = string(ledger.itemId);
ledger.kind = string(ledger.kind);
ledger.mode = string(ledger.mode);
ledger.unit = string(ledger.unit);
ledger.status = string(ledger.status);
end
