# ============================================================================
# 1-Day Octave Fix Verification Test
# ============================================================================
# Date    : 2026-03-13
# Purpose : Run a 1-day simulation with the Octave fixes applied, then compare
#           against the MATLAB baseline (matlabfluxes.csv) and observations
#           (EC_DWD_ROTH_clean.rds) to verify if the ebal.m and hydraulic
#           conductivity fixes reduce the divergence.
# ============================================================================

devtools::load_all(".")
library(tidyverse)
library(utils)
library(lubridate)

# ============================================================================
# [1] SETUP
# ============================================================================
patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
site <- "DE-STG"
run  <- "1Day_OctaveFix_Test"
start_time <- "2019-01-01T00:00"
end_time   <- "2019-01-01T23:00"

# ============================================================================
# [2] LOAD DATA
# ============================================================================
steg_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")

steg_df <- steg_df %>%
  filter(
    timestamp >= as.POSIXct(start_time, format = "%Y-%m-%dT%H:%M", tz = "UTC"),
    timestamp <= as.POSIXct(end_time,   format = "%Y-%m-%dT%H:%M", tz = "UTC")
  )

cat(sprintf("Loaded %d timesteps (%s to %s)\n", nrow(steg_df),
            min(steg_df$timestamp), max(steg_df$timestamp)))

steg_df$t_ <- yday(steg_df$timestamp) +
               hour(steg_df$timestamp) / 24 +
               minute(steg_df$timestamp) / 1440
steg_df$t_[is.na(steg_df$t_)] <- 0

# Build forcing tibble
ts_input <- tibble(
  t_        = steg_df$t_,
  timestamp = steg_df$timestamp,
  Rin_sun   = as.numeric(steg_df$Rin),
  Rli_      = as.numeric(steg_df$Rli),
  p_        = as.numeric(steg_df$p),
  Ta_       = as.numeric(steg_df$Ta),
  RH_       = as.numeric(steg_df$RH),
  ea_       = as.numeric(steg_df$ea),
  u_        = as.numeric(steg_df$ws),
  rain_     = as.numeric(ifelse(is.na(steg_df$prec_mm_EC), 0,
                                steg_df$prec_mm_EC / 36000)),
  LAI_      = as.numeric(steg_df$LAI_FP),
  co2       = as.numeric(steg_df$co2_flux)
)

# Calculate VPD (FAO-56 Penman-Monteith standard)
Ta <- ts_input$Ta_
ea <- ts_input$ea_ / 10  # hPa -> kPa
es <- 0.6108 * exp((17.27 * Ta) / (Ta + 237.3))  # kPa
ts_input$VPD_ <- as.numeric(es - ea)
ts_input$rain_[is.na(ts_input$rain_)] <- 0

# ============================================================================
# [3] RUN SIMULATION
# ============================================================================
new_run(
  patch       = patch_path,
  StartTime   = start_time,
  EndTime     = end_time,
  site_name   = site,
  run_name    = run,
  output_name = format(Sys.time(), "%Y%b%d_%H%M%S")
)

init_row <- steg_df[1, ]

input_constants(
  patch       = patch_path,
  site_name   = site,
  run_name    = run,
  LAT         = 52.456,
  LON         = 13.323,
  elevation   = 50,
  IGBP_veg_long = "Closed Shrublands",
  hc          = 5,
  n_timestamps = length(ts_input$t_),
  timestep_min = 60,
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
  startDOY   = 1,
  endDOY     = 2,
  timezn     = 1,
  setoptions = c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1)
)

input_timeseries(
  patch     = patch_path,
  site_name = site,
  run_name  = run,
  t_file    = ts_input$t_,
  year_file = year(ts_input$timestamp),
  Rin_file  = ts_input$Rin_sun,
  Rli_file  = ts_input$Rli_,
  p_file    = ts_input$p_,
  Ta_file   = ts_input$Ta_,
  RH_file   = ts_input$RH_,
  ea_file   = ts_input$ea_,
  VPD_file  = ts_input$VPD_,
  u_file    = ts_input$u_,
  rain_file = ts_input$rain_,
  LAI_file  = ts_input$LAI_,
  CO2_file  = rep(415, length(ts_input$t_))
)

