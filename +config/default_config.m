% 此文件涉及的程序为 DeepSeek 所写

function cft = default_config(planetName, override)
%DEFAULT_CONFIG 一维辐射—对流平衡（RCE）模型的行星配置
% -------------------------------------------------------------------------
% 用法
%   cft = DEFAULT_CONFIG()              返回行星注册表（earth/venus/mars/titan）
%   blk = DEFAULT_CONFIG('mars')        返回单颗行星的配置块
%   blk = DEFAULT_CONFIG('mars', ov)    返回用 ov 递归局部覆盖后的配置块
%
% 每颗行星块 cft.<planet> 含五个子结构，全部采用国际单位制（SI）：
%   .physical    行星物理量    Pa  K  m  s  kg  J  W/m^2  m/s^2  kg/mol
%   .grid        垂直网格      Pa  K（层数、几何比无量纲）
%   .radiation   辐射方案      kappa 为 m^2/kg，其余无量纲
%   .convection  对流调整      Gamma_c 为 K/m
%   .numerics    数值控制      s  K  W/m^2
%
% 字段分类约定（详见《一维辐射对流模型_config模块详解.md》§1）
%   独立量   —— 可观测 / 可给定，直接存真实值（如 M, Mv, cp, S0, alpha）。
%   导出量   —— 可由独立量用定义式派生者，保留字段但赋 0 占位，由 +constants
%               每次启动统一重算并覆盖（g, Rs, Rv, epsilon, cv, kappa,
%               Gamma_d, Te, Fabs）。注意：0 不是物理真值；下游应从 +constants
%               返回的结构读取，而不要读本配置中的 0。
%   未标定量 —— radiation.kappa / q_aborber 的 0 表示"尚未标定"，需人工标定后
%               填写，与"可派生占位 0"语义不同。
%
% 其它说明
%   1) 本函数为纯函数：不依赖全局变量，返回独立副本（结构体值语义）。
%   2) 湿度闭合采用"微量可凝结组分 + 给定相对湿度"框架；行星的主温室气体
%      （如火星/金星 CO2）由 radiation 光学体现，不进入湿度闭合。火星、金星
%      在此框架下取痕量水为可凝结组分，以免饱和蒸气压超过总压。
%   3) 换行星只换输入块，换分辨率只改该块的 grid。
% -------------------------------------------------------------------------

    if nargin < 1 || isempty(planetName)
        % 无参：返回整张行星注册表
        cft = struct( ...
            'earth', earth_block(), ...
            'venus', venus_block(), ...
            'mars',  mars_block(), ...
            'titan', titan_block());
        names = fieldnames(cft);
        for k = 1:numel(names)
            cft.(names{k}) = validate_block(cft.(names{k}));
        end
        return;
    end

    if nargin < 2
        override = struct();
    end

    switch lower(planetName)
        case 'earth', blk = earth_block();
        case 'venus', blk = venus_block();
        case 'mars',  blk = mars_block();
        case 'titan', blk = titan_block();
        otherwise
            error('default_config:unknownPlanet', '未知行星：%s', planetName);
    end

    blk = merge_struct(blk, override);
    cft = validate_block(blk);
end

% =========================================================================
% 行星块构造函数（结构完全一致，仅数值不同）
% =========================================================================

