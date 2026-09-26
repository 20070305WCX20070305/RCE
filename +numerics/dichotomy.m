function root = dichotomy(func, a0, b0, tol)

    %   输入: func 句柄, a0/b0 两初始猜测(K), tol 残差容差
    %   假设: func 单调增；若两猜测同号，沿正确方向几何扩张找异号点

    function r = zero_solve(f, a, b, tol)
        fa = f(a); fb = f(b);
        while abs(fb) > tol
            c = (a + b) / 2;
            fc = f(c);
            if fa * fc > 0
                a = c;
                fa = fc;
            else
                b = c;
                fb = fc;
            end
        end
        r = b;
    end

    a = max([a0,b0]);
    b = min([a0,b0]);
    fa = func(a); fb = func(b);
    if fa * fb < 0
        root = zero_solve(func, a, b, tol);
        return;
    end

    if abs(fa) < abs(fb)
        x0 = a; fx0 = fa;
    else
        x0 = b; fx0 = fb;
    end

    if fx0 > 0
        dir = -1;
    else
        dir = 1;
    end

    rho = 1.2;
    h0 = max(abs(a - b), 1);
    r = h0;
    kmax = 100;

    for k = 1:kmax
        xc = x0 + dir*r; fc = func(xc);
        if fx0 * fc < 0
            root = zero_solve(func, xc, x0, tol);
            return;
        end
        r = r * rho;
    end
end