#!/bin/bash
# watch_part2_progress.sh
# Run in a separate terminal to monitor Part 2 simulation progress.
#
# Usage (from repo root in Git Bash):
#   bash 2026Contributions/watch_part2_progress.sh

REPO="C:/Users/armanshirzad/Repos/rSTEMMUS_SCOPE"
OUTPUT_BASE="$REPO/rSTEMMUS_SCOPE/output"
LOG="$REPO/2026Contributions/part2_simulation.log"

# Part 2 expected: Jul 1 2019 01:00 -> Dec 31 2020 23:00
# aerodyn.bin: 9 cols x 8 bytes = 72 bytes per timestep
BYTES_PER_TS=72
EXPECTED_TS=13199

echo "============================================================"
echo "  2-Year Part 2 Simulation Progress Monitor"
echo "  Expected: ~${EXPECTED_TS} timesteps (Jul 2019 - Dec 2020)"
echo "============================================================"
echo ""

# Wait for output folder to appear
echo "Waiting for simulation to start (output folder)..."
while true; do
  OUT_DIR=$(ls -td "$OUTPUT_BASE"/DE-STG_DE-STG_Test_FIXED_Final_2yr_OCTAVE_part2_* 2>/dev/null | head -1)
  if [ -n "$OUT_DIR" ]; then
    echo "Output dir found: $OUT_DIR"
    echo ""
    break
  fi
  sleep 10
done

AERODYN="$OUT_DIR/aerodyn.bin"
START_TS_EPOCH=$(date +%s)
PREV_BYTES=0
PREV_TIME=$START_TS_EPOCH

echo "Watching aerodyn.bin for timestep completion..."
echo "------------------------------------------------------------"
printf "%-8s %-10s %-8s %-14s %-10s %-s\n" "Time" "Timesteps" "Done%" "Rate(ts/hr)" "ETA" "Last log line"
echo "------------------------------------------------------------"

while true; do
  NOW=$(date +%s)
  ELAPSED=$(( NOW - START_TS_EPOCH ))

  # Count timesteps from aerodyn.bin size
  if [ -f "$AERODYN" ]; then
    BYTES=$(stat -c%s "$AERODYN" 2>/dev/null || stat -f%z "$AERODYN")
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

    ELAPSED_HRS=$(awk "BEGIN {printf \"%.1fh\", $ELAPSED / 3600}")
    LAST_LOG=$(tail -1 "$LOG" 2>/dev/null | cut -c1-40)

    printf "%-8s %-10s %-8s %-14s %-10s %-s\n" \
      "$ELAPSED_HRS" "$TS_DONE" "${PCT}%" "$RATE_TS_HR" "$ETA" "$LAST_LOG"

    PREV_BYTES=$BYTES
    PREV_TIME=$NOW

    # Check for CSV files = simulation finished
    if [ -f "$OUT_DIR/fluxes.csv" ]; then
      echo ""
      echo "============================================================"
      echo "  SIMULATION COMPLETE — fluxes.csv found!"
      echo "  Output: $OUT_DIR"
      echo "============================================================"
      exit 0
    fi
  else
    echo "$(date '+%H:%M:%S')  Waiting for aerodyn.bin..."
  fi

  sleep 60
done
