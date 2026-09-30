function testSafeEntry()
root = fileparts(fileparts(mfilename('fullpath')));
for target = {fullfile(root,'results'),fullfile(root,'results','..','config')}
    try
        runProjectExperiments(target{1});
        error('Test:ExpectedFailure','Existing/outside output accepted.');
    catch err
        assert(strcmp(err.identifier,'RunAll:UnsafeOutput'));
    end
end
end
