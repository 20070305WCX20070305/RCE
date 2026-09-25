function tau = opticalDepth(p_lev, kappa, q, g)
    % input 
    % level pressure--p_lev--1*(N+1) 
    % 质量吸收系数--kappa--(nb)*1 
    % 吸收体质量混合比--q--(nb)*N 
    % 重力加速度--g--scalar

    % output 
    % optical depth--tau--(nb)*N
    p1 = p_lev(1:end-1);
    p2 = p_lev(2:end);
    deltap = p2 - p1;

    [deltap2, kappa2] = ndgrid(kappa, deltap);
    tau = kappa2.*q.*deltap2 ./ g;
end 