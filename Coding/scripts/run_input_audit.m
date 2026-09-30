function audit = run_input_audit(outDir, registryFile)
%RUN_INPUT_AUDIT Report provenance without treating candidate data as verified.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outDir)
    outDir = fullfile(root,'results','tables');
end
if nargin < 2 || isempty(registryFile)
    registryFile = fullfile(root,'config','parameter_sources.csv');
end
sources = readtable(registryFile, ...
    'TextType','string');
required = ["parameter","value","unit","sourceType","sourceLocation", ...
    "locator","conditions","status"];
if ~isequal(string(sources.Properties.VariableNames),required) || ...
        numel(unique(sources.parameter)) ~= height(sources) || ...
        any(~ismember(sources.status,["verified","candidate","unverified"])) || ...
        any(~isfinite(sources.value(sources.status ~= "unverified")))
    error('InputAudit:InvalidRegistry','Parameter source registry is invalid.');
end
verifiedRows = find(sources.status == "verified");
for k = verifiedRows.'
    location = strtrim(sources.sourceLocation(k));
    locator = strtrim(sources.locator(k));
    if ismissing(location) || ismissing(locator) || location == "" || ...
            locator == "" || ...
            ismember(sources.sourceType(k),["unknown","team_assumption","team_definition"])
        error('InputAudit:MissingEvidence', ...
            'Verified input needs an identifiable external source: %s',sources.parameter(k));
    end
    if ~startsWith(location,["https://","http://"]) && ...
            ~isfile(fullfile(root,strrep(location,'/',filesep)))
        error('InputAudit:MissingEvidence', ...
            'Verified source file is absent: %s',sources.parameter(k));
    end
    if sources.parameter(k) == "atmosphere_table" && ...
            (~startsWith(location,"data/raw/") || ...
            ~isfile(fullfile(root,strrep(location,'/',filesep))))
        error('InputAudit:MissingEvidence', ...
            'Verified atmosphere input needs a local raw source file.');
    end
end
tab = loadAtmosphereTable();
diagnostics = validateAtmosphereTable(tab,120e3,550e3);
p = baseline_case();
names = ["initial_mass","initial_altitude","inclination","thrust", ...
    "specific_impulse","effective_sail_area","reentry_interface", ...
    "window_lower_boundary"];
values = [p.sc.initialMass_kg,p.sc.initialAltitude_m,p.sc.inclination_rad, ...
    p.thruster.thrust_N,p.thruster.Isp_s,p.sail.addedArea_m2, ...
    p.mission.reentryAltitude_m,p.mission.windowLowerAltitude_m];
for k = 1:numel(names)
    row = find(sources.parameter == names(k));
    if numel(row) ~= 1 || abs(sources.value(row)-values(k)) > ...
            1e-10*max(1,abs(values(k)))
        error('InputAudit:ConfigMismatch', ...
            'Source registry disagrees with baseline configuration: %s',names(k));
    end
end
verified = sources.status == "verified";
audit = sources(:,{'parameter','value','unit','sourceType','sourceLocation', ...
    'locator','conditions','status'});
audit.verified = verified;
audit.note = repmat("",height(audit),1);
atmosphereRow = audit.parameter == "atmosphere_table";
audit.note(atmosphereRow) = "Candidate table: " + diagnostics.rows + ...
    " rows; original source and conversion unverified";
if any(atmosphereRow) && sources.sourceType(atmosphereRow) == "official_numeric_match"
    rawPath = fullfile(root,sources.sourceLocation(atmosphereRow));
    raw = readmatrix(rawPath,'FileType','text');
    converted = raw;
    converted(:,[1 3]) = converted(:,[1 3])*1000;
    [found,rows] = ismember(tab(:,1),converted(:,1));
    if ~all(found) || any(abs(tab-converted(rows,:)) > ...
            1e-12*max(abs(tab),realmin),'all')
        error('InputAudit:SourceMismatch','Candidate table does not match archived official data.');
    end
    audit.note(atmosphereRow) = "14 rows numerically matched; unit-comment and altitude/model applicability unresolved";
end
if ~isfolder(outDir), mkdir(outDir); end
writetable(audit,fullfile(outDir,'input_audit.csv'));
end
