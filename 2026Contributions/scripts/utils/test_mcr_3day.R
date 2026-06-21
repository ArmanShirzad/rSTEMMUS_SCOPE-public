## ═══════════════════════════════════════════════════════════════════════════
## test_mcr_3day.R  —  MCR validation: 3-day simulation + multi-depth metrics
## ═══════════════════════════════════════════════════════════════════════════
## PURPOSE: Validate the compiled STEMMUS-SCOPE binary running via MATLAB
##          Runtime R2024a. Produces the same multi-depth performance metrics
##          as the MATLAB and Octave 2yr runs, but on a 3-day window.
##          The key test is: does the binary produce output at all?
##          And: are the values physically reasonable (not NaN/zero)?
## ═══════════════════════════════════════════════════════════════════════════

devtools::load_all(".")
library(tidyverse)
library(lubridate)

exe_method <- "mcr"

patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
site <- "DE-STG"
run  <- "mcr_validation_test"
start_time <- "2019-01-01T00:00"
end_time   <- "2019-01-03T23:00"   # 3 days = 72 timesteps

cat("\n════════════════════════════════════════════════════════════════\n")
cat("  MCR VALIDATION TEST — 3-day MATLAB Runtime run\n")
cat(sprintf("  Engine: %s\n", exe_method))
cat(sprintf("  Period: %s to %s\n", start_time, end_time))
cat("════════════════════════════════════════════════════════════════\n\n")

# ── Load Observation Data ────────────────────────────────────────────────────
steg_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
steg_df <- steg_df %>%
  filter(timestamp >= as.POSIXct(start_time, format="%Y-%m-%dT%H:%M", tz="UTC"),
         timestamp <= as.POSIXct(end_time,   format="%Y-%m-%dT%H:%M", tz="UTC"))
cat(sprintf("Loaded %d timesteps of observations\n", nrow(steg_df)))

# ── Build Time Vector ────────────────────────────────────────────────────────
steg_df$t_ <- yday(steg_df$timestamp) + hour(steg_df$timestamp)/24 + minute(steg_df$timestamp)/1440
steg_df$t_[is.na(steg_df$t_)] <- 0

# ── Build Timeseries Input ───────────────────────────────────────────────────
ts_input <- tibble(
  t_ = steg_df$t_, timestamp = steg_df$timestamp,
  Rin_sun = as.numeric(steg_df$Rin), Rli_ = as.numeric(steg_df$Rli),
  p_ = as.numeric(steg_df$p), Ta_ = as.numeric(steg_df$Ta),
  RH_ = as.numeric(steg_df$RH), ea_ = as.numeric(steg_df$ea),
  u_ = as.numeric(steg_df$ws),
  rain_ = as.numeric(ifelse(is.na(steg_df$prec_mm_EC), 0, steg_df$prec_mm_EC/36000)),
  LAI_ = as.numeric(steg_df$LAI_FP), co2 = as.numeric(steg_df$co2_flux)
)

Ta <- ts_input$Ta_; ea <- ts_input$ea_/10
es <- 0.6108 * exp((17.27*Ta)/(Ta+237.3))
ts_input$VPD_ <- as.numeric(es - ea)
ts_input$rain_[is.na(ts_input$rain_)] <- 0

init_row <- steg_df[1, ]

# ── Create Run Directory ─────────────────────────────────────────────────────
out_timestamp <- format(Sys.time(), "%Y%b%d_%H%M")
new_run(patch=patch_path, StartTime=start_time, EndTime=end_time,
        site_name=site, run_name=run, output_name=out_timestamp)

# ── Load Soil Properties ─────────────────────────────────────────────────────
Soil_property_steglitz <- get_SoilProperties(
  patch = file.path(patch_path, "input/SoilProperty/"),
  lon = 13.31583, lat = 52.45723
)

