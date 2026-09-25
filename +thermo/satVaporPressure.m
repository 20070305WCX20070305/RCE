function [es des_dT] = satVaporPressure(T, e0, T0, L, Rv)
    % input 
    % Temperature--T--1*N
    % vapor pressure constant--e0--scalar 
    % Temperature constant--T0--scalar 
    % heat of vaporization--L--scalar 
    % ratio between ideal gas constant and M--Rv--scalar

    % output 
    % Saturation vapor pressure--es--1*N
    % Derivative of Saturation vapor pressure--des_dT--1*N
    es = e0 * exp((L.*(1/T0-1./T))./Rv);
    des_dT = L.*es./(Rv* T.^2);
end