cat("\n🚀 Starting 1-day Octave simulation with fixes applied...\n")
sim_start <- Sys.time()

run_inMATLAB(
  patch      = patch_path,
  site_name  = site,
  run_name   = run,
  exe_method = "octave"
)

sim_end <- Sys.time()
cat(sprintf("⏱  Simulation completed in %.1f minutes\n",
            as.numeric(difftime(sim_end, sim_start, units = "mins"))))

# ============================================================================
# [4] COMPARE RESULTS — Octave vs MATLAB vs Observation
# ============================================================================
cat("\n📊 Loading results for comparison...\n")

# Find the output directory
output_dirs <- list.dirs(paste0(patch_path, "output/"), recursive = FALSE)
latest_dir <- output_dirs[grep("1Day_OctaveFix", output_dirs)]
if (length(latest_dir) > 1) latest_dir <- latest_dir[length(latest_dir)]

if (length(latest_dir) == 0) {
  stop("No output directory found for the test run!")
}

cat(sprintf("Output directory: %s\n", latest_dir))

# -- Load Octave outputs --
sim_theta_file <- file.path(latest_dir, "sim_Theta.csv")
fluxes_file    <- file.path(latest_dir, "fluxes.csv")

if (!file.exists(sim_theta_file)) {
  cat("⚠️  sim_Theta.csv not found. Listing available files:\n")
  print(list.files(latest_dir))
  stop("Cannot proceed without simulation output files.")
}

octave_theta <- read.csv(sim_theta_file, header = TRUE)
octave_fluxes <- read.csv(fluxes_file, header = TRUE)

cat(sprintf("  Octave output: %d SMC timesteps, %d flux timesteps\n",
            nrow(octave_theta), nrow(octave_fluxes)))

# -- Load MATLAB baseline (first 24 hours) --
matlab_fluxes <- read.csv("2026Contributions/matlabfluxes.csv", header = TRUE)
matlab_fluxes_1d <- matlab_fluxes[1:min(nrow(octave_fluxes), nrow(matlab_fluxes)), ]

cat(sprintf("  MATLAB baseline: using %d timesteps for comparison\n",
            nrow(matlab_fluxes_1d)))

# -- Load observations (first 24 hours) --
obs_data <- steg_df[1:nrow(octave_fluxes), ]

# ============================================================================
# [5] COMPUTE COMPARISON METRICS
# ============================================================================
cat("\n📈 Computing comparison metrics...\n\n")

# --- Latent Heat / ET comparison ---
n_compare <- min(nrow(octave_fluxes), nrow(matlab_fluxes_1d))
oct_lE    <- octave_fluxes$lEtot[1:n_compare]
mat_lE    <- matlab_fluxes_1d$lEtot[1:n_compare]

# Handle NaN
valid <- !is.na(oct_lE) & !is.na(mat_lE)
oct_lE_v <- oct_lE[valid]
mat_lE_v <- mat_lE[valid]

mean_oct_lE <- mean(oct_lE_v)
mean_mat_lE <- mean(mat_lE_v)
rmse_lE     <- sqrt(mean((oct_lE_v - mat_lE_v)^2))
bias_lE     <- mean(oct_lE_v - mat_lE_v)
pct_diff_lE <- (mean_oct_lE - mean_mat_lE) / abs(mean_mat_lE) * 100

cat("═══════════════════════════════════════════════════════════\n")
cat("  LATENT HEAT (ET) COMPARISON — Octave vs MATLAB (1-day)\n")
cat("═══════════════════════════════════════════════════════════\n")
cat(sprintf("  Octave mean lEtot:  %.2f W/m²\n", mean_oct_lE))
cat(sprintf("  MATLAB mean lEtot:  %.2f W/m²\n", mean_mat_lE))
cat(sprintf("  RMSE:               %.2f W/m²\n", rmse_lE))
cat(sprintf("  Bias (Oct-Mat):     %.2f W/m²\n", bias_lE))
cat(sprintf("  Pct Difference:     %+.1f%%\n", pct_diff_lE))
cat(sprintf("  [Pre-fix benchmark: +52%% overestimation]\n"))

