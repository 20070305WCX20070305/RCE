function heating_rate = heatingRate(F_up, F_down, p_level, g, cp)
    % input 
    % 层界向上长波通量--Fup--[N+1×1]
    % 层界向下长波通量--Fdn--[N+1×1]
    % 边界气压--p_lev--[N+1×1]
    % 重力加速度--g--scalar
    % 定压比热--cp--scalar

    % output 
    % 各层辐射加热率--dTdt--[N×1]

    delta_p = p_level(2:end) - p_level(1:end-1);
    delta_F_net = F_up(2:end) - F_up(1:end-1) - F_down(2:end) + F_down(1:end-1);
    heating_rate = (g/cp).*(delta_F_net./delta_p);
end 