# Guard-ablation experiment data

Data behind the numerical-guard ablation reported in the accompanying manuscript. The experiment reverts the
ten defensive numerical guards to their pre-hardening state and compares the result against the guarded build
under byte-identical soil parameters, soil initialisation and meteorological forcing.

The ten reverted files are:

```
+conductivity/calculateHydraulicConductivity.m
+conductivity/+hydraulicConductivity/calculateKL_h.m
+conductivity/+hydraulicConductivity/calculateSe.m
+conductivity/+hydraulicConductivity/calculateGamma_hh.m
+conductivity/+hydraulicConductivity/calculateTheta_LL.m
+soilmoisture/calculateMatricCoefficients.m
+soilmoisture/solveSoilMoistureBalance.m
+soilmoisture/solveTridiagonalMatrixEquations.m
Density_V.m
ebal.m
```

Site: Berlin-Steglitz (DE-STG), 2019 to 2020, 17,544 hourly timesteps.

---

## `matlab/` — MATLAB R2025b arm

| File | Contents |
|---|---|
| `AB_metrics_summary.csv` | Correlation, RMSE and bias between the reverted and guarded builds, per variable, for three configurations: two-year and two-month under the uncorrected initialisation, and two-month under the corrected initialisation |
| `AB_2yr_timeseries_old_vs_new.csv` | Hourly soil moisture at 60 cm and total latent heat for both builds, full two-year run |
| `AB_cascade_evidence.txt` | Solver warning counts under the corrected initialisation |

## `octave/` — GNU Octave 11.1.0 arm

| File | Contents |
|---|---|
| `AB_octave_metrics_summary.csv` | Correlation, RMSE and bias between the reverted and guarded builds, per variable |
| `AB_octave_2yr_timeseries_old_vs_new.csv` | Hourly soil moisture at 60 cm and total latent heat for both builds, with timestamps |
| `AB_octave_engine_stderr.log` | Complete solver log for the reverted build |
| `AB_octave_smc60_old_vs_new.png` | Timeseries and scatter of the two builds at 60 cm |

---

## Summary of the result

The guards leave canopy and radiative physics essentially untouched and are load-bearing in the soil solver.
Removing them produces a solution that remains statistically similar to the correct one while being
physically invalid, and the two interpreters fail differently:

- On MATLAB the unguarded build emits 2,252,805 solver warning lines.
- On Octave it emits 1,756, all ordinary energy-balance non-convergence, and exits normally.
- On both, soil moisture at 60 cm collapses to exactly zero during the 2019 dry-down: 1,067 timesteps on
  MATLAB, 1,513 on Octave.

Evaluated against field observations at 60 cm, the unguarded Octave build attains r = 0.844 against r = 0.853
for the guarded build, with a smaller bias. Only the Kling-Gupta Efficiency separates them clearly, 0.627
against 0.774.

## Reproducing

Revert the ten files listed above to their pre-hardening versions in a separate copy of `src/`, then run the
model from that copy with an otherwise unchanged configuration. Keep the working tree untouched so the
guarded build remains available for comparison.
