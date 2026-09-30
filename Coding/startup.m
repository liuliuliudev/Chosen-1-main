function root = startup()
%STARTUP 将本工程的代码目录加入 MATLAB 搜索路径。
root = fileparts(mfilename('fullpath'));
addpath(root);
% 显式列出所需目录，避免把结果和原始数据目录也加入路径。
folders = {'config','src/dynamics','src/environment','src/control', ...
    'src/propagation','src/analysis','src/visualization','scripts','tests'};
for k = 1:numel(folders)
    addpath(fullfile(root, folders{k}));
end
end
