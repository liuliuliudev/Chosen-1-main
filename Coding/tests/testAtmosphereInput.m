function testAtmosphereInput()
%TESTATMOSPHEREINPUT Check valid input and reject malformed physical data.
tab = loadAtmosphereTable();
d = validateAtmosphereTable(tab,120e3,550e3);
assert(d.rows == size(tab,1) && d.upper_m >= 550e3);
audit = run_input_audit(tempname);
assert(height(audit) == 9 && all(~audit.verified));
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
