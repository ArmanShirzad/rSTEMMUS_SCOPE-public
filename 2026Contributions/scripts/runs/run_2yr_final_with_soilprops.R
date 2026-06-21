## ═══════════════════════════════════════════════════════════════════════════
## run_2yr_final_with_soilprops.R
## ═══════════════════════════════════════════════════════════════════════════
## PURPOSE: Final 2-year simulation with DE-STG soil properties restored.
##          This is the DEFINITIVE run script — all previous 2yr scripts
##          were missing soil_property_list, causing r=0.145 against obs.
##
## WHAT CHANGED vs run_2yr_continuous_final_MATLAB.R:
##   1. Added get_SoilProperties() call for DE-STG (lon=13.31583, lat=52.45723)
##   2. Added soil_property_list = Soil_property_steglitz in input_constants()
##   EVERYTHING ELSE IS IDENTICAL (units, timestamps, setoptions, etc.)
##
## USAGE:
##   source("2026Contributions/run_2yr_final_with_soilprops.R")
##   # Default: exe_method = "octave"
##   # To run MATLAB: change exe_method below OR set it before sourcing
##
## DATE: 2026-04-20
## ═══════════════════════════════════════════════════════════════════════════

devtools::load_all(".")
library(tidyverse)
library(lubridate)

# ── Configuration ────────────────────────────────────────────────────────────
# Change this to "matlab" for the MATLAB run (Step 3 in task plan)
if (!exists("exe_method")) {
  exe_method <- "octave"
}

patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
site <- "DE-STG"
run  <- paste0("DE-STG_2yr_final_soilprops_", toupper(exe_method))
start_time <- "2019-01-01T00:00"
end_time   <- "2020-12-31T23:00"

cat("\n════════════════════════════════════════════════════════════════\n")
cat(sprintf("  FINAL 2-Year Run WITH Soil Properties [%s]\n", toupper(exe_method)))
cat(sprintf("  Period: %s to %s\n", start_time, end_time))
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

# VPD calculation (FAO-56 Penman-Monteith)
Ta <- ts_input$Ta_; ea <- ts_input$ea_/10
es <- 0.6108 * exp((17.27*Ta)/(Ta+237.3))
ts_input$VPD_ <- as.numeric(es - ea)
ts_input$rain_[is.na(ts_input$rain_)] <- 0

init_row <- steg_df[1, ]

# ── Create Run Directory ─────────────────────────────────────────────────────
out_timestamp <- format(Sys.time(), "%Y%b%d_%H%M")
new_run(patch=patch_path, StartTime=start_time, EndTime=end_time,
        site_name=site, run_name=run, output_name=out_timestamp)

# ══════════════════════════════════════════════════════════════════════════════
# ██  THE CRITICAL ADDITION: Load real DE-STG soil properties  ██
# ══════════════════════════════════════════════════════════════════════════════
cat("\n→ Loading DE-STG soil properties (Van Genuchten parameters)...\n")
Soil_property_steglitz <- get_SoilProperties(
  patch = file.path(patch_path, "input/SoilProperty/"),
  lon = 13.31583,
  lat = 52.45723
)
cat("  ✓ Soil properties loaded successfully\n")
cat(sprintf("  porosity[1]: %.4f | SaturatedK[1]: %.6f | Coefficient_n[1]: %.4f\n",
    Soil_property_steglitz$porosity[1],
    Soil_property_steglitz$SaturatedK[1],
    Soil_property_steglitz$Coefficient_n[1]))
cat("\n")
# ══════════════════════════════════════════════════════════════════════════════

# ── Set Constants (with soil properties + correct units) ─────────────────────
# UNITS CONFIRMED from input_constants.R source code (2026-04-20):
#   - Temperature: function does `value - 273.15` internally → pass KELVIN
#   - SMC: function writes value directly → pass FRACTION (0-1)
input_constants(
  patch=patch_path, site_name=site, run_name=run,
  LAT=52.456, LON=13.323, elevation=50,
  IGBP_veg_long="Closed Shrublands", hc=5,
  n_timestamps=length(ts_input$t_), timestep_min=60,
  initial_soil_temperature=data.frame(
    skt=init_row$soil_temp10cm+273.15,    # °C → K (correct: function subtracts 273.15)
    stl1=init_row$soil_temp10cm+273.15,
    stl2=init_row$soil_temp20cm+273.15,
    stl3=init_row$soil_temp30cm+273.15,
    stl4=init_row$soil_temp50cm+273.15),
  initial_volumetric_soil_water=data.frame(
    swvl1=init_row$SMC_10cm/100,          # % → fraction (correct: function writes directly)
    swvl2=init_row$SMC_20cm/100,
    swvl3=init_row$SMC_30cm/100,
    swvl4=init_row$SMC_60cm/100),
  # ████ THIS WAS MISSING IN ALL PREVIOUS 2yr RUNS ████
  soil_property_list = Soil_property_steglitz,
  startDOY=1, endDOY=731, timezn=1,
  setoptions=c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1))

cat("  ✓ input_constants() completed with soil properties\n")

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

# ── Launch Simulation ────────────────────────────────────────────────────────
cat("\n════════════════════════════════════════════════════════════════\n")
cat(sprintf("  Starting 2-Year %s Simulation WITH SOIL PROPERTIES\n", toupper(exe_method)))
cat(sprintf("  Period: %s to %s\n", start_time, end_time))
cat(sprintf("  Timesteps: %d\n", nrow(steg_df)))
cat(sprintf("  startDOY=1, endDOY=731\n"))
cat(sprintf("  Run label: %s\n", run))
cat(sprintf("  Engine: %s\n", toupper(exe_method)))
cat("  Soil properties: Soil_property_steglitz (DE-STG) ✓\n")
cat("  Temperature units: Kelvin (correct) ✓\n")
cat("  SMC units: fraction 0-1 (correct) ✓\n")
cat("════════════════════════════════════════════════════════════════\n\n")

t0 <- Sys.time()
run_inMATLAB(patch=patch_path, site_name=site, run_name=run, exe_method=exe_method)
elapsed <- difftime(Sys.time(), t0, units="hours")
cat(sprintf("\n✓ %s simulation completed in %.1f hours (%.1f min)\n",
    toupper(exe_method), as.numeric(elapsed), as.numeric(elapsed)*60))

# ── Save Output Path ─────────────────────────────────────────────────────────
out_target <- paste0(patch_path, "output/", site, "_", run, "_", out_timestamp)
out_file <- sprintf("2026Contributions/latest_2yr_soilprops_%s_output_dir.txt", tolower(exe_method))
writeLines(out_target, out_file)
cat(sprintf("Output dir saved to: %s\n", out_file))
cat(sprintf("Output dir: %s\n", out_target))
