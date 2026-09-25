function [F_up, F_down] = twoStream(tau, B, Ts, emis, sigma, beta)
    % input 
    % 逐层逐带光学厚度--tau--nb*N 
    % 每层每带黑体发射--B--nb*N 
    % 地表温度--Ts--scalar 
    % 地表发射率--emis--scalar 
    % 斯特藩-玻尔兹曼常数--sigma--scalar 
    % 扩散因子--beta--scalar

    % output 
    % 各层界向上长波通量（带已求和）--F_up--1*(N+1) 
    % 各层界向下长波通量（带已求和）--F_down--1*(N+1)
    
    T = exp(- beta.*tau);
    S = (1 - T).*B;
    [nb, N] = size(B);

    grey_energy = emis * sigma * Ts^4 / nb;
    F_upo = [zeros(nb, N), grey_energy .*ones(nb, 1)];
    for k = N:-1:1
        F_upo(:,k) = T(:,k) .* F_upo(:, k+1) + S(:,k);
    end
    F_up = sum(F_upo);

    F_down_t = [zeros(nb, N+1)];
    for k = 1:N
        F_down_t(:,k+1) = T(:,k).*F_down_t(:,k) + S(:,k);
    end
    F_down = sum(F_down_t);
end