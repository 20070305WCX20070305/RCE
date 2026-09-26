function [dt, dTmax_prev] = adaptStep(dTmax, dt, dt_target, beta, dt_min, dt_max, dT_max_prev)
    % input
    % dTmax         本步各层最大温度变化
    % dt            当前步长
    % dt_target     单步目标最大变化 
    % beta          幂律欠松弛指数
    % dt_min        步长下限
    % dt_max        步长上限
    % dT_max_prev   上一步的 dTmax

    % output
    % dt            下一步建议步长
    % dTmax_prev    更新后的历史值

    dT_max_safe = max(dTmax, 1e-12);
    r = (dt_target / dT_max_safe) .^ beta;
    r = clip(r, 0.5, 2.0);

    if isfinite(dT_max_prev) && dT_max_prev > 0 && dTmax > 1.5 * dT_max_prev
        r = 0.5 * r;
    end

    dt = clip(dt * r, dt_min, dt_max);
    dTmax_prev = dTmax;
end