function blk = earth_block()
% EARTH_BLOCK 地球配置块（SI）
    blk.physical = add_derived(struct( ...
        'name',        'earth',  ...   % -,      行星标识
        'Mp',          5.9722e24, ...  % kg,     行星质量
        'Rp',          6.371e6,  ...   % m,      行星半径
        'M',           0.028944, ...   % kg/mol, 干空气平均摩尔质量
        'Mv',          0.018015, ...   % kg/mol, 可凝结组分(H2O)摩尔质量
        'condensable', 'H2O',    ...   % -,      可凝结组分
        'cp',          1005,     ...   % J/(kg K), 定压比热
        'L',           2.501e6,  ...   % J/kg,   汽化潜热
        'S0',          1361,     ...   % W/m^2,  轨道处恒星辐照
        'alpha',       0.295,    ...   % -,      行星反照率
        'emis',        0.97,     ...   % -,      地表发射率
        'e0',          611.2,    ...   % Pa,     相平衡参考蒸气压(273.15 K)
        'T0',          273.15,   ...   % K,      相平衡参考温度
        'RH',          0.75,     ...   % -,      相对湿度
        'CD',          1.3e-3,   ...   % -,      拖拽系数
        'V',           5));            % m/s,    近地面风速

    blk.grid = struct( ...
        'ps',      1.01325e5, ...      % Pa,     表面气压
        'ptop',    0.5,       ...      % Pa,     大气顶气压
        'N',       40,        ...      % -,      层数
        'stretch', 1.2);               % -,      网格几何比

    blk.radiation = struct( ...
        'nb',        2,          ...   % -,      辐射带数
        'fband',     [0.8 0.2],  ...   % -,      各带发射权重(sum=1)
        'kappa',     0,          ...   % m^2/kg, 质量吸收系数(未标定)
        'q_aborber', 0,          ...   % kg/kg,  吸收体混合比来源(未标定)
        'pscale',    0.6,        ...   % -,      压力标度指数(暂未使用)
        'cloud',     []);              % -,      云参数(暂未使用)

    blk.convection = struct( ...
        'moist',          true,  ...   % -,      湿对流开关
        'Gamma_c',        6.5e-3,...   % K/m,    临界直减率
        'critical_point', 1e-3,  ...   % K,      不稳定判据阈值
        'rmin',           3e-6,  ...   % kg/kg,  混合比下限
        'maxIter',        5,     ...   % -,      干/湿交替迭代上限
        'tol_E',          1e-3);       % W/m^2,  湿分支能量泛函容差

    blk.numerics = struct( ...
        'dt0',       600,   ...        % s,      初始/重置时间步
        'dt_target', 0.3,   ...        % K,      单步目标最大温度变化
        'beta',      1.66,  ...        % -,      双流扩散因子(twoStream)
        'betaStep',  0.4,   ...        % -,      步长欠松弛指数(adaptStep)
        'dtmin',     60,    ...        % s,      步长下限
        'dtmax',     7200,  ...        % s,      步长上限
        'dT_tol',    1e-3,  ...        % K,      内层收敛阈值
        'F_tol',     1e-3,  ...        % W/m^2,  外层 TOA 闭合阈值
        'Ts_tol',    1e-3,  ...        % K,      外层 Ts 变化阈值
        'maxIter',   1e4,   ...        % -,      内层最大迭代
        'p0',        1e5);             % Pa,     位温参考气压
end