if (abs(pct_diff_lE) < 52) {
  cat("  ✅ IMPROVED — ET difference reduced from 52%% to",
      sprintf("%.1f%%\n", abs(pct_diff_lE)))
} else {
  cat("  ❌ No improvement in ET — further investigation needed\n")
}

# --- SMC at 60cm comparison ---
# Find the column closest to 60cm depth
smc_cols <- grep("^V", names(octave_theta))
n_layers <- length(smc_cols)
# Layer closest to 60cm (layers numbered from bottom, depth ~500cm total)
# For a standard model, column 1 = bottom, column NL = top
# 60cm from surface = layer NL-6 approximately
target_col <- max(1, n_layers - 6)

oct_smc <- octave_theta[, target_col + 1]  # +1 for row offset

# Get observed SMC at 60cm
obs_smc <- obs_data$SMC_60cm[1:min(length(oct_smc), nrow(obs_data))]
if (!is.null(obs_smc) && length(obs_smc) > 0) {
  obs_smc <- obs_smc / 100  # % -> m3/m3

  valid_smc <- !is.na(oct_smc) & !is.na(obs_smc)
  oct_smc_v <- oct_smc[valid_smc]
  obs_smc_v <- obs_smc[valid_smc]

  rmse_smc <- sqrt(mean((oct_smc_v - obs_smc_v)^2))
  bias_smc <- mean(oct_smc_v - obs_smc_v)

  cat("\n═══════════════════════════════════════════════════════════\n")
  cat("  SOIL MOISTURE @ 60cm — Octave vs Observation (1-day)\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat(sprintf("  Octave mean SMC:    %.4f m³/m³\n", mean(oct_smc_v)))
  cat(sprintf("  Observed mean SMC:  %.4f m³/m³\n", mean(obs_smc_v)))
  cat(sprintf("  RMSE:               %.4f m³/m³\n", rmse_smc))
  cat(sprintf("  Bias (Oct-Obs):     %+.4f m³/m³\n", bias_smc))
  cat(sprintf("  [Pre-fix benchmark: +0.10 m³/m³ wet bias]\n"))
}

# --- Sensible Heat comparison ---
oct_H <- octave_fluxes$Htot[1:n_compare]
mat_H <- matlab_fluxes_1d$Htot[1:n_compare]

valid_H <- !is.na(oct_H) & !is.na(mat_H)
if (sum(valid_H) > 0) {
  rmse_H <- sqrt(mean((oct_H[valid_H] - mat_H[valid_H])^2))
  bias_H <- mean(oct_H[valid_H] - mat_H[valid_H])

  cat("\n═══════════════════════════════════════════════════════════\n")
  cat("  SENSIBLE HEAT — Octave vs MATLAB (1-day)\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat(sprintf("  RMSE:               %.2f W/m²\n", rmse_H))
  cat(sprintf("  Bias (Oct-Mat):     %+.2f W/m²\n", bias_H))
}

cat("\n═══════════════════════════════════════════════════════════\n")
cat("  VERDICT\n")
cat("═══════════════════════════════════════════════════════════\n")

if (abs(pct_diff_lE) < 20 && abs(bias_smc) < 0.05) {
  cat("  🎯 MAJOR IMPROVEMENT: Both ET and SMC divergence reduced significantly.\n")
} else if (abs(pct_diff_lE) < 52 || abs(bias_smc) < 0.10) {
  cat("  📉 PARTIAL IMPROVEMENT: Some metrics improved but further work needed.\n")
} else {
  cat("  ⚠️  MINIMAL IMPROVEMENT: Core drainage issue likely remains.\n")
}

cat("\nDone! Results logged above.\n")
