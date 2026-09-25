function [es des_dT] = satVaporPressure(T, e0, T0, L, Rv)
    % input 
    % Temperature--T--N*1 
    % vapor pressure constant--e0--scalar 
    % Temperature constant--T0--scalar 
    % heat of vaporization--L--scalar 
    % ratio between ideal gas constant and M--Rv--scalar

    % output 
    % Saturation vapor pressure--es--N*1 
    % Derivative of Saturation vapor pressure--des_dT--N*1
    es = e0 * exp((L.*(1/T0-1./T)));
    des_dT = L.*es./(Rv* T.^2);
end