function w = windowExitMetrics(events, startApogee_m, endApogee_m, lower_m, endTime_s)
%WINDOWEXITMETRICS 根据带方向的事件求已计算轨迹内最后一次退出。
w = struct('time_s',NaN,'observed',false,'status','not_observed', ...
    'returnCount',0,'observationEnd_s',endTime_s);
tol_m = 1e-3;
if abs(startApogee_m-lower_m) <= tol_m || abs(endApogee_m-lower_m) <= tol_m
    w.status = 'ambiguous_boundary';
    return
end
candidate_s = NaN;
if startApogee_m < lower_m
    candidate_s = 0;
end
if ~isempty(events)
    types = {events.type};
    selected = events(strcmp(types,'window_down') | strcmp(types,'window_up'));
    [~,order] = sort([selected.time_s]);
    selected = selected(order);
    for k = 1:numel(selected)
        if strcmp(selected(k).type,'window_down')
            candidate_s = selected(k).time_s;
        else
            candidate_s = NaN;
            w.returnCount = w.returnCount+1;
        end
    end
end
belowAtEnd = endApogee_m < lower_m;
if belowAtEnd && isfinite(candidate_s)
    w.time_s = candidate_s;
    w.observed = true;
    if candidate_s == 0
        w.status = 'initially_below';
    else
        w.status = 'observed';
    end
elseif belowAtEnd || isfinite(candidate_s)
    % 终态与穿越记录矛盾时保留缺失值，交给数值检查排查。
    w.status = 'inconsistent';
end
end