# ── Set Constants ─────────────────────────────────────────────────────────────
input_constants(
  patch=patch_path, site_name=site, run_name=run,
  LAT=52.456, LON=13.323, elevation=50,
  IGBP_veg_long="Closed Shrublands", hc=5,
  n_timestamps=length(ts_input$t_), timestep_min=60,
  initial_soil_temperature=data.frame(
    skt=init_row$soil_temp10cm+273.15, stl1=init_row$soil_temp10cm+273.15,
    stl2=init_row$soil_temp20cm+273.15, stl3=init_row$soil_temp30cm+273.15,
    stl4=init_row$soil_temp50cm+273.15),
  initial_volumetric_soil_water=data.frame(
    swvl1=init_row$SMC_10cm/100, swvl2=init_row$SMC_20cm/100,
    swvl3=init_row$SMC_30cm/100, swvl4=init_row$SMC_60cm/100),
  soil_property_list = Soil_property_steglitz,
  startDOY=1, endDOY=3, timezn=1,
  setoptions=c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1))

# ── Set Timeseries Inputs ────────────────────────────────────────────────────
input_timeseries(
  patch=patch_path, site_name=site, run_name=run,
  t_file=ts_input$t_, year_file=year(ts_input$timestamp),
  Rin_file=ts_input$Rin_sun, Rli_file=ts_input$Rli_,
  p_file=ts_input$p_, Ta_file=ts_input$Ta_,
  RH_file=ts_input$RH_, ea_file=ts_input$ea_,
  VPD_file=ts_input$VPD_, u_file=ts_input$u_,
  rain_file=ts_input$rain_, LAI_file=ts_input$LAI_,
  CO2_file=rep(415, length(ts_input$t_)))

# ── Run via MCR ──────────────────────────────────────────────────────────────
cat("\n→ Launching simulation via MATLAB Runtime (MCR)...\n")
t0 <- Sys.time()
run_inMATLAB(patch=patch_path, site_name=site, run_name=run, exe_method=exe_method)
elapsed <- difftime(Sys.time(), t0, units="mins")

# ── Analyze Output ───────────────────────────────────────────────────────────
out_dir <- paste0(patch_path, "output/", site, "_", run, "_", out_timestamp)
theta_file <- file.path(out_dir, "Sim_Theta.csv")

cat("\n════════════════════════════════════════════════════════════════\n")
cat("  MCR VALIDATION RESULTS\n")
cat("════════════════════════════════════════════════════════════════\n")
cat(sprintf("  Runtime: %.1f minutes\n", as.numeric(elapsed)))
cat(sprintf("  Output dir: %s\n", out_dir))

if (!file.exists(theta_file)) {
  cat("\n  ❌ FAIL: Sim_Theta.csv not found. MCR simulation may have crashed.\n")
  cat(sprintf("  Expected at: %s\n", theta_file))
  cat("════════════════════════════════════════════════════════════════\n")
  quit(status = 1)
}

# Read simulation output
raw <- read.csv(theta_file, header = FALSE)
depths_row <- as.numeric(raw[1, ])
target_depths <- c(10, 20, 30, 60)

cat(sprintf("  Sim_Theta.csv loaded: %d rows, %d columns\n", nrow(raw), ncol(raw)))
cat(sprintf("  Timesteps produced: %d\n", nrow(raw) - 3))

# Also load the MATLAB 2yr reference for the same 3-day window (first 72 timesteps)
matlab_dir <- paste0(patch_path, "output/DE-STG_DE-STG_2yr_final_soilprops_MATLAB_2026Apr22_1927")
matlab_theta <- file.path(matlab_dir, "Sim_Theta.csv")
has_matlab_ref <- file.exists(matlab_theta)

if (has_matlab_ref) {
  raw_matlab <- read.csv(matlab_theta, header = FALSE)
  cat("  MATLAB 2yr reference loaded for parity comparison\n")
}

