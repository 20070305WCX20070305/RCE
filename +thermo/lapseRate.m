function [gamma_d, gamma_w] = lapseRate(T,p,es,epsilon,g,cp,Rs,Rv,L)
    % inuput 
    % temperature--T--1*N 
    % pressure--p--1*N 
    % vappor pressure--es--1*N 

    % ratio of mass--epsilon--scalar 
    % gravity constant --g--scalar 
    % constant-pressure heat capacity--cp--scalar 
    % ratio between ideal gas constant and r-mass--Rs,Rv--scalar 
    % heat of vaporization--L--scalar 

    % output 
    % dry lapse rate--gamma_d--scalar 
    % wet lapse rate--gamma_w--1*N

    gamma_d = g / cp;
    rs = epsilon.*es ./ (p - es);
    gamma_w = g/cp .*((1+L.*rs ./ (Rs.*T)) ./ (1+(L^2.*rs) ./ (cp*Rv.* T.^2)));
end