function con = constant_cauculation(cft, name)

%{
C
|—— state            % 状态码，0表示正常，1表示异常，读取为 1 时主程序应当立刻停止。
├── phys      
│   ├── c            % 真空光速
│   ├── h            % 普朗克常数
│   ├── kB           % 玻尔兹曼常数
│   ├── NA           % 阿伏伽德罗常数
│   ├── R            % 普适气体常数 = kB*NA
│   ├── sigma        % Stefan–Boltzmann 常数
│   ├── G            % 引力常数
│   └── pi           % 圆周率（可选，供绘图/几何公式）
├── planet   
│   ├── name, Mp, Rp, g, M, Mv, condensable, cp, L, S0, alpha, emis, e0, T0, RH, CD, V
│   ├── Rs           % = R/M
│   ├── Rv           % = R/Mv
│   ├── epsilon      % = Mv/M = Rs/Rv
│   ├── cv           % = cp - Rs
│   ├── kappa        % = Rs/cp
│   └── Gamma_d      % = g/cp
└── derived   
    ├── Te           % 有效温度
    ├── Fabs         % TOA 吸收恒星辐射 = (1-alpha)*S0/4
    ├── p0           % 位温参考气压（数值约定）
    ├── beta         % 扩散因子（数值约定） 
%}

    con = struct('state', 0);

    name = lower(name);
    if ~ismember(name, {'earth', 'mars', 'venus', 'titan'})
        fprintf('name error: invalid planet name: %s\n', name);
        con.state = 1;
        return
    end

% 物理学常数部分
    con.phys = struct(...
        'c',        299792458,...
        'h',        6.62607015e-34,...
        'kB',       1.380649e-23,...
        'NA',       6.02214076e23,...
        'G',        6.67430e-11,...
        'pi',       pi);
    con.phys.R = con.phys.kB * con.phys.NA;
    con.phys.sigma = 2 * pi ^5*con.phys.kB^4 / (15 * con.phys.h^3*con.phys.c^2);

    % 导出量部分 con.planet

    con.planet = cft.(name).physical;
    con.planet.g = con.phys.G * con.planet.Mp / con.planet.Rp^2;
    con.planet.Rv = con.phys.R / con.planet.Mv;
    con.planet.Rs = con.phys.R / con.planet.M;
    con.planet.epsilon = con.planet.Mv / con.planet.M;
    con.planet.cv = con.planet.cp - con.planet.Rs;
    con.planet.kappa = con.planet.Rs / con.planet.cp;
    con.planet.Gamma_d = con.planet.g / con.planet.cp;


    % con.derived 字段
    con.derived.Te = ((1 - con.planet.alpha) * con.planet.S0 / (4 * con.phys.sigma))^(1/4);
    con.derived.Fabs = (1 - con.planet.alpha)* con.planet.S0 / 4;
    con.derived.p0 = cft.(name).numerics.p0;
    con.derived.beta = cft.(name).numerics.beta;
end


