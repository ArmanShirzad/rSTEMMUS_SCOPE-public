"""Recompute the guard-ablation statistics and figure from the archived time series.

Reproduces, without re-running the model:
  - the two-year OLD-vs-NEW agreement for soil moisture at 60 cm and total latent heat
    (manuscript Table 4, two-year rows; MATLAB and Octave arms), and
  - the two-panel figure (time series + 1:1 scatter at 60 cm; manuscript Fig. 2),
  - the count of time steps with soil moisture collapsed to zero.

OLD = build with the ten guards reverted, NEW = guarded build (see README.md in this folder).

Usage (from the repository root):
    python 2026Contributions/docs/guard_ablation/reproduce_guard_ablation.py
Requires: Python 3.8+, pandas, numpy, matplotlib.
"""
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent
ARMS = {
    "MATLAB R2025b": HERE / "matlab" / "AB_2yr_timeseries_old_vs_new.csv",
    "GNU Octave 11.1.0": HERE / "octave" / "AB_octave_2yr_timeseries_old_vs_new.csv",
}


def stats(old, new):
    ok = np.isfinite(old) & np.isfinite(new)
    o, n = old[ok], new[ok]
    return {
        "n": int(ok.sum()),
        "r": float(np.corrcoef(o, n)[0, 1]),
        "RMSE": float(np.sqrt(np.mean((o - n) ** 2))),
        "bias_old_minus_new": float(np.mean(o - n)),
    }


def main():
    rows = []
    data = {}
    for arm, path in ARMS.items():
        df = pd.read_csv(path)
        data[arm] = df
        for var, label in [("SMC60", "SMC_60cm"), ("lEtot", "total_ET_lEtot")]:
            s = stats(df[f"{var}_old"].to_numpy(float), df[f"{var}_new"].to_numpy(float))
            rows.append({"engine": arm, "variable": label, **s})
        rows.append({"engine": arm, "variable": "SMC_60cm zero-collapse steps (OLD)",
                     "n": int((df["SMC60_old"] <= 0).sum())})
    out = pd.DataFrame(rows)
    out_csv = HERE / "reproduced_guard_ablation_metrics.csv"
    out.to_csv(out_csv, index=False, float_format="%.4f")
    print(out.to_string(index=False))
    print(f"\nWritten: {out_csv}")

    fig, axes = plt.subplots(len(ARMS), 2, figsize=(12, 4.2 * len(ARMS)),
                             gridspec_kw={"width_ratios": [2.2, 1]})
    for row, (arm, df) in zip(np.atleast_2d(axes), data.items()):
        ax_ts, ax_sc = row
        ax_ts.plot(df["SMC60_new"].to_numpy(), lw=0.8, label="NEW (guards on)")
        ax_ts.plot(df["SMC60_old"].to_numpy(), lw=0.8, label="OLD (guards reverted)")
        ax_ts.set_title(f"{arm}: soil moisture at 60 cm")
        ax_ts.set_xlabel("hourly time step (2019-2020)")
        ax_ts.set_ylabel("m³ m⁻³")
        ax_ts.legend(frameon=False)
        ax_sc.scatter(df["SMC60_new"], df["SMC60_old"], s=1, alpha=0.3)
        lim = [0, float(np.nanmax(df[["SMC60_new", "SMC60_old"]].to_numpy())) * 1.05]
        ax_sc.plot(lim, lim, "k--", lw=0.8)
        ax_sc.set_xlim(lim); ax_sc.set_ylim(lim)
        ax_sc.set_xlabel("NEW"); ax_sc.set_ylabel("OLD"); ax_sc.set_title("1:1 scatter")
    fig.tight_layout()
    out_png = HERE / "reproduced_guard_ablation_smc60.png"
    fig.savefig(out_png, dpi=150)
    print(f"Written: {out_png}")


if __name__ == "__main__":
    main()
