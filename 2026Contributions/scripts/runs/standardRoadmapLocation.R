# ============================================================================
# Standard Roadmap Template for rSTEMMUS_SCOPE
# ============================================================================
#
# Version : 2.0 (Parallelization-Ready)
# Updated : 2026-03-06
# Authors : Arman Shirzad, EcoExtreML Contributors
# License : Apache-2.0
#
# PURPOSE:
#   Universal, machine-agnostic template for setting up and executing
#   STEMMUS-SCOPE simulations via the rSTEMMUS_SCOPE R-wrapper.
#   Works on macOS, Linux, and Windows without path changes.
#
# INSTRUCTIONS:
#   1. Copy this file and rename it for your site (e.g., roadmap_MySite.R).
#   2. Fill in [SECTION 2] with your site configuration.
#   3. Choose execution engine: "octave" (free) or "matlab" (commercial).
#   4. Run!
#
# FOR PARALLEL / MULTI-SITE RUNS:
#   See [SECTION 6] at the bottom of this file for a ready-to-use template
#   that runs multiple simulations concurrently across CPU cores.
#
# REQUIREMENTS:
#   - R >= 4.1.0
#   - One of the following execution engines:
#       "octave"  : GNU Octave >= 8.0 (free, with 'io' + 'statistics' packages)
#       "matlab"  : MATLAB R2021a+ (requires license)
#       "mcr"     : MATLAB Runtime (free, requires pre-compiled binary;
#                   compile once with: cd src/ && compile_stemmus_scope)
#   - R Packages: tidyverse, lubridate, devtools
#   - For parallel: parallel (built-in on Mac/Linux)
#
# COMPLIANCE:
#   See docs/COMPLIANCE.md for FAIR, GDPR, and EU AI Act alignment.
# ============================================================================


# ============================================================================
# [SECTION 0] ENVIRONMENT SETUP
# ============================================================================

# Check if libraries are installed, else install/load them
# devtools::install_github("EcoExtreML/rSTEMMUS_SCOPE")
# For local development, uncomment the line below:
devtools::load_all(".")

library(tidyverse)
library(utils)
library(lubridate)
library(parallel)  # Required for multi-core parallelization (Mac/Linux)

# Perform initial setup (downloading template files if needed)
# Auto-detect if this is a first run (input/ directory missing)
if (!dir.exists(paste0(getwd(), "/rSTEMMUS_SCOPE/input/"))) {
  message("First run detected — input/ directory not found.")
  message("Running initial_setup() to download template files...")
  initial_setup(patch = paste0(getwd(), "/rSTEMMUS_SCOPE/"))
  message("initial_setup() complete.")
} else {
  message("Input directory found — skipping initial_setup().")
}


# ============================================================================
# [SECTION 1] DYNAMIC PATH CONFIGURATION (DO NOT EDIT)
# ============================================================================
# Automatically detects the rSTEMMUS_SCOPE folder in your current project directory.
# Ensure your working directory is set to the root of the repository.
# Uses forward slashes and paste0() — works identically on Mac, Linux, Windows.

patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")

# Verify critical directories exist
stopifnot(
  "src/ directory missing — re-clone the repository" = dir.exists(paste0(patch_path, "src/")),
  "input/ directory missing — did you extract input.7z?" = dir.exists(paste0(patch_path, "input/"))
)


# ============================================================================
# [SECTION 2] USER CONFIGURATION  <<<--- EDIT THIS SECTION --->>>
# ============================================================================

# --- Simulation Identity ---
site_name  <- "Site-CODE"             # FLUXNET ID, e.g. "DE-STG", "AR-SLu"
run_name_base <- "Simulation_01"      # Base name for this experiment

# --- Execution Engine ---
# "octave" : GNU Octave >= 8.0 (Free, open source, recommended for Mac/Linux)
# "matlab" : MATLAB R2021a+   (Requires license, full feature set)
# "mcr"    : MATLAB Runtime   (Free, no license — requires pre-compiled binary;
#                               compile once with: cd src/ && compile_stemmus_scope)
execution_engine <- "octave"

# Auto-append engine to run name for traceability
run_name <- paste0(run_name_base, "_", toupper(execution_engine))

# --- Time Window ---
start_time <- "2019-01-01T00:00"
end_time   <- "2019-01-02T00:00"     # 1 day = 24 hourly steps

# --- Input Data ---
# Path to your meteorological observations file (.rds format)
# Example columns needed: timestamp, Rin, Rli, p, Ta, RH, ea, ws, prec_mm_EC,
#                          LAI_FP, co2_flux, soil_temp*, SMC_*
weather_file_path <- "path/to/your_weather_data.rds"

# --- Site Constants ---
site_lat   <- 52.456                  # Latitude  (decimal degrees)
site_lon   <- 13.323                  # Longitude (decimal degrees)
site_elev  <- 50                      # Elevation (meters above sea level)
veg_class  <- "Closed Shrublands"     # IGBP vegetation class
canopy_h   <- 5                       # Canopy height (meters)
timestep   <- 60                      # Timestep in minutes (60 = hourly)

