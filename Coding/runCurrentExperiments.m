function resultRoot=runCurrentExperiments(resultRoot)
%RUNCURRENTEXPERIMENTS 从新目录完成A1/A2、独立审计、分辨率复算和图。
project=fileparts(mfilename('fullpath'));
if nargin<1
    resultRoot=fullfile(project,'results',['current_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
end
resultRoot=char(java.io.File(char(resultRoot)).getCanonicalPath());
allowed=char(java.io.File(fullfile(project,'results')).getCanonicalPath());
if ~startsWith(lower(resultRoot),[lower(allowed) filesep]) || isfolder(resultRoot) || isfile(resultRoot)
    error('CurrentRun:UnsafeOutput','Choose a new directory under Coding/results.');
end
mkdir(resultRoot);
run_power_a1(fullfile(resultRoot,'a1'));
verify_power_a1(fullfile(resultRoot,'a1'));
check_power_a1_resolution(fullfile(resultRoot,'a1'));
plot_power_a1(fullfile(resultRoot,'a1'));
run_deployment_a2(fullfile(resultRoot,'a2'));
verify_deployment_a2(fullfile(resultRoot,'a2'));
check_deployment_a2_resolution(fullfile(resultRoot,'a2'));
plot_deployment_a2(fullfile(resultRoot,'a2'));
run_uncertainty_u1(fullfile(resultRoot,'u1'));
verify_uncertainty_u1(fullfile(resultRoot,'u1'));
check_uncertainty_u1_resolution(fullfile(resultRoot,'u1'));
plot_uncertainty_u1(fullfile(resultRoot,'u1'));
run_uncertainty_u2(fullfile(resultRoot,'u2'));
buildCurrentEvidence(resultRoot);
fprintf('Current experiment output: %s\n',resultRoot);
end
