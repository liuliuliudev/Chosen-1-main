function audit = run_input_audit(outDir)
%RUN_INPUT_AUDIT Report provenance without treating candidate data as verified.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outDir)
    outDir = fullfile(root,'results','tables');
end
sources = readtable(fullfile(root,'config','parameter_sources.csv'), ...
    'TextType','string');
required = ["parameter","value","unit","sourceType","sourceLocation", ...
    "locator","conditions","status"];
if ~isequal(string(sources.Properties.VariableNames),required) || ...
        numel(unique(sources.parameter)) ~= height(sources) || ...
        any(~ismember(sources.status,["verified","candidate","unverified"])) || ...
        any(~isfinite(sources.value(sources.status ~= "unverified")))
    error('InputAudit:InvalidRegistry','Parameter source registry is invalid.');
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
if ~isfolder(outDir), mkdir(outDir); end
writetable(audit,fullfile(outDir,'input_audit.csv'));
end