# --- Model Options ---
# setoptions vector (18 flags): see upstream docs for full descriptions
#   [1] soil_heat_method, [2] soil_layer_method, [3] soil_moisture_method,
#   [4] groundwater_coupling, ... etc.
model_options <- c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1)


# ============================================================================
# [SECTION 3] LOAD AND PREPARE DATA
# ============================================================================

if (!file.exists(weather_file_path)) {
  stop(paste("Weather data file not found:", weather_file_path,
             "\nPlease update 'weather_file_path' in Section 2."))
}

site_df <- readRDS(weather_file_path)

# Filter to simulation window
site_df <- site_df %>%
  filter(
    timestamp >= as.POSIXct(start_time, format = "%Y-%m-%dT%H:%M", tz = "UTC"),
    timestamp <= as.POSIXct(end_time,   format = "%Y-%m-%dT%H:%M", tz = "UTC")
  )

if (nrow(site_df) == 0) {
  stop("No data rows found in the specified time window. Check start_time / end_time.")
}

message(sprintf("Loaded %d timesteps (%s to %s)", nrow(site_df),
                min(site_df$timestamp), max(site_df$timestamp)))

# Compute fractional day-of-year (model time axis)
site_df$t_ <- yday(site_df$timestamp) +
              hour(site_df$timestamp) / 24 +
              minute(site_df$timestamp) / 1440
site_df$t_[is.na(site_df$t_)] <- 0

# Build forcing tibble
ts_input <- tibble(
  t_        = site_df$t_,
  timestamp = site_df$timestamp,
  Rin_sun   = as.numeric(site_df$Rin),
  Rli_      = as.numeric(site_df$Rli),
  p_        = as.numeric(site_df$p),
  Ta_       = as.numeric(site_df$Ta),
  RH_       = as.numeric(site_df$RH),
  ea_       = as.numeric(site_df$ea),
  u_        = as.numeric(site_df$ws),
  rain_     = as.numeric(ifelse(is.na(site_df$prec_mm_EC), 0,
                                site_df$prec_mm_EC / 36000)),
  LAI_      = as.numeric(site_df$LAI_FP),
  co2       = as.numeric(site_df$co2_flux)
)

# Calculate VPD using the FAO-56 Penman-Monteith saturated vapor pressure
Ta <- ts_input$Ta_
ea <- ts_input$ea_ / 10                # hPa -> kPa
es <- 0.6108 * exp((17.27 * Ta) / (Ta + 237.3))  # kPa
ts_input$VPD_ <- as.numeric(es - ea)   # kPa

# Replace any remaining NA/NaN with safe defaults
ts_input$rain_[is.na(ts_input$rain_)] <- 0


# ============================================================================
# [SECTION 4] GENERATE INPUT FILES & RUN (Reusable Function)
# ============================================================================
# Wraps the standard simulation steps into a function for easy execution
# AND parallelization. This function is used by both single runs and
# the parallel sweep in Section 6.

# Get initial conditions from first row of data
init_row <- site_df[1, ]

