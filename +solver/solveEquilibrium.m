function st = solveEquilibrium(par)
%{
par
├── phys       % = C.phys      （普适常数）
├── planet     % = C.planet    （行星量：独立量 + 派生量）
├── derived    % = C.derived   （Te, Fabs, p0, beta）
├── grid       % = blk.grid
├── radiation  % = blk.radiation
├── convection % = blk.convection
└── numerics   % = blk.numerics    
%}

    % 标定气压坐标
    st = struct();
    [p_lev, p_center] = grid.PressureGrid(blk.grid.ps, blk.grid.ptop, blk.grid.N, blk.grid.strech);
    st.p_lev = p_lev;
    st.p_center = p_center;
    
    % 初始化温度以及湿度
    Ts = par.derived.Te;
    T = par.derived.Te * ones(par.grid.N);
    [es, des_dT] = thermo.satVaporPressure(T, par.planet.e0, par.planet.T0, par.planet.L, par.planet.Rv);
    [r, rs, vmr] = thermo.mixRatio(p_center, par.planet.es, par.planet.RH, par.planet.epsilon);
    
    % 逐带吸收体q
    function q = build_q(r, q_aborber, nb)
        N  = numel(r);
        r  = reshape(r, 1, N);              
        if isempty(q_aborber)
            bg = zeros(nb, 1);
        elseif isscalar(q_aborber)
            bg = q_aborber * ones(nb, 1);
        else
            bg = reshape(q_aborber, nb, 1);
        end
        w = ones(nb, 1);                    
        q = w * r + bg * ones(1, N);       
    end
    q = build_q(r, par.radiation.q_aborber, par.radiation.nb);

    % 初始光学量
    tau=radiation.opticalDepth(p_lev, par.planet.kappa, q, par.planet.g);
    B = radiation.planckBand(T, par.phys.sigma, par.radiation.fband');

    % 数值控制参数
    dt = par.numerics.dt0;
    dTmaxPrev = Inf;
    iter = 0;

end