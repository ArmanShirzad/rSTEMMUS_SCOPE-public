# ============================================================================
# Standard Roadmap Template for rSTEMMUS_SCOPE — v2.0
# ============================================================================
#
# Version : 2.0 (preflight + auto-execute)
# Updated : 2026-05-21
# Authors : Arman Shirzad, EcoExtreML Contributors
# License : Apache-2.0
#
# WHAT CHANGED FROM v1 (2026-03-06):
#   * Calls verify_install() first so missing engines / packages surface
#     before any model code runs (replaces silent stack traces).
#   * Calls validate_weather_rds() before reading the forcing file
#     (catches the "ran fine but produced nonsense" failure mode).
#   * Fixed the auto-setup heuristic — now triggers initial_setup() when
#     EITHER src/ OR input/ is missing (v1 only checked input/).
#   * Honest comment: initial_setup() downloads the model source, input
#     templates, runs/, and an example output — not just "template files".
#   * Section 5 now runs the simulation by default. The old commented-out
#     line was a silent dead-end for new users.
#
# INSTRUCTIONS:
#   1. Copy this file and rename it for your site (e.g., roadmap_MySite.R).
#   2. Fill in [SECTION 2] with your site configuration.
#   3. Choose execution engine: "octave" (free) / "matlab" / "mcr".
#   4. Run!  (Section 5 is no longer commented out by default.)
#
# REQUIREMENTS:
#   - R >= 4.1.0  +  rSTEMMUS_SCOPE package (load via devtools::load_all)
#   - One execution engine:
#       "octave" : GNU Octave >= 8.0 (free, with `io` + `statistics` packages)
#       "matlab" : MATLAB R2021a+   (requires license, uses -batch)
#       "mcr"    : MATLAB Runtime R2024a (free; needs precompiled binary —
#                   either compile once with src/compile_stemmus_scope.m or
#                   download from the project Release page)
#   - R packages: tidyverse, lubridate, devtools, jsonlite, BioC rhdf5
#     (run `Rscript bootstrap.R` once from the repo root to install all)
# ============================================================================


# ============================================================================
# [SECTION 0] ENVIRONMENT SETUP
# ============================================================================

devtools::load_all(".")

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
})

patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")

# Auto-detect first run. initial_setup() downloads the MATLAB model
# source code (src/), input templates (input/), run configs (runs/) and
# example output — a few hundred MB total. We trigger it when EITHER
# src/ or input/ is missing.
if (!dir.exists(paste0(patch_path, "src/")) ||
    !dir.exists(paste0(patch_path, "input/"))) {
  message("First-run detected — running initial_setup() to download ",
          "model source + input templates ...")
  initial_setup(patch = patch_path)
}

# Preflight: surface missing R packages, missing model dirs, missing
# engines before we waste time generating inputs.
status <- verify_install(patch = patch_path, verbose = TRUE)
required_ok <- status$ok[status$component %in%
                         c("R >= 4.1",
                           "rSTEMMUS_SCOPE/src/",
                           "rSTEMMUS_SCOPE/input/")]
if (!all(required_ok)) {
  stop("Preflight FAILED — see verify_install() output above. ",
       "Run `Rscript bootstrap.R` from the repo root, then retry.")
}


# ============================================================================
# [SECTION 1] DYNAMIC PATH CONFIGURATION (DO NOT EDIT)
# ============================================================================

stopifnot(
  "src/ directory missing — initial_setup() did not run successfully?" =
    dir.exists(paste0(patch_path, "src/")),
  "input/ directory missing — initial_setup() did not run successfully?" =
    dir.exists(paste0(patch_path, "input/"))
)


# ============================================================================
# [SECTION 2] USER CONFIGURATION  <<<--- EDIT THIS SECTION --->>>
# ============================================================================

# --- Simulation Identity ---
site_name     <- "Site-CODE"            # FLUXNET ID, e.g. "DE-STG", "AR-SLu"
run_name_base <- "Simulation_01"        # Base name for this experiment

# --- Execution Engine ---
# "octave"  : GNU Octave 8.0+ (free, recommended on Mac/Linux/no-license)
# "matlab"  : MATLAB R2021a+ (commercial, fastest on Windows)
# "mcr"     : MATLAB Runtime R2024a + STEMMUS_SCOPE_exe binary (free)
execution_engine <- "octave"

run_name <- paste0(run_name_base, "_", toupper(execution_engine))

# --- Time Window ---
start_time <- "2019-01-01T00:00"
end_time   <- "2019-01-02T00:00"        # 1 day = 24 hourly steps

