function [r, rs, vmr] = mixRatio(p, es, RH, epsilon)
    % input 
    % pressure--p--N*1 
    % vappor pressure--es--N*1 
    % relative humidity--RH--scalar or N*1 
    % mass Ratio--epsilon--scalar

    % output
    % Saturation Vapor Pressure--rs--N*1
    % vapor pressure--r--N*1
    % volume mixing ratio--vmr--N*1

    rs = epsilon * es ./ (p - es);
    r = RH .* (epsilon * es) ./ (p - RH .* es);
    vmr = r ./ epsilon;
end