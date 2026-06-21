## ═══════════════════════════════════════════════════════════════════════════
## test_theta_r_guard.R  —  MINIMAL 3-day test for theta_r floor guard
## ═══════════════════════════════════════════════════════════════════════════
## PURPOSE: Quick smoke test to verify the theta_r floor guard in
##          calculateTheta_LL.m doesn't crash and produces valid output.
##          Uses the same DE-STG setup as the definitive 2yr runs.
##
## This runs with Octave only (the engine with the dry-collapse issue).
## 3 days = 72 timesteps — should complete in < 2 minutes.
## ═══════════════════════════════════════════════════════════════════════════

devtools::load_all(".")
library(tidyverse)
library(lubridate)

exe_method <- "matlab"

patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
site <- "DE-STG"
run  <- "theta_r_guard_test_MATLAB"
start_time <- "2019-01-01T00:00"
end_time   <- "2019-01-03T23:00"   # 3 days = 72 timesteps

cat("\n════════════════════════════════════════════════════════════════\n")
cat("  THETA_R GUARD TEST — 3-day Octave run\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# ── Load Observation Data ────────────────────────────────────────────────────
steg_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
steg_df <- steg_df %>%
  filter(timestamp >= as.POSIXct(start_time, format="%Y-%m-%dT%H:%M", tz="UTC"),
         timestamp <= as.POSIXct(end_time,   format="%Y-%m-%dT%H:%M", tz="UTC"))
cat(sprintf("Loaded %d timesteps\n", nrow(steg_df)))

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

# ── Run ──────────────────────────────────────────────────────────────────────
t0 <- Sys.time()
run_inMATLAB(patch=patch_path, site_name=site, run_name=run, exe_method=exe_method)
elapsed <- difftime(Sys.time(), t0, units="mins")

# ── Verify Output ────────────────────────────────────────────────────────────
out_dir <- paste0(patch_path, "output/", site, "_", run, "_", out_timestamp)
theta_file <- file.path(out_dir, "Sim_Theta.csv")

if (file.exists(theta_file)) {
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])
  idx_60 <- which.min(abs(depths - 60))
  smc <- as.numeric(raw[-(1:3), idx_60])
  
  cat("\n════════════════════════════════════════════════════════════════\n")
  cat("  THETA_R GUARD TEST RESULTS\n")
  cat("════════════════════════════════════════════════════════════════\n")
  cat(sprintf("  Runtime: %.1f minutes\n", as.numeric(elapsed)))
  cat(sprintf("  Output: %s\n", out_dir))
  cat(sprintf("  Timesteps produced: %d\n", length(smc)))
  cat(sprintf("  SMC at 60cm — min: %.6f  max: %.6f  mean: %.6f\n",
              min(smc, na.rm=T), max(smc, na.rm=T), mean(smc, na.rm=T)))
  cat(sprintf("  Timesteps with SMC = 0.000: %d\n", sum(smc < 0.001, na.rm=T)))
  cat(sprintf("  Timesteps with SMC < theta_r: %d\n", sum(smc < 0.05, na.rm=T)))
  
  if (min(smc, na.rm=T) > 0.001) {
    cat("\n  ✅ PASS: No dry-collapse detected. Floor guard is working.\n")
  } else {
    cat("\n  ❌ FAIL: Dry-collapse still present.\n")
  }
} else {
  cat("\n  ❌ FAIL: Sim_Theta.csv not found. Simulation may have crashed.\n")
  cat(sprintf("  Expected at: %s\n", theta_file))
}
cat("════════════════════════════════════════════════════════════════\n")
