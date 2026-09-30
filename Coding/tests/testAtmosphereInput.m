function testAtmosphereInput()
%TESTATMOSPHEREINPUT Check valid input and reject malformed physical data.
tab = loadAtmosphereTable();
d = validateAtmosphereTable(tab,120e3,550e3);
assert(d.rows == size(tab,1) && d.upper_m >= 550e3);
audit = run_input_audit(tempname);
assert(height(audit) == 9 && all(~audit.verified));
assert(all(ismember(audit.status,["candidate","unverified"])));
root = fileparts(fileparts(mfilename('fullpath')));
registry = readtable(fullfile(root,'config','parameter_sources.csv'), ...
    'TextType','string');
registry.status(1) = "verified";
registry.value(1) = 1;
registry.sourceType(1) = "external_table";
registry.sourceLocation(1) = "data/processed/exponential_atmosphere_candidate.csv";
registry.locator(1) = "page 1";
registryFile = [tempname '.csv'];
writetable(registry,registryFile);
try
    run_input_audit(tempname,registryFile);
    error('Test:ExpectedFailure','Missing raw atmosphere source was accepted.');
catch exception
    assert(strcmp(exception.identifier,'InputAudit:MissingEvidence'));
end
bad = tab;
bad(3,1) = bad(2,1);
assertInvalid(bad);
bad = tab;
bad(4,2) = -1;
assertInvalid(bad);
bad = tab;
bad(5,2) = 2*bad(4,2);
assertInvalid(bad);
end

function assertInvalid(tab)
try
    validateAtmosphereTable(tab,120e3,550e3);
    error('Test:ExpectedFailure','Invalid atmosphere table was accepted.');
catch exception
    assert(strcmp(exception.identifier,'Atmosphere:InvalidTable') || ...
        strcmp(exception.identifier,'Atmosphere:Discontinuity'));
end
end
