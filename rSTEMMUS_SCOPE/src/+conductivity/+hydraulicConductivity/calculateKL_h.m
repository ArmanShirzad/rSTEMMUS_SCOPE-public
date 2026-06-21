function kl_h = calculateKL_h(mu_w, se, Ks, m)

    % load Constants
    Constants = io.define_constants();

    MU_WN = Constants.MU_W0 * exp(Constants.MU1 / (8.31441 * (20 + 133.3)));
    CKT = MU_WN / mu_w;

    % Clamp se to [0,1]: floating-point precision can push se slightly above 1,
    % making (1 - se^(1/m)) negative and raising a negative to fractional power m
    % produces complex kl_h. real() + clamp is mathematically neutral for
    % physically valid se in [0,1].
    se = max(0, min(1, real(se)));

    if se == 0
        kl_h = 0;
    else
        kl_h = CKT * Ks * (se^(0.5)) * (1 - (1 - se^(1 / m))^m)^2;
    end

    % Ensure result is real (strip any residual imaginary component)
    kl_h = real(kl_h);

    if kl_h <= 1E-20
        kl_h = 1E-20;
    end
    if isnan(kl_h) == 1
        kl_h = 0;
        warning('\n case "isnan(kl_h) == 1", set "kl_h = 0" \r');
    end
end