function blk = mars_block()
% MARS_BLOCK 火星配置块（SI）：背景大气约 95% CO2，可凝结组分取痕量 H2O
    blk.physical = add_derived(struct( ...
        'name',        'mars',   ...   % -,      行星标识
        'Mp',          6.4171e23,...   % kg,     行星质量
        'Rp',          3.3895e6, ...   % m,      行星半径
        'M',           0.04334,  ...   % kg/mol, 背景大气(CO2)平均摩尔质量
        'Mv',          0.018015, ...   % kg/mol, 可凝结组分(H2O)摩尔质量
        'condensable', 'H2O',    ...   % -,      可凝结组分(痕量水)
        'cp',          844,      ...   % J/(kg K), 定压比热
        'L',           2.501e6,  ...   % J/kg,   水汽化潜热
        'S0',          586,      ...   % W/m^2,  轨道处恒星辐照
        'alpha',       0.25,     ...   % -,      行星反照率
        'emis',        0.95,     ...   % -,      地表发射率
        'e0',          611.2,    ...   % Pa,     相平衡参考蒸气压
        'T0',          273.15,   ...   % K,      相平衡参考温度
        'RH',          0.10,     ...   % -,      相对湿度
        'CD',          1.3e-3,   ...   % -,      拖拽系数
        'V',           5));            % m/s,    近地面风速

    blk.grid = struct( ...
        'ps',      610,   ...          % Pa,     表面气压
        'ptop',    0.1,   ...          % Pa,     大气顶气压
        'N',       40,    ...          % -,      层数
        'stretch', 1.15);              % -,      网格几何比

    blk.radiation = struct( ...
        'nb',        2,          ...   % -,      辐射带数
        'fband',     [0.8 0.2],  ...   % -,      各带发射权重(sum=1)
        'kappa',     0,          ...   % m^2/kg, 质量吸收系数(未标定)
        'q_aborber', 0,          ...   % kg/kg,  吸收体混合比来源(未标定)
        'pscale',    0.6,        ...   % -,      压力标度指数(暂未使用)
        'cloud',     []);              % -,      云参数(暂未使用)

    blk.convection = struct( ...
        'moist',          true,  ...   % -,      湿对流开关
        'Gamma_c',        4.0e-3,...   % K/m,    临界直减率
        'critical_point', 1e-3,  ...   % K,      不稳定判据阈值
        'rmin',           3e-6,  ...   % kg/kg,  混合比下限
        'maxIter',        5,     ...   % -,      干/湿交替迭代上限
        'tol_E',          1e-3);       % W/m^2,  湿分支能量泛函容差

    blk.numerics = struct( ...
        'dt0',       600,   ...        % s,      初始/重置时间步
        'dt_target', 0.3,   ...        % K,      单步目标最大温度变化
        'beta',      1.66,  ...        % -,      双流扩散因子(twoStream)
        'betaStep',  0.4,   ...        % -,      步长欠松弛指数(adaptStep)
        'dtmin',     60,    ...        % s,      步长下限
        'dtmax',     7200,  ...        % s,      步长上限
        'dT_tol',    1e-3,  ...        % K,      内层收敛阈值
        'F_tol',     1e-3,  ...        % W/m^2,  外层 TOA 闭合阈值
        'Ts_tol',    1e-3,  ...        % K,      外层 Ts 变化阈值
        'maxIter',   1e4,   ...        % -,      内层最大迭代
        'p0',        610);             % Pa,     位温参考气压(取表面量级)
end

function blk = venus_block()
% VENUS_BLOCK 金星配置块（SI）：背景大气约 96.5% CO2，深厚温室；采用干对流
    blk.physical = add_derived(struct( ...
        'name',        'venus',  ...   % -,      行星标识
        'Mp',          4.8675e24,...   % kg,     行星质量
        'Rp',          6.0518e6, ...   % m,      行星半径
        'M',           0.04344,  ...   % kg/mol, 背景大气(CO2)平均摩尔质量
        'Mv',          0.018015, ...   % kg/mol, 可凝结组分(H2O，痕量)摩尔质量
        'condensable', 'H2O',    ...   % -,      可凝结组分(痕量水)
        'cp',          900,      ...   % J/(kg K), 定压比热
        'L',           2.501e6,  ...   % J/kg,   水汽化潜热
        'S0',          2604,     ...   % W/m^2,  轨道处恒星辐照
        'alpha',       0.76,     ...   % -,      行星反照率(Bond)
        'emis',        0.90,     ...   % -,      地表发射率
        'e0',          611.2,    ...   % Pa,     相平衡参考蒸气压
        'T0',          273.15,   ...   % K,      相平衡参考温度
        'RH',          0,        ...   % -,      相对湿度(干)
        'CD',          1.3e-3,   ...   % -,      拖拽系数
        'V',           1));            % m/s,    近地面风速

    blk.grid = struct( ...
        'ps',      9.2e6, ...          % Pa,     表面气压
        'ptop',    10,    ...          % Pa,     大气顶气压
        'N',       60,    ...          % -,      层数
        'stretch', 1.1);               % -,      网格几何比

    blk.radiation = struct( ...
        'nb',        2,          ...   % -,      辐射带数
        'fband',     [0.8 0.2],  ...   % -,      各带发射权重(sum=1)
        'kappa',     0,          ...   % m^2/kg, 质量吸收系数(未标定,需极大)
        'q_aborber', 0,          ...   % kg/kg,  吸收体混合比来源(未标定)
        'pscale',    0.6,        ...   % -,      压力标度指数(暂未使用)
        'cloud',     []);              % -,      云参数(暂未使用)

    blk.convection = struct( ...
        'moist',          false, ...   % -,      干对流
        'Gamma_c',        9.5e-3,...   % K/m,    临界直减率
        'critical_point', 1e-3,  ...   % K,      不稳定判据阈值
        'rmin',           0,     ...   % kg/kg,  干对流不用
        'maxIter',        5,     ...   % -,      干/湿交替迭代上限
        'tol_E',          1e-3);       % W/m^2,  能量泛函容差

    blk.numerics = struct( ...
        'dt0',       600,   ...        % s,      初始/重置时间步
        'dt_target', 0.3,   ...        % K,      单步目标最大温度变化
        'beta',      1.66,  ...        % -,      双流扩散因子(twoStream)
        'betaStep',  0.4,   ...        % -,      步长欠松弛指数(adaptStep)
        'dtmin',     60,    ...        % s,      步长下限
        'dtmax',     7200,  ...        % s,      步长上限
        'dT_tol',    1e-3,  ...        % K,      内层收敛阈值
        'F_tol',     1e-3,  ...        % W/m^2,  外层 TOA 闭合阈值
        'Ts_tol',    1e-3,  ...        % K,      外层 Ts 变化阈值
        'maxIter',   1e4,   ...        % -,      内层最大迭代
        'p0',        1e5);             % Pa,     位温参考气压
