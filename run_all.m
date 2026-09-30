function resultRoot = run_all(varargin)
%RUN_ALL Compatible entry; outputs always use a new directory.
addpath(fullfile(fileparts(mfilename('fullpath')),'Coding'));
resultRoot = runProjectExperiments(varargin{:});
end