run_stemmus_scope <- function(sim_run_name, param_overrides = NULL) {

  # Step 1: Initialize Run Directory
  new_run(
    patch       = patch_path,
    StartTime   = start_time,
    EndTime     = end_time,
    site_name   = site_name,
    run_name    = sim_run_name,
    output_name = paste0(sim_run_name, "_OUT")
  )

  # Step 2: (Optional) Download soil properties for your coordinates
  # Requires ~24 GB SoilProperty dataset. Skip for initial testing.
  # soil_props <- get_SoilProperties(
  #   patch = file.path(patch_path, "input/input_for_input/SoilProperty/"),
  #   lon   = site_lon,
  #   lat   = site_lat
  # )

  # Step 3: Set Static Constants
  # IMPORTANT: Soil temperatures must be in Kelvin (add 273.15 to °C values).
  #            Soil moisture must be in m³/m³ (divide % by 100 if needed).
  input_constants(
    patch       = patch_path,
    site_name   = site_name,
    run_name    = sim_run_name,
    LAT         = site_lat,
    LON         = site_lon,
    elevation   = site_elev,
    IGBP_veg_long = veg_class,
    hc          = canopy_h,
    n_timestamps = length(ts_input$t_),
    timestep_min = timestep,
    initial_soil_temperature = data.frame(
      skt  = init_row$soil_temp10cm + 273.15,   # °C -> K
      stl1 = init_row$soil_temp10cm + 273.15,
      stl2 = init_row$soil_temp20cm + 273.15,
      stl3 = init_row$soil_temp30cm + 273.15,
      stl4 = init_row$soil_temp50cm + 273.15
    ),
    initial_volumetric_soil_water = data.frame(
      swvl1 = init_row$SMC_10cm / 100,          # % -> m³/m³
      swvl2 = init_row$SMC_20cm / 100,
      swvl3 = init_row$SMC_30cm / 100,
      swvl4 = init_row$SMC_60cm / 100
    ),
    # soil_property_list = soil_props,  # Uncomment if using get_SoilProperties
    startDOY   = yday(as.Date(start_time)),
    endDOY     = yday(as.Date(end_time)),
    timezn     = 1,
    setoptions = model_options
  )

  # Step 4: Set Time Series Data
  # Apply parameter overrides if passed (useful for sensitivity analysis)
  active_ts <- ts_input
  if (!is.null(param_overrides) && "LAI_multiplier" %in% names(param_overrides)) {
    active_ts$LAI_ <- active_ts$LAI_ * param_overrides$LAI_multiplier
  }

  input_timeseries(
    patch     = patch_path,
    site_name = site_name,
    run_name  = sim_run_name,
    t_file    = active_ts$t_,
    year_file = year(active_ts$timestamp),
    Rin_file  = active_ts$Rin_sun,
    Rli_file  = active_ts$Rli_,
    p_file    = active_ts$p_,
    Ta_file   = active_ts$Ta_,
    RH_file   = active_ts$RH_,
    ea_file   = active_ts$ea_,
    VPD_file  = active_ts$VPD_,
    u_file    = active_ts$u_,
    rain_file = active_ts$rain_,
    LAI_file  = active_ts$LAI_,
    CO2_file  = rep(415, length(active_ts$t_))
  )

  # Step 5: Execute Simulation (with error catching)
  cat(sprintf("\n🚀 Starting simulation: %s on engine: %s\n", sim_run_name, execution_engine))
  res <- tryCatch({
    run_inMATLAB(
      patch      = patch_path,
      site_name  = site_name,
      run_name   = sim_run_name,
      exe_method = execution_engine
    )
    "SUCCESS"
  }, error = function(e) { as.character(e$message) })

  return(list(run_name = sim_run_name, status = res))
}


# ============================================================================
# [SECTION 5] EXECUTE SINGLE SIMULATION
# ============================================================================
# Uncomment the block below to run a single simulation immediately.
# The function defined in Section 4 handles everything.

# result <- run_stemmus_scope(run_name)
# cat("Run:", result$run_name, "| Status:", result$status, "\n")


# ============================================================================
# [SECTION 6] PARALLEL EXECUTION GUIDE (Multi-Site / Parameter Sweep)
# ============================================================================
#
# The parallelization architecture ensures that every Octave/MATLAB process
# reads and writes to its OWN isolated directory. No shared state, no locks.
#
# HOW IT WORKS:
#   1. Each call to new_run() creates a unique folder:  runs/SITE_RUNNAME/
#   2. input_constants() and input_timeseries() write ONLY to that folder.
#   3. run_inMATLAB() injects CFG='/path/to/config.txt' directly into the
#      Octave/MATLAB command line — each process knows its own config.
#   4. Output goes to a unique timestamped folder: output/SITE_RUNNAME_TIME/
#
# USAGE:
#   Wrap Sections 4+5 in a function, then use parallel::mclapply (Mac/Linux)
#   or future.apply::future_lapply (Windows) to dispatch across CPU cores.
#
# EXAMPLE — Sweep over 5 LAI multipliers on 5 cores:
#
#   scenarios <- list(
#     list(id = 1, LAI_multiplier = 0.5),
#     list(id = 2, LAI_multiplier = 1.0),
#     list(id = 3, LAI_multiplier = 1.5),
#     list(id = 4, LAI_multiplier = 2.0),
#     list(id = 5, LAI_multiplier = 3.0)
#   )
#
#   parallel_worker <- function(scenario) {
#     custom_run_name <- paste0(run_name_base, "_LAIx", scenario$LAI_multiplier)
#     run_stemmus_scope(sim_run_name = custom_run_name, param_overrides = scenario)
#   }
#
#   # Fire all 5 simultaneously — 1 core per simulation:
#   results <- mclapply(scenarios, parallel_worker, mc.cores = 5)
#   print(results)
#
# FOR WINDOWS USERS (mclapply does not fork on Windows):
#   library(future)
#   library(future.apply)
#   plan(multisession, workers = 5)
#   results <- future_lapply(scenarios, parallel_worker)
#
# SCALING:
#   - 10-core laptop   -> mc.cores = 10  (10 sims simultaneously)
#   - 64-core HPC node -> mc.cores = 64  (64 sims simultaneously)
#   - Multi-node cluster: Use {future} + {batchtools} for SLURM/PBS dispatch.
#
# VERIFIED:
#   5-core smoke test on Apple M4: 5 x 1-day sims completed in 2.65 min
#   (vs ~12.5 min serial). Zero file conflicts. See test_parallel.R.
# ============================================================================

