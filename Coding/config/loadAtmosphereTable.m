function tab = loadAtmosphereTable(filename, lowerAltitude_m, upperAltitude_m)
%LOADATMOSPHERETABLE Read a three-column SI atmosphere table with headers.
if nargin < 1 || isempty(filename)
    root = fileparts(fileparts(mfilename('fullpath')));
    filename = fullfile(root,'data','processed', ...
        'exponential_atmosphere_candidate.csv');
end
if nargin < 2, lowerAltitude_m = 120e3; end
if nargin < 3, upperAltitude_m = 550e3; end
data = readtable(filename,'TextType','string');
expected = {'height_m','rho_kg_m3','scale_height_m'};
if ~isequal(data.Properties.VariableNames,expected)
    error('Atmosphere:Columns','Atmosphere columns must use the expected SI names.');
end
tab = table2array(data);
validateAtmosphereTable(tab,lowerAltitude_m,upperAltitude_m);
end
