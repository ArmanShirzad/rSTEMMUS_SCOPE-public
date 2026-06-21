function [CHK, hh, C4] = solveTridiagonalMatrixEquations(C4, hh, C4_a, RHS, ModelSettings, GroundwaterSettings)
    %{
        Solve the tridiagonal matrix equations using Thomas algorithm, which is
        in the form of Equation 4.25 (STEMMUS Technical Notes, page 41).
    %}

    if ~GroundwaterSettings.GroundwaterCoupling  % no Groundwater coupling, added by Mostafa
        indxBotm = 1; % index of bottom layer is 1, STEMMUS calculates from bottom to top
    else % Groundwater Coupling is activated
        % index of bottom layer after neglecting saturated layers (from bottom to top)
        indxBotm = GroundwaterSettings.indxBotmLayer;
    end

    RHS(indxBotm) = RHS(indxBotm) / C4(indxBotm, 1);

    for i = indxBotm + 1:ModelSettings.NN
        C4(i, 1) = C4(i, 1) - C4_a(i - 1) * C4(i - 1, 2) / C4(i - 1, 1);
        RHS(i) = (RHS(i) - C4_a(i - 1) * RHS(i - 1)) / C4(i, 1);
    end

    for i = ModelSettings.NL:-1:indxBotm
        RHS(i) = RHS(i) - C4(i, 2) * RHS(i + 1) / C4(i, 1);
    end

    if GroundwaterSettings.GroundwaterCoupling
        for i = indxBotm:-1:2
            RHS(i - 1) = RHS(i) + ModelSettings.DeltZ(i - 1);
        end
    end

    for i = 1:ModelSettings.NN
        CHK(i) = abs(RHS(i) - hh(i));
        hh(i) = RHS(i);
        SAVEhh(i) = hh(i);
    end

    % Guard: if Thomas algorithm produced NaN/complex matric heads, strip imaginary
    % parts and clamp non-finite values to a physically safe fallback (-1000 cm =
    % moderately moist soil). Only activates when solver input was already broken.
    if any(isnan(SAVEhh)) || any(~isreal(SAVEhh))
        warning('\n some items of SAVEhh are nan or not real — clamping to safe values\r');
        for i = 1:ModelSettings.NN
            if isnan(hh(i)) || ~isreal(hh(i))
                hh(i) = real(hh(i));
                if ~isfinite(hh(i))
                    hh(i) = -1000;
                end
            end
        end
    end
end