# Multi-depth analysis
cat("\n  ── MCR vs Observations (3-day window) ──────────────────────\n\n")
cat(sprintf("  %-8s  %-8s  %-8s  %-12s  %-12s\n", "Depth", "r", "KGE", "RMSE", "Bias"))
cat("  ─────────────────────────────────────────────────────────\n")

for (d in target_depths) {
  idx <- which.min(abs(depths_row - d))
  smc_mcr <- as.numeric(raw[-(1:3), idx])

  # Get observations for same depth
  obs_col <- paste0("SMC_", d, "cm")
  if (!obs_col %in% names(steg_df)) next
  obs <- steg_df[[obs_col]] / 100  # % → fraction

  n <- min(length(smc_mcr), length(obs))
  smc_mcr <- smc_mcr[1:n]; obs <- obs[1:n]
  valid <- !is.na(smc_mcr) & !is.na(obs)
  smc_mcr <- smc_mcr[valid]; obs <- obs[valid]

  if (length(smc_mcr) < 5) next
  r <- cor(smc_mcr, obs)
  bias <- mean(smc_mcr - obs)
  rmse <- sqrt(mean((smc_mcr - obs)^2))
  alpha <- sd(smc_mcr) / sd(obs)
  beta <- mean(smc_mcr) / mean(obs)
  kge <- 1 - sqrt((r - 1)^2 + (alpha - 1)^2 + (beta - 1)^2)

  cat(sprintf("  %-8s  %+.3f    %+.3f    %.4f        %+.4f\n",
              paste0(d, " cm"), r, kge, rmse, bias))
}

# MCR vs MATLAB parity (if reference available)
if (has_matlab_ref) {
  cat("\n  ── MCR vs MATLAB Parity (3-day window) ───────────────────\n\n")
  cat(sprintf("  %-8s  %-8s  %-12s  %-12s\n", "Depth", "r", "RMSE", "Bias"))
  cat("  ─────────────────────────────────────────────────────────\n")

  depths_matlab <- as.numeric(raw_matlab[1, ])

  for (d in target_depths) {
    idx_mcr <- which.min(abs(depths_row - d))
    idx_mat <- which.min(abs(depths_matlab - d))
    smc_mcr <- as.numeric(raw[-(1:3), idx_mcr])
    smc_mat <- as.numeric(raw_matlab[-(1:3), idx_mat])

    # Only use first 72 timesteps from MATLAB reference
    n <- min(length(smc_mcr), 72)
    smc_mcr <- smc_mcr[1:n]; smc_mat <- smc_mat[1:n]
    valid <- !is.na(smc_mcr) & !is.na(smc_mat)
    smc_mcr <- smc_mcr[valid]; smc_mat <- smc_mat[valid]

    if (length(smc_mcr) < 5) next
    r <- cor(smc_mcr, smc_mat)
    bias <- mean(smc_mcr - smc_mat)
    rmse <- sqrt(mean((smc_mcr - smc_mat)^2))

    cat(sprintf("  %-8s  %+.3f    %.6f      %+.6f\n", paste0(d, " cm"), r, rmse, bias))
  }
}

# Quick sanity check
smc_60 <- as.numeric(raw[-(1:3), which.min(abs(depths_row - 60))])
cat(sprintf("\n  SMC 60cm — min: %.6f  max: %.6f  mean: %.6f\n",
            min(smc_60, na.rm=T), max(smc_60, na.rm=T), mean(smc_60, na.rm=T)))
cat(sprintf("  Timesteps with SMC=0: %d\n", sum(smc_60 < 0.001, na.rm=T)))

if (min(smc_60, na.rm=T) > 0.001 && !any(is.na(smc_60))) {
  cat("\n  ✅ PASS: MCR simulation completed successfully with valid output.\n")
} else {
  cat("\n  ⚠️ WARNING: Output has anomalies (NaN or zero values).\n")
}

cat("════════════════════════════════════════════════════════════════\n")
