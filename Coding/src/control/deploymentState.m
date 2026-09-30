function d=deploymentState(t,start,c)
%DEPLOYMENTSTATE 实际进度和观测分离；反馈丢失不改变实际面积。
d=struct('fraction',0,'observation',"stowed",'active',false, ...
    'nextBoundary',inf,'complete',false,'confirmed',false,'timeout',false);
if ~isfinite(start), return; end
elapsed=max(0,t-start);
d.active=elapsed<c.deploymentDelay_s-1e-7;
d.complete=~d.active;
progress=min(1,elapsed/c.deploymentDelay_s);
if c.deploymentAreaRamp, d.fraction=c.deploymentActualFraction*progress;
elseif d.complete, d.fraction=c.deploymentActualFraction;
end
d.observation="unknown";
d.confirmed=c.deploymentFeedback && elapsed>=c.deploymentDelay_s+c.confirmationDelay_s-1e-7;
d.timeout=~d.confirmed && elapsed>=c.deploymentTimeout_s-1e-7;
if d.confirmed
    if c.deploymentActualFraction==1, d.observation="deployed";
    elseif c.deploymentActualFraction==0, d.observation="failed";
    else, d.observation="partial";
    end
end
edges=start+[c.deploymentDelay_s,c.deploymentTimeout_s];
if c.deploymentFeedback, edges(end+1)=start+c.deploymentDelay_s+c.confirmationDelay_s; end
edges=edges(edges>t+1e-7);
if ~isempty(edges), d.nextBoundary=min(edges); end
end
