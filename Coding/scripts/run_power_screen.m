function summary = run_power_screen(p,outDir)
%RUN_POWER_SCREEN 先作能量上下限，再作逐步电池收支，不自动宣称硬件可行。
q = powerScenario(p);
solar_W = [650;500];
rows = cell(2,1);
for k = 1:2
    q.solarEol_W = solar_W(k);
    energy = q.initialFraction*q.capacity_Wh;
    minEnergy = energy; unmet = 0; on_s = 0; t = 0;
    while t < 10*q.period_s-1e-6
        [available,generation,boundary] = powerAvailability(t,energy,q);
        [duty,nextDuty] = dutySchedule(t,p);
        on = duty && available >= q.thrustLoad_W;
        dt = min([q.step_s,boundary-t,nextDuty-t,10*q.period_s-t]);
        if dt < 1e-7, dt = 1e-7; end
        load = q.coastLoad_W;
        if on, load = q.thrustLoad_W; end
        [energy,missing] = advanceBattery(energy,generation,load,dt,q);
        minEnergy = min(minEnergy,energy); unmet = unmet+missing;
        on_s = on_s+on*dt; t = t+dt;
    end
    idealMeanGeneration_W = solar_W(k)*(1-q.eclipseFraction);
    requestedMeanLoad_W = q.coastLoad_W + ...
        (q.thrustLoad_W-q.coastLoad_W)*p.thruster.dutyFraction;
    eclipseBaseEnergy_Wh = q.coastLoad_W*q.eclipseFraction*q.period_s/3600/q.dischargeEfficiency;
    rows{k} = table(solar_W(k),q.eclipseFraction,idealMeanGeneration_W, ...
        requestedMeanLoad_W,eclipseBaseEnergy_Wh,minEnergy,unmet,on_s/t, ...
        "team_assumption",'VariableNames',{'solarEol_W','eclipseFraction', ...
        'idealMeanGeneration_W','requestedMeanLoad_W','eclipseBaseBattery_Wh', ...
        'minimumBattery_Wh','unmetBaseEnergy_Wh','actualDutyFraction','status'});
end
summary = vertcat(rows{:});
writetable(summary,fullfile(outDir,'power_screen.csv'));
save(fullfile(outDir,'power_assumptions.mat'),'q');
end