end

function blk = titan_block()
% TITAN_BLOCK 泰坦配置块（SI）：背景大气约 94% N2，可凝结组分 CH4
    blk.physical = add_derived(struct( ...
        'name',        'titan',  ...   % -,      行星标识
        'Mp',          1.3452e23,...   % kg,     行星质量
        'Rp',          2.5747e6, ...   % m,      行星半径
        'M',           0.02801,  ...   % kg/mol, 背景大气(N2)平均摩尔质量
        'Mv',          0.016043, ...   % kg/mol, 可凝结组分(CH4)摩尔质量
        'condensable', 'CH4',    ...   % -,      可凝结组分
        'cp',          1040,     ...   % J/(kg K), 定压比热
        'L',           5.1e5,    ...   % J/kg,   CH4 汽化潜热
        'S0',          14.82,    ...   % W/m^2,  轨道处恒星辐照
        'alpha',       0.29,     ...   % -,      行星反照率
        'emis',        0.90,     ...   % -,      地表发射率
        'e0',          1.169e4,  ...   % Pa,     CH4 三相点参考蒸气压(90.69 K)
        'T0',          90.69,    ...   % K,      CH4 三相点参考温度
        'RH',          0.50,     ...   % -,      相对湿度
        'CD',          1.3e-3,   ...   % -,      拖拽系数
        'V',           1));            % m/s,    近地面风速

    blk.grid = struct( ...
        'ps',      1.467e5, ...        % Pa,     表面气压
        'ptop',    0.5,     ...        % Pa,     大气顶气压
        'N',       40,      ...        % -,      层数
        'stretch', 1.2);               % -,      网格几何比

    blk.radiation = struct( ...
        'nb',        2,          ...   % -,      辐射带数
        'fband',     [0.8 0.2],  ...   % -,      各带发射权重(sum=1)
        'kappa',     0,          ...   % m^2/kg, 质量吸收系数(未标定)
        'q_aborber', 0,          ...   % kg/kg,  吸收体混合比来源(未标定)
        'pscale',    0.6,        ...   % -,      压力标度指数(暂未使用)
        'cloud',     []);              % -,      云参数(暂未使用)

    blk.convection = struct( ...
        'moist',          true,  ...   % -,      湿对流开关
        'Gamma_c',        0.9e-3,...   % K/m,    临界直减率
        'critical_point', 1e-3,  ...   % K,      不稳定判据阈值
        'rmin',           3e-6,  ...   % kg/kg,  混合比下限
        'maxIter',        5,     ...   % -,      干/湿交替迭代上限
        'tol_E',          1e-3);       % W/m^2,  湿分支能量泛函容差

    blk.numerics = struct( ...
        'dt0',       600,   ...        % s,      初始/重置时间步
        'dt_target', 0.3,   ...        % K,      单步目标最大温度变化
        'beta',      1.66,  ...        % -,      双流扩散因子(twoStream)
        'betaStep',  0.4,   ...        % -,      步长欠松弛指数(adaptStep)
        'dtmin',     60,    ...        % s,      步长下限
        'dtmax',     7200,  ...        % s,      步长上限
        'dT_tol',    1e-3,  ...        % K,      内层收敛阈值
        'F_tol',     1e-3,  ...        % W/m^2,  外层 TOA 闭合阈值
        'Ts_tol',    1e-3,  ...        % K,      外层 Ts 变化阈值
        'maxIter',   1e4,   ...        % -,      内层最大迭代
        'p0',        1e5);             % Pa,     位温参考气压
