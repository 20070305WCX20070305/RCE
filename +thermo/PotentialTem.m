function theta = PotentialTem(T, p, kappa, p_0)
    % ==========input==========
    % T: temperature, 1*N
    % p: pressure, 1*N
    % kappa: Poisson constant
    % p_0: pressure constant, 1e5 for example

    %==========output===========
    % theta: vector of potential temperature, 1*N
    theta = T.*(p_0./p).^kappa;
end