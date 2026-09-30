function summary = analyzeSwitchNeighborhood(result)
%ANALYZESWITCHNEIGHBORHOOD 检查展帆前后一圈的密切轨道尺度。
p = result.config.parameters;
events = result.eventLog;
idx = find(strcmp({events.type},'switch'),1);
if isempty(idx)
    error('SwitchDiagnostic:MissingEvent','Case has no switch event.');
end
switchTime_s = events(idx).time_s;
t = result.time_s;
[~,switchIndex] = min(abs(t-switchTime_s));
switchOrbit = osculatingOrbit(result.state_SI(switchIndex,:).',p);
period_s = 2*pi*sqrt(switchOrbit.a_m^3/p.earth.mu);
altitude = zeros(numel(t),3);
for k = 1:numel(t)
    orbit = osculatingOrbit(result.state_SI(k,:).',p);
    altitude(k,:) = [orbit.a_m-p.earth.RE, ...
        orbit.perigeeAltitude_m,orbit.apogeeAltitude_m]/1e3;
end
phase = ["before";"after"];
aMin_km = NaN(2,1); aMax_km = NaN(2,1); aMean_km = NaN(2,1);
perigeeMin_km = NaN(2,1); apogeeMax_km = NaN(2,1);
timeAboveSwitchFraction = NaN(2,1);
for k = 1:2
    if k == 1
        selected = t >= switchTime_s-period_s & t <= switchTime_s;
    else
        selected = t >= switchTime_s & t <= switchTime_s+period_s;
    end
    tt = t(selected);
    aa = altitude(selected,:);
    if numel(tt) < 2
        error('SwitchDiagnostic:InsufficientSamples', ...
            'Need at least two saved states on each side of the switch.');
    end
    aMin_km(k) = min(aa(:,1));
    aMax_km(k) = max(aa(:,1));
    aMean_km(k) = trapz(tt,aa(:,1))/(tt(end)-tt(1));
    perigeeMin_km(k) = min(aa(:,2));
    apogeeMax_km(k) = max(aa(:,3));
    timeAboveSwitchFraction(k) = trapz(tt, ...
        double(aa(:,1) > p.mission.switchAltitude_m/1e3))/(tt(end)-tt(1));
end
summary = table(phase,aMin_km,aMax_km,aMean_km,perigeeMin_km, ...
    apogeeMax_km,timeAboveSwitchFraction);
end
