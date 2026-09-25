function [p_lev p_center] = PressureGrid(ps, ptop, N, strech)
    % 输入：
    % ps底部气压,
    % ptop顶部气压,
    % N 层数,
    % strech 几何因子，因为向下气压增大，大概是指数形式
    % ==============================================
    % 输出：
    % p_lev 层边界气压，N+1 *1
    % p_center 层中心气压 N*1
    if strech == 1
        p_lev = linspace(ptop, ps, N+1);
    else
        delta_p = (ps-ptop)*(strech - 1) / (strech ^ (N+1) - 1);
        num = 1:N;
        p_lev = ptop + [[0], delta_p * (strech.^(num+1) - 1)/(strech - 1)];
    end

    p_1 = p_lev(1:end-1);
    p_2 = p_lev(2:end);
    p_center = sqrt(p_1.*p_2);
end