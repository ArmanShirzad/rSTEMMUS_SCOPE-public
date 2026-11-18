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

The statistics and the 60 cm figure can be recomputed from the archived time series without running the
model:

```bash
python 2026Contributions/docs/guard_ablation/reproduce_guard_ablation.py
```

This writes `reproduced_guard_ablation_metrics.csv` (r, RMSE and bias between the two builds, and the number of
time steps with soil moisture collapsed to zero) and `reproduced_guard_ablation_smc60.png` into this folder.

To repeat the ablation itself:

The unguarded (OLD) versions of the ten files are in [`unguarded_src/`](unguarded_src/), at the same relative
paths as in `rSTEMMUS_SCOPE/src/`. They are identical in content to the corresponding files of the original
[EcoExtreML/rSTEMMUS_SCOPE](https://github.com/EcoExtreML/rSTEMMUS_SCOPE) source (`rSTEMMUS_SCOPE/src.zip`,
commit `b0e8684`), and they are the files used for both arms above. Every other model file is the same in
OLD and NEW.

1. Make a second copy of this repository, for example
   `git clone https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public.git ../rSTEMMUS_SCOPE-unguarded`.
2. From the root of **this** repository, copy the ten files into that copy:

   ```bash
   Rscript 2026Contributions/docs/guard_ablation/make_unguarded_copy.R ../rSTEMMUS_SCOPE-unguarded
   ```

   The script refuses to overwrite the repository it is run from, so the guarded build stays intact.
3. Run the same two-year DE-STG script in both copies with an identical configuration (same soil parameters,
   soil initialisation and forcing; only the output folder differs), for example
   `2026Contributions/scripts/runs/run_2yr_final_with_soilprops.R` with `exe_method` set to `"matlab"` or
   `"octave"`. A two-year run takes about 1.3 h on MATLAB and about 9 h on Octave.
4. Compare the two output folders (soil moisture at 60 cm in `Sim_Theta.csv`, latent heat in `fluxes.csv`).
