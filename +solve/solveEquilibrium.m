function st = solveEquilibrium(blk, con)
    st = struct();

    % 网格生成
    [p_lev, p_center] = grid.PressureGrid(blk.grid.ps, blk.grid.ptop, blk.grid.N, blk.grid.strech);
    