end

% =========================================================================
% 辅助函数（仅本文件可见）
% =========================================================================

function p = add_derived(p)
%ADD_DERIVED 为 physical 结构体补上"导出量占位 0"字段
%   这些量由 +constants 从独立量重算并覆盖；此处的 0 仅作占位，不是真值。
    p.g       = 0;   % m/s^2  = G*Mp/Rp^2
    p.Rs      = 0;   % J/(kg K) = R/M
    p.Rv      = 0;   % J/(kg K) = R/Mv
    p.epsilon = 0;   % -      = Mv/M = Rs/Rv
    p.cv      = 0;   % J/(kg K) = cp - Rs
    p.kappa   = 0;   % -      = Rs/cp
    p.Gamma_d = 0;   % K/m    = g/cp
    p.Te      = 0;   % K      = [(1-alpha)*S0/(4*sigma)]^(1/4)
    p.Fabs    = 0;   % W/m^2  = (1-alpha)*S0/4
end

function blk = merge_struct(blk, ov)
%MERGE_STRUCT 用 ov 递归局部覆盖 blk：同层同为结构体则递归，否则整体替换
    if isempty(ov)
        return;
    end
    f = fieldnames(ov);
    for k = 1:numel(f)
        name = f{k};
        if isfield(blk, name) && isstruct(blk.(name)) && isstruct(ov.(name))
            blk.(name) = merge_struct(blk.(name), ov.(name));
        else
            blk.(name) = ov.(name);
        end
    end
end

function blk = validate_block(blk)
%VALIDATE_BLOCK 基本物理量校验（单位：SI）
    assert(blk.grid.ps > blk.grid.ptop, ...
        'default_config: 需满足 ps > ptop');
    assert(blk.grid.N >= 2, ...
        'default_config: 层数 N 至少为 2');
    assert(blk.grid.stretch >= 1, ...
        'default_config: stretch 应不小于 1');
    assert(blk.physical.M > 0 && blk.physical.Mv > 0, ...
        'default_config: 摩尔质量必须为正');
    assert(blk.physical.cp > 0, ...
        'default_config: cp 必须为正');
    assert(blk.physical.e0 > 0 && blk.physical.T0 > 0 && blk.physical.L > 0, ...
        'default_config: 相平衡参数 e0/T0/L 必须为正');
    assert(blk.physical.S0 > 0, ...
        'default_config: 恒星辐照 S0 必须为正');
    assert(blk.physical.alpha >= 0 && blk.physical.alpha < 1, ...
        'default_config: 反照率 alpha 应在 [0,1)');
    assert(blk.physical.emis > 0 && blk.physical.emis <= 1, ...
        'default_config: 地表发射率 emis 应在 (0,1]');
    assert(all(blk.physical.RH(:) >= 0) && all(blk.physical.RH(:) <= 1), ...
        'default_config: 相对湿度 RH 应在 [0,1]');
    assert(blk.radiation.nb >= 1 && numel(blk.radiation.fband) == blk.radiation.nb, ...
        'default_config: fband 长度须等于 nb');
    assert(abs(sum(blk.radiation.fband) - 1) < 1e-9, ...
        'default_config: fband 之和须为 1');
    assert(blk.convection.Gamma_c >= 0, ...
        'default_config: 临界直减率 Gamma_c 不能为负');
end