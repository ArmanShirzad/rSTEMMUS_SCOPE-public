#!/bin/bash
# watch_and_validate.sh — Watch simulation progress, then auto-run validation on completion
#
# Usage:
#   bash 2026Contributions/watch_and_validate.sh <RUN_PATTERN> <EXPECTED_TIMESTEPS> <RUN_LABEL> [MATLAB_THETA]
#
# Examples:
#   bash 2026Contributions/watch_and_validate.sh DE-STG_DE-STG_2yr_continuous_final 17544 2yr_continuous_final
#   bash 2026Contributions/watch_and_validate.sh DE-STG_DE-STG_2yr_continuous_final_MATLAB 17544 2yr_continuous_final_MATLAB
#
# After simulation completes (fluxes.csv appears), automatically runs plot_validation.R

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_BASE="$REPO/rSTEMMUS_SCOPE/output"
RSCRIPT="/c/Program Files/R/R-4.5.3/bin/Rscript.exe"

RUN_PATTERN="${1:?Usage: watch_and_validate.sh <RUN_PATTERN> <EXPECTED_TIMESTEPS> <RUN_LABEL> [MATLAB_THETA]}"
EXPECTED_TS="${2:?Usage: watch_and_validate.sh <RUN_PATTERN> <EXPECTED_TIMESTEPS> <RUN_LABEL>}"
RUN_LABEL="${3:?Usage: watch_and_validate.sh <RUN_PATTERN> <EXPECTED_TIMESTEPS> <RUN_LABEL>}"
MATLAB_THETA="${4:-$REPO/2026Contributions/validation_plots/Sim_Theta.csv}"

BYTES_PER_TS=72

echo "============================================================"
echo "  STEMMUS_SCOPE Watch + Auto-Validate"
echo "  Pattern : ${RUN_PATTERN}*"
echo "  Expected: ~${EXPECTED_TS} timesteps"
echo "  Label   : ${RUN_LABEL}"
echo "============================================================"
echo ""

# Wait for output folder to appear
echo "Waiting for simulation output folder..."
while true; do
  OUT_DIR=$(ls -td "$OUTPUT_BASE"/${RUN_PATTERN}* 2>/dev/null | head -1)
  if [ -n "$OUT_DIR" ]; then
    echo "Output dir found: $OUT_DIR"
    echo ""
    break
  fi
  sleep 5
done

AERODYN="$OUT_DIR/aerodyn.bin"
START_TS_EPOCH=$(date +%s)
PREV_BYTES=0
PREV_TIME=$START_TS_EPOCH

echo "Watching aerodyn.bin for timestep completion..."
echo "------------------------------------------------------------"
printf "%-8s %-10s %-8s %-14s %-10s\n" "Elapsed" "Timesteps" "Done%" "Rate(ts/hr)" "ETA"
echo "------------------------------------------------------------"

while true; do
  NOW=$(date +%s)
  ELAPSED=$(( NOW - START_TS_EPOCH ))

  if [ -f "$AERODYN" ]; then
    BYTES=$(stat -c%s "$AERODYN" 2>/dev/null || stat -f%z "$AERODYN" 2>/dev/null || wc -c < "$AERODYN")
    TS_DONE=$(( BYTES / BYTES_PER_TS ))
    PCT=$(awk "BEGIN {printf \"%.1f\", $TS_DONE * 100 / $EXPECTED_TS}")

    DT=$(( NOW - PREV_TIME ))
    if [ "$DT" -gt 0 ] && [ "$BYTES" -gt "$PREV_BYTES" ]; then
      DB=$(( BYTES - PREV_BYTES ))
      RATE_TS_HR=$(awk "BEGIN {printf \"%.0f\", ($DB / $BYTES_PER_TS) / $DT * 3600}")
    else
      RATE_TS_HR="--"
    fi

    if [ "$RATE_TS_HR" != "--" ] && [ "$RATE_TS_HR" -gt 0 ] 2>/dev/null; then
      TS_LEFT=$(( EXPECTED_TS - TS_DONE ))
      ETA_HRS=$(awk "BEGIN {printf \"%.1f\", $TS_LEFT / $RATE_TS_HR}")
      ETA="${ETA_HRS}h"
    else
      ETA="--"
    fi

    ELAPSED_FMT=$(awk "BEGIN {printf \"%.1fh\", $ELAPSED / 3600}")

    printf "%-8s %-10s %-8s %-14s %-10s\n" \
      "$ELAPSED_FMT" "$TS_DONE" "${PCT}%" "$RATE_TS_HR" "$ETA"

    PREV_BYTES=$BYTES
    PREV_TIME=$NOW

    # Check for fluxes.csv = simulation finished
    if [ -f "$OUT_DIR/fluxes.csv" ]; then
      echo ""
      echo "============================================================"
      echo "  SIMULATION COMPLETE"
      echo "  Output: $OUT_DIR"
      echo "  Timesteps: $TS_DONE"
      echo "  Wall time: $ELAPSED_FMT"
      echo "============================================================"

      # Save output dir
      echo "$OUT_DIR" > "$REPO/2026Contributions/latest_${RUN_LABEL}_output_dir.txt"
      echo "Output dir saved to: 2026Contributions/latest_${RUN_LABEL}_output_dir.txt"

      # ── AUTO-VALIDATE ──────────────────────────────────────────
      echo ""
      echo "============================================================"
      echo "  AUTO-TRIGGERING VALIDATION PLOTS"
      echo "============================================================"
      echo ""

      cd "$REPO"
      "$RSCRIPT" 2026Contributions/plot_validation.R \
        --octave_dir "$OUT_DIR" \
        --obs_file "$REPO/2026Contributions/EC_DWD_ROTH_clean.rds" \
        --matlab_theta "$MATLAB_THETA" \
        --start_time "2019-01-01" \
        --end_time "2020-12-31" \
        --site_label "DE-STG" \
        --run_label "$RUN_LABEL"

      echo ""
      echo "============================================================"
      echo "  WATCH + VALIDATE COMPLETE for: $RUN_LABEL"
      echo "============================================================"
      exit 0
    fi
  else
    echo "$(date '+%H:%M:%S')  Waiting for aerodyn.bin..."
  fi

  sleep 60
done
