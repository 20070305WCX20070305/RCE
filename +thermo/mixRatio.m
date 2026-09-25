function [r, rs, vmr] = mixRatio(p, es, RH, epsilon)
    % input 
    % pressure--p--1*N
    % vappor pressure--es--1*N
    % relative humidity--RH--scalar or 1*N
    % mass Ratio--epsilon--scalar

    % output
    % Saturation Vapor Pressure--rs--1*N
    % vapor pressure--r--1*N
    % volume mixing ratio--vmr--1*N

    rs = epsilon * es ./ (p - es);
    r = RH .* (epsilon * es) ./ (p - RH .* es);
    vmr = r ./ epsilon;
end