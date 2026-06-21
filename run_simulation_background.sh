#!/bin/bash

# run_simulation_background.sh
# Created by Antigravity to run simulations in the background on macOS

# 1. Define Paths
PROJECT_ROOT="/Users/armanmacair/repos/Stemmus-Scope/rSTEMMUS_SCOPE"
SCRIPT_PATH="2026Contributions/roadmapSeglitz.R"
LOG_FILE="simulation_output.log"

# 2. Check for caffeinate
if ! command -v caffeinate &> /dev/null; then
    echo "Error: 'caffeinate' command not found. This script requires macOS."
    exit 1
fi

# 3. Change to project directory
cd "$PROJECT_ROOT" || { echo "Failed to cd to $PROJECT_ROOT"; exit 1; }

echo "=========================================================="
echo "Starting Simulation (Background Mode)"
echo "----------------------------------------------------------"
echo "Script: $SCRIPT_PATH"
echo "Output Log: $LOG_FILE"
echo "Preventing Sleep: YES (caffeinate active)"
echo "=========================================================="

# 4. Install all required dependencies (including devtools and rSTEMMUS_SCOPE deps)
echo "Installing required R packages (this may take a while first time)..."
Rscript -e "
pkgs <- c('devtools', 'data.table', 'dplyr', 'ecmwfr', 'rio', 'sf', 'terra', 'tidyr', 'archive', 'filesstrings')
for (p in pkgs) {
  if (!require(p, character.only = TRUE, quietly = TRUE)) {
    install.packages(p, repos = 'http://cran.rstudio.com/')
  }
}
# Bioconductor packages
if (!require('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = 'http://cran.rstudio.com/')
if (!require('rhdf5', quietly = TRUE)) BiocManager::install('rhdf5', ask = FALSE)
# GitHub packages  
if (!require('zen4R', quietly = TRUE)) remotes::install_github('eblondel/zen4R')
"

# 5. Run the specific Roadmap script with caffeinate and nohup
# -d: Prevent display sleep
# -i: Prevent idle sleep
# -m: Prevent disk sleep
# -s: Prevent system sleep (requires AC power usually)
# nohup: Keep running even if terminal closes
# &: Run in background

nohup caffeinate -dims Rscript "$SCRIPT_PATH" > "$LOG_FILE" 2>&1 &

PID=$!
echo "Simulation started in background with PID: $PID"
echo ""
echo "To monitor progress, run:"
echo "  tail -f $PROJECT_ROOT/$LOG_FILE"
echo ""
echo "IMPORTANT: Please keep your laptop connected to power."
echo "=========================================================="
