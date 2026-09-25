function equ_theta = equPotentialTem(theta, r, T, L, cp)
    % input 
    % potential temperature--theta--1*N 
    % mixing ratio--r--1*N temperature--T--1*N 
    % heat of vaporization--L--scalar 
    % constant-pressure heat capacity--cp--scalar

    % output 
    % equal potential temperature--equ_theta--1*N 
    
    equ_theta = theta.*exp(L.*r./(cp.*T));
end