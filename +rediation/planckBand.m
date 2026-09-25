function B = planckBand(T, sigma, f_band)
    % input 
    % temperature--T--1*N 
    % radiation band--f_band--nb*1 
    % 斯特藩-玻尔兹曼常数--sigma--scalar

    % output 
    % 黑体半球通量--B--nb*N
    [T_processed, f_band_processed] = ndgrid(T, f_band);
    B = sigma.*(f_band_processed.*T_processed.^4);
end