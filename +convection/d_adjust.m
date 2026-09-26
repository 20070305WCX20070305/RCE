function T_ad = d_adjust(T_center, p_center, p_level, r, es, epsilon, L, cp, Rs,...
    kappa, gamma_c, p0, g, critical_point)

    % input
    %   待调整的层中心温度          T_center      [1×N]
    %   层中心气压，自顶向下递增     p_center      [1×N]
    %   层边界气压，自顶向下递增     p_level       [1×(N+1)]
    %   实际混合比                  r             [1×N]
    %   饱和蒸气压                  es            [1×N]
    %   水汽与干空气分子量比         epsilon       scalar
    %   相变潜热                    L             scalar
    %   定压比热                    cp            scalar
    %   背景大气比气体常数           Rs            scalar
    %   kappa = Rs/cp              kappa         scalar
    %   临界直减率                  gamma_c       scalar
    %   位温参考气压                p0            scalar
    %   表面重力                    g             scalar
    %   判据容差                    critical_point scalar

    % output
    %   调整后的层中心温度           T_ad          [1×N]

    function T_new = renew(start, stop, Tc, pc, wgh, p_zero, ka)
        T_cut = Tc(start:stop);
        p_cut = pc(start:stop);
        wgh_cut = wgh(start:stop);

        theta_zero = (T_cut * wgh_cut') / ((p_cut./p0).^ka * wgh_cut');
        T_new = theta_zero .* ((p_cut./p_zero).^ka);
    end

    function segs = search(a)
        n = numel(a);
        segs = zeros(n,2);
        k = 0;
        start_idx = 1;

        for i = 1:n
            if i == n || a(i+1) ~= a(i) + 1
                k = k + 1;
                segs(k, 1) = a(start_idx);
                segs(k, 2) = a(i);
                start_idx = i + 1;
            end
        end
        segs = segs(1:k, :);
    end

    weight = (p_level(2:end) - p_level(1:end-1))./g;
    theta = thermo.PotentialTem(T_center, p_center, kappa, p0);
    delta_theta = theta(2:end) - theta(1:end - 1);
    tar_index = find(delta_theta > critical_point);
    
    if isempty(tar_index)
        T_ad = T_center;
    else
        segs = search(tar_index);
        [rows,~] = size(segs);
        for k = 1:rows
            start = segs(k, 1);
            stop = segs(k,2);
            T_new = renew(start, stop + 1, T_center, p_center, weight, p0, kappa);
            T_center(start:stop + 1) = T_new;
        end
        T_ad = T_center;
    end      
end