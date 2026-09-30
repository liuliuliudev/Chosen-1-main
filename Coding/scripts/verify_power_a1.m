function audit=verify_power_a1(outRoot)
%VERIFY_POWER_A1 从逐片段记录独立核对电量收支、功率和统一硬件。
out=fullfile(outRoot,'tables'); saved=load(fullfile(out,'power_a1_results.mat'),'results');
rows=cell(numel(saved.results),1);
for k=1:numel(saved.results)
    r=saved.results{k}; q=r.power.assumptions; h=r.power.history;
    before=[q.initialFraction*q.capacity_Wh;h.batteryEnd_Wh(1:end-1)];
    dt=(h.end_s-h.start_s)/3600;
    net=h.generation_W-h.load_W;
    charged=min(max(net,0),q.chargeLimit_W).*dt*q.chargeEfficiency;
    requested=min(max(-net,0),q.dischargeLimit_W).*dt;
    delivered=min(requested,max(0,before-q.minimumFraction*q.capacity_Wh)*q.dischargeEfficiency);
    expected=min(q.capacity_Wh,before+charged-delivered/q.dischargeEfficiency);
    error_Wh=max(abs(expected-h.batteryEnd_Wh));
    missing=max(-net,0).*dt-delivered;
    missingError_Wh=max(abs(missing-h.unmet_Wh));
    bounded=all(h.batteryEnd_Wh>=q.minimumFraction*q.capacity_Wh-1e-7 & h.batteryEnd_Wh<=q.capacity_Wh+1e-7);
    fuelConsistent=abs(r.metrics.propUsed_kg-r.thrustOn_s*r.config.parameters.thruster.thrust_N/ ...
        (r.config.parameters.thruster.Isp_s*r.config.parameters.earth.g0))<1e-6;
    pass=error_Wh<1e-7 && missingError_Wh<1e-7 && bounded && fuelConsistent;
    rows{k}=table(string(r.config.case.id),error_Wh,missingError_Wh,bounded,fuelConsistent,pass, ...
        'VariableNames',{'caseId','energyError_Wh','unmetError_Wh','batteryBounded','fuelConsistent','pass'});
end
audit=vertcat(rows{:}); writetable(audit,fullfile(out,'energy_audit.csv'));
assert(all(audit.pass),'A1:EnergyAudit','Energy accounting or bounds failed.');
end
