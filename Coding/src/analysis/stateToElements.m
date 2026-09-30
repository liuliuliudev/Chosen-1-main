function elements = stateToElements(x, p)
%STATETOELEMENTS 保留分析层接口，轨道几何计算由公共动力学模块提供。
elements = osculatingOrbit(x,p);
end
