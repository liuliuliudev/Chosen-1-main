function audit=verify_uncertainty_u1(root)
out=fullfile(root,'tables'); s=load(fullfile(out,'uncertainty_results.mat'),'results'); rows=cell(numel(s.results),1);
for k=1:numel(s.results)
    r=s.results{k}; q=r.power.assumptions; h=r.power.history;
    before=[q.initialFraction*q.capacity_Wh;h.batteryEnd_Wh(1:end-1)];
    hours=(h.end_s-h.start_s)/3600; net=h.generation_W-h.load_W;
    charge=min(max(net,0),q.chargeLimit_W).*hours*q.chargeEfficiency;
    discharge=min(min(max(-net,0),q.dischargeLimit_W).*hours, ...
        max(0,before-q.minimumFraction*q.capacity_Wh)*q.dischargeEfficiency);
    expected=min(q.capacity_Wh,before+charge-discharge/q.dischargeEfficiency);
    energyError_Wh=max(abs(expected-h.batteryEnd_Wh));
    unmetError_Wh=max(abs(max(-net,0).*hours-discharge-h.unmet_Wh));
    bounded=all(h.batteryEnd_Wh>=q.minimumFraction*q.capacity_Wh-1e-7 & h.batteryEnd_Wh<=q.capacity_Wh+1e-7);
    fuelError_kg=abs(r.metrics.propUsed_kg-r.thrustOn_s*r.config.parameters.thruster.thrust_N/ ...
        (r.config.parameters.thruster.Isp_s*r.config.parameters.earth.g0));
    e=r.eventLog; started=sum(strcmp({e.type},'deployment_started'));
    confirmed=sum(strcmp({e.type},'deployment_confirmed'));
    pass=energyError_Wh<1e-7 && unmetError_Wh<1e-7 && bounded && fuelError_kg<1e-6 && started<=1 && confirmed<=started;
    rows{k}=table(string(r.config.case.id),energyError_Wh,unmetError_Wh,bounded,fuelError_kg,started,confirmed,pass, ...
        'VariableNames',{'caseId','energyError_Wh','unmetError_Wh','bounded','fuelError_kg','deployCommands','confirmations','pass'});
end
audit=vertcat(rows{:}); writetable(audit,fullfile(out,'uncertainty_audit.csv'));
disp(audit); assert(all(audit.pass),'U1:Audit','Accounting checks failed.');
end