# --- Forcing Data ---
# Path to your meteorological observations file (.rds format). Must contain
# the columns checked by validate_weather_rds() — run that function with
# verbose=TRUE for the full list.
weather_file_path <- "path/to/your_weather_data.rds"

# --- Site Constants ---
site_lat   <- 52.456                    # decimal degrees
site_lon   <- 13.323
site_elev  <- 50                        # meters above sea level
veg_class  <- "Closed Shrublands"       # IGBP class — see info_IGBP_classes()
canopy_h   <- 5                         # meters
timestep   <- 60                        # minutes (60 = hourly, 30 = half-hourly)

# --- Model Options ---
model_options <- c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1)


# ============================================================================
# [SECTION 3] LOAD AND PREPARE DATA  (preflight + ingest)
# ============================================================================

# Schema + unit validator. Failures here catch the silent
# "ran fine but produced nonsense" failure mode.
v <- validate_weather_rds(weather_file_path, verbose = TRUE)
if (!all(v$ok)) {
  stop("Weather file validation FAILED — fix the rows marked FAIL above.")
}

site_df <- readRDS(weather_file_path) %>%
  filter(
    timestamp >= as.POSIXct(start_time, format = "%Y-%m-%dT%H:%M", tz = "UTC"),
    timestamp <= as.POSIXct(end_time,   format = "%Y-%m-%dT%H:%M", tz = "UTC")
  )

if (nrow(site_df) == 0) {
  stop("No data rows found in the specified time window. Check start_time / end_time.")
}

message(sprintf("Loaded %d timesteps (%s to %s)", nrow(site_df),
                min(site_df$timestamp), max(site_df$timestamp)))

site_df$t_ <- yday(site_df$timestamp) +
              hour(site_df$timestamp) / 24 +
              minute(site_df$timestamp) / 1440
site_df$t_[is.na(site_df$t_)] <- 0

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

# FAO-56 Penman-Monteith saturated vapor pressure → VPD
Ta <- ts_input$Ta_
ea <- ts_input$ea_ / 10                 # hPa -> kPa
es <- 0.6108 * exp((17.27 * Ta) / (Ta + 237.3))
ts_input$VPD_ <- as.numeric(es - ea)
ts_input$rain_[is.na(ts_input$rain_)] <- 0

init_row <- site_df[1, ]


# ============================================================================
# [SECTION 4] GENERATE INPUT FILES & RUN (Reusable Function)
# ============================================================================

