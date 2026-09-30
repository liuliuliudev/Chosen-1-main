function makeOrbitVideo(result,filename,frameCount)
%MAKEORBITVIDEO 将已计算的高度历程制作成动画，到仿真结束时停止。
% 默认 750 帧、每秒 10 帧，播放约 75 秒；横轴始终是仿真时间。
if nargin < 2
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    filename = fullfile(root,'results','videos', ...
        [result.config.case.id '_altitude.mp4']);
end
folder = fileparts(filename);
if ~isfolder(folder), mkdir(folder); end
fps = 10;
if nargin < 3, frameCount = 750; end
% 在已有轨迹采样点中均匀选帧，不重新积分轨道。
sample = unique(round(linspace(1,numel(result.time_s),frameCount)));
t = result.time_s/86400;
h = (vecnorm(result.state_SI(:,1:3),2,2)- ...
    result.config.parameters.earth.RE)/1e3;
fig = figure('Visible','off','Color','w');
set(fig,'Position',[100 100 960 540]);
set(gca,'Color','w','XColor','k','YColor','k');
plot(t,h,'Color',[0.8 0.8 0.8]); hold on
trace = plot(t(1),h(1),'b-','LineWidth',1.5);
dot = plot(t(1),h(1),'ro','MarkerFaceColor','r');
yline(result.config.parameters.mission.reentryAltitude_m/1e3,':');
xlabel('Simulation time (day)'); ylabel('Altitude (km)'); grid on
title(result.config.case.id,'Color','k');
writer = VideoWriter(filename,'MPEG-4'); writer.FrameRate = fps;
open(writer);
% 灰线是完整轨迹，蓝线和红点逐帧显示当前进度。
for k = sample
    set(trace,'XData',t(1:k),'YData',h(1:k));
    set(dot,'XData',t(k),'YData',h(k));
    drawnow;
    writeVideo(writer,getframe(fig));
end
close(writer); close(fig);
end
