function index=buildCurrentEvidence(root)
%BUILDCURRENTEVIDENCE 只索引当前目录；缺文件或审计失败不得通过。
files=["a1/tables/power_a1_summary.csv";"a1/tables/power_a1_resources.csv"; ...
    "a1/tables/power_a1_results.mat";"a1/tables/energy_audit.csv"; ...
    "a1/tables/resolution_check.csv";"a1/figures/battery_history.png"; ...
    "a1/figures/thrust_history.png";"a2/tables/deployment_summary.csv"; ...
    "a2/tables/deployment_resources.csv";"a2/tables/deployment_results.mat"; ...
    "a2/tables/deployment_audit.csv";"a2/tables/resolution_check.csv"; ...
    "a2/figures/area_and_feedback.png"; ...
    "u1/tables/uncertainty_summary.csv";"u1/tables/uncertainty_resources.csv"; ...
    "u1/tables/uncertainty_results.mat";"u1/tables/uncertainty_audit.csv"; ...
    "u1/tables/resolution_check.csv";"u1/figures/uncertainty_comparison.png";"u1/validation.txt"; ...
    "u2/tables/uncertainty_summary.csv";"u2/tables/uncertainty_resources.csv"; ...
    "u2/tables/uncertainty_results.mat";"u2/tables/uncertainty_audit.csv"; ...
    "u2/tables/resolution_check.csv";"u2/tables/combined_events.csv"; ...
    "u2/tables/combined_power.csv";"u2/tables/combined_refined.mat";"u2/validation.txt"];
a1=experiment_matrix('power_a1'); a2=experiment_matrix('deployment_a2');
for k=1:numel(a1)
    files(end+1,1)="a1/tables/"+string(a1(k).id)+"_power.csv";
end
for k=1:numel(a2)
    files(end+1,1)="a2/tables/"+string(a2(k).id)+".mat";
    files(end+1,1)="a2/tables/"+string(a2(k).id)+"_events.csv";
end
files(end+1,1)="a1/validation.txt";
u1=experiment_matrix('uncertainty_u1');
for k=1:numel(u1)
    files(end+1,1)="u1/tables/"+string(u1(k).id)+".mat";
    files(end+1,1)="u1/tables/"+string(u1(k).id)+"_events.csv";
end
logs=dir(fullfile(root,'a2','validation*.txt'));
if isempty(logs)
    files(end+1,1)="a2/validation_missing.txt";
else
    for k=1:numel(logs), files(end+1,1)="a2/"+string(logs(k).name); end
end
exists=false(size(files)); bytes=zeros(size(files));
for k=1:numel(files)
    path=fullfile(root,files(k)); exists(k)=isfile(path);
    if exists(k), info=dir(path); bytes(k)=info.bytes; end
end
index=table(files,exists,bytes); writetable(index,fullfile(root,'current_evidence.csv'));
assert(all(exists),'CurrentEvidence:Missing','Required current artifacts are missing.');
checks=files(contains(files,'audit.csv') | contains(files,'resolution_check.csv'));
for k=1:numel(checks)
    check=readtable(fullfile(root,checks(k)));
    assert(height(check)>0 && all(check.pass==1),'CurrentEvidence:Failed','Audit or resolution check failed.');
end
groups={'a1','a2','u1','u2'}; expected=[8 10 5 1];
summaries={'power_a1_summary.csv','deployment_summary.csv','uncertainty_summary.csv','uncertainty_summary.csv'};
for k=1:numel(groups)
    summary=readtable(fullfile(root,groups{k},'tables',summaries{k}));
    assert(height(summary)==expected(k) && numel(unique(string(summary.caseId)))==expected(k), ...
        'CurrentEvidence:Cases','Current case count or identities incomplete.');
end
project=fileparts(fileparts(mfilename('fullpath')));
cases={experiment_matrix('power_a1'),experiment_matrix('deployment_a2'),experiment_matrix('uncertainty_u1'),experiment_matrix('uncertainty_u2')};
for g=1:numel(groups)
    summary=readtable(fullfile(root,groups{g},'tables',summaries{g}),'TextType','string');
    assert(isequal(summary.caseId,string({cases{g}.id}).'), ...
        'CurrentEvidence:Cases','Case identities differ from experiment definition.');
end
sourceFiles=[dir(fullfile(project,'src','**','*.m'));dir(fullfile(project,'config','*.m')); ...
    dir(fullfile(project,'config','*.csv'));dir(fullfile(project,'scripts','*.m')); ...
    dir(fullfile(project,'tests','*.m'));dir(fullfile(project,'*.m'))];
source=struct('path',{},'text',{});
for k=1:numel(sourceFiles)
    path=fullfile(sourceFiles(k).folder,sourceFiles(k).name);
    source(k).path=path(numel(project)+2:end);
    source(k).text=fileread(path);
end
save(fullfile(root,'source_snapshot.mat'),'source');
evidenceOrigin="single_run";
if isfile(fullfile(root,'assembly_manifest.json')), evidenceOrigin="assembled_validated_runs"; end
generatedAt=string(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
matlabVersion=string(version); physicalStatus="candidate_unverified";
crossMachineStatus="not_verified"; indexStatus="complete_with_candidates";
writetable(table(generatedAt,matlabVersion,indexStatus,physicalStatus,crossMachineStatus,evidenceOrigin), ...
    fullfile(root,'current_context.csv'));
end