run_stemmus_scope <- function(sim_run_name, param_overrides = NULL) {

  new_run(
    patch       = patch_path,
    StartTime   = start_time,
    EndTime     = end_time,
    site_name   = site_name,
    run_name    = sim_run_name,
    output_name = paste0(sim_run_name, "_OUT")
  )

  # IMPORTANT: input_constants() converts °C -> K internally for soil
  # temperatures, so the values passed in MUST already be Kelvin. SMC is
  # m³/m³ (fraction), so percent values must be divided by 100.
  input_constants(
    patch        = patch_path,
    site_name    = site_name,
    run_name     = sim_run_name,
    LAT          = site_lat,
    LON          = site_lon,
    elevation    = site_elev,
    IGBP_veg_long = veg_class,
    hc           = canopy_h,
    n_timestamps = length(ts_input$t_),
    timestep_min = timestep,
    initial_soil_temperature = data.frame(
      skt  = init_row$soil_temp10cm + 273.15,
      stl1 = init_row$soil_temp10cm + 273.15,
      stl2 = init_row$soil_temp20cm + 273.15,
      stl3 = init_row$soil_temp30cm + 273.15,
      stl4 = init_row$soil_temp50cm + 273.15
    ),
    initial_volumetric_soil_water = data.frame(
      swvl1 = init_row$SMC_10cm / 100,
      swvl2 = init_row$SMC_20cm / 100,
      swvl3 = init_row$SMC_30cm / 100,
      swvl4 = init_row$SMC_60cm / 100
    ),
    # soil_property_list = get_SoilProperties(...),  # opt-in, needs 24 GB dataset
    startDOY   = yday(as.Date(start_time)),
    endDOY     = yday(as.Date(end_time)),
    timezn     = 1,
    setoptions = model_options
  )

  active_ts <- ts_input
  if (!is.null(param_overrides) &&
      "LAI_multiplier" %in% names(param_overrides)) {
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

  cat(sprintf("\nStarting simulation: %s on engine: %s\n",
              sim_run_name, execution_engine))
  res <- tryCatch({
    run_inMATLAB(
      patch      = patch_path,
      site_name  = site_name,
      run_name   = sim_run_name,
      exe_method = execution_engine
    )
    "SUCCESS"
  }, error = function(e) as.character(e$message))

  list(run_name = sim_run_name, status = res)
}


# ============================================================================
# [SECTION 5] EXECUTE THE SIMULATION  (runs by default — v1 had this commented)
# ============================================================================

result <- run_stemmus_scope(run_name)
cat(sprintf("Run: %s | Status: %s\n", result$run_name, result$status))


# ============================================================================
# [SECTION 6] PARALLEL EXECUTION GUIDE  (v2 — explicit, copy-pasteable)
# ============================================================================
#
# WHEN to use parallel execution:
#  * Parameter sweeps: one simulation per parameter value (LAI, Vcmax, etc.)
#  * Site ensembles: same script + same engine, different site coordinates
#  * Sensitivity analysis: same site, different forcing perturbations
# WHEN NOT to use it:
#  * One single 2yr simulation — that's already CPU-bound on one core,
#    parallel only helps if you have multiple INDEPENDENT runs to do.
#
# REQUIREMENTS:
#  * Linux/macOS:  built-in 'parallel' package (no install needed)
#  * Windows:      install once with
#                   install.packages(c("future", "future.apply"))
#                   (Windows' R has no fork; we use multisession workers)
#
# HOW IT WORKS — read this once:
#  Each call to run_stemmus_scope() routes through new_run() which writes
#  per-run input files into rSTEMMUS_SCOPE/runs/SITE_RUNNAME/. The CFG path
#  for that run is injected directly into the Octave/MATLAB command line —
#  NO path.txt, NO shared state. Two simulations with different run_names
#  cannot collide on disk or in memory. That's the basis of the parallelism.
#
# ----------------------------------------------------------------------------
# RECIPE — copy this whole block, edit the `scenarios` list, run it.
# ----------------------------------------------------------------------------
#
# # ---- 1) Replace Section 5 'result <- run_stemmus_scope(run_name)' with a
# #       parameter list defining what each worker should do.
# scenarios <- list(
#   list(suffix = "LAIx0.5", LAI_multiplier = 0.5),
#   list(suffix = "LAIx1.0", LAI_multiplier = 1.0),
#   list(suffix = "LAIx1.5", LAI_multiplier = 1.5),
#   list(suffix = "LAIx2.0", LAI_multiplier = 2.0)
# )
#
# # ---- 2) Worker function. Each scenario gets its own run_name so the
# #       runs/ and output/ folders don't collide.
# worker <- function(scenario) {
#   sim_run_name <- paste0(run_name_base, "_", scenario$suffix,
#                          "_", toupper(execution_engine))
#   run_stemmus_scope(sim_run_name      = sim_run_name,
#                     param_overrides   = scenario)
# }
#
# # ---- 3) Dispatch — pick ONE of the two blocks below, NOT both.
#
# # 3a) Mac / Linux only (fork-based, fastest):
# library(parallel)
# results <- mclapply(scenarios, worker,
#                    mc.cores = min(length(scenarios), parallel::detectCores()-1))
#
# # 3b) Windows (also works on Mac/Linux but slightly slower):
# library(future); library(future.apply)
# plan(multisession, workers = min(length(scenarios), parallel::detectCores()-1))
# results <- future_lapply(scenarios, worker, future.seed = TRUE)
# plan(sequential)   # release the worker processes when done
#
# # ---- 4) Report which runs succeeded.
# for (r in results) cat(sprintf("Run: %-50s | Status: %s\n", r$run_name, r$status))
#
# ----------------------------------------------------------------------------
# TROUBLESHOOTING:
#
#  * "could not find function 'mclapply'"  → mc-only function, you're on
#    Windows. Use the future_lapply block instead.
#
#  * Octave fails with 'cannot find io package' in workers but not in serial
#    → workers don't inherit the parent R session's Octave package cache.
#    Add 'pkg load io statistics' to each worker by editing run_inMATLAB.R
#    (it's already added to STEMMUS_SCOPE.m for Octave; nothing to do).
#
#  * RAM blows up on 4+ workers → each worker holds its own copy of the
#    weather .rds (~12 MB for ROTH) plus engine memory (~500 MB for
#    Octave 11). Budget ~700 MB per worker. Drop workers count if needed.
#
#  * Workers hang on Windows: the multisession plan inherits the parent's
#    working directory but NOT its devtools::load_all() state. Wrap the
#    worker so it reloads:
#        worker <- function(scenario) {
#          devtools::load_all(".")              # <- add this line
#          ... (rest of worker as above) ...
#        }
#
# ----------------------------------------------------------------------------
# VERIFIED on Apple M4 (Mar 2026): 5 x 1-day sims in 2.65 min vs 12.5 min
#   serial. Each worker created its own runs/SITE_RUNNAME/ — zero conflicts.
# ============================================================================
