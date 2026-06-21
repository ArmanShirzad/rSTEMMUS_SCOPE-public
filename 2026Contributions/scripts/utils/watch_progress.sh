#!/bin/bash
# watch_progress.sh — Generic STEMMUS_SCOPE simulation progress monitor
#
# Usage:
#   bash 2026Contributions/watch_progress.sh <RUN_PATTERN> <EXPECTED_TIMESTEPS>
#
# Examples:
#   bash 2026Contributions/watch_progress.sh DE-STG_DE-STG_2yr_validation 17544
#   bash 2026Contributions/watch_progress.sh DE-STG_DE-STG_6mo_test 4345
#
# The script auto-discovers the output directory matching RUN_PATTERN in rSTEMMUS_SCOPE/output/

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_BASE="$REPO/rSTEMMUS_SCOPE/output"

RUN_PATTERN="${1:?Usage: watch_progress.sh <RUN_PATTERN> <EXPECTED_TIMESTEPS>}"
EXPECTED_TS="${2:?Usage: watch_progress.sh <RUN_PATTERN> <EXPECTED_TIMESTEPS>}"

# aerodyn.bin: 9 cols x 8 bytes = 72 bytes per timestep
BYTES_PER_TS=72

echo "============================================================"
echo "  STEMMUS_SCOPE Simulation Progress Monitor"
echo "  Pattern : ${RUN_PATTERN}*"
echo "  Expected: ~${EXPECTED_TS} timesteps"
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
    # Get file size (works on both Windows Git Bash and Unix)
    BYTES=$(stat -c%s "$AERODYN" 2>/dev/null || stat -f%z "$AERODYN" 2>/dev/null || wc -c < "$AERODYN")
    TS_DONE=$(( BYTES / BYTES_PER_TS ))
    PCT=$(awk "BEGIN {printf \"%.1f\", $TS_DONE * 100 / $EXPECTED_TS}")

    # Rate over last interval
    DT=$(( NOW - PREV_TIME ))
    if [ "$DT" -gt 0 ] && [ "$BYTES" -gt "$PREV_BYTES" ]; then
      DB=$(( BYTES - PREV_BYTES ))
      RATE_TS_HR=$(awk "BEGIN {printf \"%.0f\", ($DB / $BYTES_PER_TS) / $DT * 3600}")
    else
      RATE_TS_HR="--"
    fi

    # ETA
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

      # Write confirmed output dir for downstream scripts
      RUN_LABEL=$(echo "$RUN_PATTERN" | sed 's/^[A-Z\-]*_[A-Z\-]*_//')
      echo "$OUT_DIR" > "$REPO/2026Contributions/latest_${RUN_LABEL}_output_dir.txt"
      echo "Output dir saved to: 2026Contributions/latest_${RUN_LABEL}_output_dir.txt"
      exit 0
    fi
  else
    echo "$(date '+%H:%M:%S')  Waiting for aerodyn.bin..."
  fi

  sleep 60
done
