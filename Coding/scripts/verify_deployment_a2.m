function audit=verify_deployment_a2(root)
out=fullfile(root,'tables'); s=load(fullfile(out,'deployment_results.mat'),'results');
rows=cell(numel(s.results),1);
for k=1:numel(s.results)
    r=s.results{k}; c=r.config.case; q=r.power.assumptions; h=r.power.history;
    previous=[q.initialFraction*q.capacity_Wh;h.batteryEnd_Wh(1:end-1)];
    dt=(h.end_s-h.start_s)/3600; net=h.generation_W-h.load_W;
    charge=min(max(net,0),q.chargeLimit_W).*dt*q.chargeEfficiency;
    delivered=min(min(max(-net,0),q.dischargeLimit_W).*dt, ...
        max(0,previous-q.minimumFraction*q.capacity_Wh)*q.dischargeEfficiency);
    expected=min(q.capacity_Wh,previous+charge-delivered/q.dischargeEfficiency);
    energyError_Wh=max(abs(expected-h.batteryEnd_Wh));
    pass=energyError_Wh<1e-7 && all(h.batteryEnd_Wh>=q.minimumFraction*q.capacity_Wh-1e-7);
    start=NaN; confirmation=NaN; timeout=NaN; motorEnergy_Wh=0;
    if c.deploymentModel
        e=r.eventLog; starts=find(strcmp({e.type},'deployment_started'));
        pass=pass && numel(starts)==1;
        if numel(starts)==1
            start=e(starts).time_s;
            motor=h.start_s>=start-1e-6 & h.start_s<start+c.deploymentDelay_s-1e-6;
            motorEnergy_Wh=sum((h.end_s(motor)-h.start_s(motor))*30/3600);
            pass=pass && all(h.load_W(motor)==240) && all(~h.thrustOn(motor));
            pass=pass && abs(motorEnergy_Wh-30*c.deploymentDelay_s/3600)<1e-6;
            confirm=find(strcmp({e.type},'deployment_confirmed'));
            timed=find(strcmp({e.type},'deployment_timeout'));
            if c.deploymentFeedback
                pass=pass && numel(confirm)==1;
                if ~isempty(confirm), confirmation=e(confirm(1)).time_s; end
                pass=pass && abs(confirmation-start-c.deploymentDelay_s-c.confirmationDelay_s)<1e-5;
            else
                pass=pass && isempty(confirm) && numel(timed)==1 && all(~h.thrustOn(h.start_s>=start));
                if ~isempty(timed), timeout=e(timed(1)).time_s; end
                pass=pass && abs(timeout-start-c.deploymentTimeout_s)<1e-5;
            end
            actual=arrayfun(@(t) deploymentState(t,start,c).fraction,r.time_s);
            pass=pass && max(abs(actual-r.sailFraction))<1e-7;
        end
    end
    rows{k}=table(string(c.id),start,confirmation,timeout,motorEnergy_Wh,energyError_Wh,pass, ...
        'VariableNames',{'caseId','start_s','confirmation_s','timeout_s','motorEnergy_Wh','energyError_Wh','pass'});
end
audit=vertcat(rows{:}); writetable(audit,fullfile(out,'deployment_audit.csv'));
disp(audit); assert(all(audit.pass),'Deployment:Audit','Deployment evidence checks failed.');
end
