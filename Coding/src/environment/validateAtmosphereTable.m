function diagnostics = validateAtmosphereTable(tab, lowerAltitude_m, upperAltitude_m)
%VALIDATEATMOSPHERETABLE Check table coverage and piecewise-model behavior.
if ~isnumeric(tab) || size(tab,2) ~= 3 || size(tab,1) < 2 || ...
        any(~isfinite(tab),'all') || any(diff(tab(:,1)) <= 0) || ...
        any(tab(:,2) <= 0) || any(tab(:,3) <= 0) || ...
        tab(1,1) > lowerAltitude_m || tab(end,1) < upperAltitude_m
    error('Atmosphere:InvalidTable','Atmosphere table is invalid or lacks coverage.');
end
predictedNext = tab(1:end-1,2).*exp(-diff(tab(:,1))./tab(1:end-1,3));
jumpRatio = tab(2:end,2)./predictedNext;
if any(diff(tab(:,2)) >= 0) || any(jumpRatio > 1.25 | jumpRatio < 0.8)
    error('Atmosphere:Discontinuity','Density trend or segment boundary is inconsistent.');
end
diagnostics = struct('rows',size(tab,1),'lower_m',tab(1,1), ...
    'upper_m',tab(end,1),'maxBoundaryRatio',max(max(jumpRatio,1./jumpRatio)));
end
