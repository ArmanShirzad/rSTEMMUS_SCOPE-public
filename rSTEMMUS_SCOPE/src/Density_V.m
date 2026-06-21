function [RHOV, DRHOVh, DRHOVT] = Density_V(TT, hh, g, Rv, NN)

    for MN = 1:NN
        % Guard: extract real part before any comparison (MATLAB errors on complex min/max/if).
        % Fallback to 20°C if TT is non-real or non-finite.
        if ~isreal(TT(MN)) || ~isfinite(TT(MN))
            T_safe = 20;
        else
            T_safe = max(min(TT(MN), 150), -20);
        end

        % Guard: sanitize hh — complex/NaN hh from the tridiagonal solver is the
        % primary source of cascade failures. Extract real part and clamp.
        if ~isreal(hh(MN))
            hh(MN) = real(hh(MN));
        end
        if ~isfinite(hh(MN))
            hh(MN) = -1000;  % moderately moist fallback
        end

        HR(MN) = exp(hh(MN) * g / (Rv * (T_safe + 273.15)));
        if HR(MN) <= 0.041
            HR(MN) = 0.041;
        elseif HR(MN) >= 1
            HR(MN) = 1;
        end
        RHOV_s(MN) = 1e-6 * exp(31.3716 - 6014.79 / (T_safe + 273.15) - 7.92495 * 0.001 * (T_safe + 273.15)) / (T_safe + 273.15);
        DRHOV_sT(MN) = RHOV_s(MN) * (6014.79 / (T_safe + 273.15)^2 - 7.92495 * 0.001) - RHOV_s(MN) / (T_safe + 273.15);
        if T_safe < -20
            RHOV_s(MN) = 1e-6 * exp(31.3716 - 6014.79 / (-20 + 273.15) - 7.92495 * 0.001 * (-20 + 273.15)) / (-20 + 273.15);
            DRHOV_sT(MN) = RHOV_s(MN) * (6014.79 / (-20 + 273.15)^2 - 7.92495 * 0.001) - RHOV_s(MN) / (-20 + 273.15);
        elseif T_safe >= 150
            RHOV_s(MN) = 1e-6 * exp(31.3716 - 6014.79 / (150 + 273.15) - 7.92495 * 0.001 * (150 + 273.15)) / (150 + 273.15);
            DRHOV_sT(MN) = RHOV_s(MN) * (6014.79 / (150 + 273.15)^2 - 7.92495 * 0.001) - RHOV_s(MN) / (150 + 273.15);
        end
        RHOV(MN) = RHOV_s(MN) * HR(MN);

        DRHOVh(MN) = RHOV_s(MN) * HR(MN) * g / (Rv * (T_safe + 273.15));

        DRHOVT(MN) = RHOV_s(MN) * HR(MN) * (-hh(MN) * g / (Rv * (T_safe + 273.15)^2)) + HR(MN) * DRHOV_sT(MN);

        % Guard: ensure outputs are real and finite (prevents complex propagation downstream)
        if ~isreal(RHOV(MN)) || ~isfinite(RHOV(MN))
            RHOV(MN) = 0;
        end
        if ~isreal(DRHOVh(MN)) || ~isfinite(DRHOVh(MN))
            DRHOVh(MN) = 0;
        end
        if ~isreal(DRHOVT(MN)) || ~isfinite(DRHOVT(MN))
            DRHOVT(MN) = 0;
        end

    end
