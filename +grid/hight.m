function Grid_hight = hight(p_lev, T_lev, Rs, g)
    %input：
    %level pressure:p_lev N*1 
    % level temperature: T_lev N*1 
    % Rs:普适气体常数，叠加相对分子质量修正 
    % g重力加速度
    
    % output: 
    % hight: n-level center's hight N*1
    
    p_log = log(p_lev);
    p1 = p_log(1:end - 1);
    p2 = p_log(2:end);
    delta_log_p = p2 - p1;

    T1 = T_lev(2:end);
    T2 = T_lev(1:end - 1);
    T_ave = (T1 + T2) / 2;

    delta_z = Rs * T_ave .* delta_log_p / g;
    [~,n] = size(delta_z);
    A = tril(ones(n));
    Grid_hight = delta_z * A;
end
