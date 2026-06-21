#!/bin/bash
# watch_both_and_validate.sh — Wait for BOTH Octave and MATLAB to finish,
# then run a single 3-way validation (Obs vs new-MATLAB vs new-Octave)
#
# Usage:
#   bash 2026Contributions/watch_both_and_validate.sh

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_BASE="$REPO/rSTEMMUS_SCOPE/output"
RSCRIPT="/c/Program Files/R/R-4.5.3/bin/Rscript.exe"

OCTAVE_PATTERN="DE-STG_DE-STG_2yr_continuous_final_2026"
MATLAB_PATTERN="DE-STG_DE-STG_2yr_continuous_final_MATLAB_2026"
EXPECTED_TS=17544
BYTES_PER_TS=72

echo "============================================================"
echo "  Dual-Simulation Watch + Combined Validation"
echo "  Waiting for BOTH Octave and MATLAB to complete"
echo "  before running 3-way validation"
echo "============================================================"
echo ""

# ── Discover output directories ──────────────────────────────
echo "Finding output directories..."
while true; do
  OCT_DIR=$(ls -td "$OUTPUT_BASE"/${OCTAVE_PATTERN}* 2>/dev/null | head -1)
  if [ -n "$OCT_DIR" ]; then break; fi
  sleep 5
done
echo "  Octave dir: $OCT_DIR"

while true; do
  MAT_DIR=$(ls -td "$OUTPUT_BASE"/${MATLAB_PATTERN}* 2>/dev/null | head -1)
  if [ -n "$MAT_DIR" ]; then break; fi
  sleep 5
done
echo "  MATLAB dir: $MAT_DIR"
echo ""

# ── Track both simulations ───────────────────────────────────
OCT_DONE=false
MAT_DONE=false
START_EPOCH=$(date +%s)

echo "Monitoring both simulations..."
echo "------------------------------------------------------------"
printf "%-8s | %-22s | %-22s\n" "Elapsed" "Octave" "MATLAB"
echo "------------------------------------------------------------"

while true; do
  NOW=$(date +%s)
  ELAPSED=$(( NOW - START_EPOCH ))
  ELAPSED_FMT=$(awk "BEGIN {printf \"%.1fh\", $ELAPSED / 3600}")

  # Octave status
  if [ "$OCT_DONE" = true ]; then
    OCT_STATUS="COMPLETE"
  elif [ -f "$OCT_DIR/fluxes.csv" ]; then
    OCT_DONE=true
    OCT_STATUS="COMPLETE"
    echo "$OCT_DIR" > "$REPO/2026Contributions/latest_2yr_continuous_final_output_dir.txt"
  elif [ -f "$OCT_DIR/aerodyn.bin" ]; then
    OCT_BYTES=$(stat -c%s "$OCT_DIR/aerodyn.bin" 2>/dev/null || wc -c < "$OCT_DIR/aerodyn.bin")
    OCT_TS=$(( OCT_BYTES / BYTES_PER_TS ))
    OCT_PCT=$(awk "BEGIN {printf \"%.1f\", $OCT_TS * 100 / $EXPECTED_TS}")
    OCT_STATUS="${OCT_TS}ts (${OCT_PCT}%)"
  else
    OCT_STATUS="waiting..."
  fi

  # MATLAB status
  if [ "$MAT_DONE" = true ]; then
    MAT_STATUS="COMPLETE"
  elif [ -f "$MAT_DIR/fluxes.csv" ]; then
    MAT_DONE=true
    MAT_STATUS="COMPLETE"
    echo "$MAT_DIR" > "$REPO/2026Contributions/latest_2yr_continuous_final_MATLAB_output_dir.txt"
  elif [ -f "$MAT_DIR/aerodyn.bin" ]; then
    MAT_BYTES=$(stat -c%s "$MAT_DIR/aerodyn.bin" 2>/dev/null || wc -c < "$MAT_DIR/aerodyn.bin")
    MAT_TS=$(( MAT_BYTES / BYTES_PER_TS ))
    MAT_PCT=$(awk "BEGIN {printf \"%.1f\", $MAT_TS * 100 / $EXPECTED_TS}")
    MAT_STATUS="${MAT_TS}ts (${MAT_PCT}%)"
  else
    MAT_STATUS="waiting..."
  fi

  printf "%-8s | %-22s | %-22s\n" "$ELAPSED_FMT" "$OCT_STATUS" "$MAT_STATUS"

  # Both done?
  if [ "$OCT_DONE" = true ] && [ "$MAT_DONE" = true ]; then
    echo ""
    echo "============================================================"
    echo "  BOTH SIMULATIONS COMPLETE"
    echo "  Octave: $OCT_DIR"
    echo "  MATLAB: $MAT_DIR"
    echo "============================================================"
    break
  fi

  sleep 60
done

# ── Run single 3-way validation ──────────────────────────────
echo ""
echo "============================================================"
echo "  RUNNING 3-WAY VALIDATION"
echo "  Obs vs new-MATLAB vs new-Octave"
echo "============================================================"
echo ""

cd "$REPO"

# Use the NEW MATLAB output as the matlab_theta baseline
MAT_THETA="$MAT_DIR/Sim_Theta.csv"

"$RSCRIPT" 2026Contributions/plot_validation.R \
  --octave_dir "$OCT_DIR" \
  --obs_file "$REPO/2026Contributions/EC_DWD_ROTH_clean.rds" \
  --matlab_theta "$MAT_THETA" \
  --start_time "2019-01-01" \
  --end_time "2020-12-31" \
  --site_label "DE-STG" \
  --run_label "2yr_continuous_final_3way"

echo ""
echo "============================================================"
echo "  ALL DONE — Watch + Validate Complete"
echo "  Validation plots in:"
echo "  2026Contributions/validation_plots/$(date +%Y%m%d)_DE-STG_2yr_continuous_final_3way/"
echo "============================================================"
