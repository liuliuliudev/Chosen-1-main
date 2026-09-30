function resultRoot=run_current(varargin)
%RUN_CURRENT 当前A1/A2主线统一入口，历史全实验仍由run_all提供。
addpath(fullfile(fileparts(mfilename('fullpath')),'Coding'));
startup();
resultRoot=runCurrentExperiments(varargin{:});
end
