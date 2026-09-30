function styleFigure(fig)
%STYLEFIGURE 统一浅色导出样式，避免桌面主题改变结果图可读性。
axesHandles = findall(fig,'Type','axes');
for k = 1:numel(axesHandles)
    ax = axesHandles(k);
    set(ax,'Color','w','XColor',[0.12 0.15 0.18], ...
        'YColor',[0.12 0.15 0.18],'GridColor',[0.65 0.7 0.73]);
end
texts = findall(fig,'Type','text');
set(texts,'Color',[0.12 0.15 0.18]);
legends = findall(fig,'Type','legend');
for k = 1:numel(legends)
    set(legends(k),'Color','w','TextColor',[0.12 0.15 0.18]);
end
end
