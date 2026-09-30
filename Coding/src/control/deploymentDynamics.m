function dx=deploymentDynamics(t,x,mode,p,start,c)
%DEPLOYMENTDYNAMICS 连续实际展开面积只进入动力学，不进入控制反馈。
d=deploymentState(t,start,c); mode.sailFraction=d.fraction;
dx=orbitalDynamics(t,x,mode,p);
end
