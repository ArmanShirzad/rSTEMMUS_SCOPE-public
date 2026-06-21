devtools::load_all(".")
library(tidyverse)
library(lubridate)

# ── 2-Year Continuous MATLAB Run (fair 1:1 comparison with Octave) ──────────
# Identical configuration to run_2yr_continuous_final.R but exe_method="matlab"
# Uses the SAME fixed .m source files and SAME initial conditions as Octave.
# This replaces the old MATLAB baseline (Sim_Theta.csv) which was generated
# before the Mar 13 fixes and with different initial conditions.

patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
site <- "DE-STG"
run  <- "DE-STG_2yr_continuous_final_MATLAB"
start_time <- "2019-01-01T00:00"
end_time   <- "2020-12-31T23:00"

steg_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
steg_df <- steg_df %>%
  filter(timestamp >= as.POSIXct(start_time, format="%Y-%m-%dT%H:%M", tz="UTC"),
         timestamp <= as.POSIXct(end_time,   format="%Y-%m-%dT%H:%M", tz="UTC"))
cat(sprintf("Loaded %d timesteps\n", nrow(steg_df)))

steg_df$t_ <- yday(steg_df$timestamp) + hour(steg_df$timestamp)/24 + minute(steg_df$timestamp)/1440
steg_df$t_[is.na(steg_df$t_)] <- 0

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

# Create run directory
out_timestamp <- format(Sys.time(), "%Y%b%d_%H%M")
new_run(patch=patch_path, StartTime=start_time, EndTime=end_time,
        site_name=site, run_name=run, output_name=out_timestamp)

# IDENTICAL to Octave run: startDOY=1, endDOY=731, Kelvin temps, m³/m³ SMC
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
  startDOY=1, endDOY=731, timezn=1,
  setoptions=c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1))

input_timeseries(
  patch=patch_path, site_name=site, run_name=run,
  t_file=ts_input$t_, year_file=year(ts_input$timestamp),
  Rin_file=ts_input$Rin_sun, Rli_file=ts_input$Rli_,
  p_file=ts_input$p_, Ta_file=ts_input$Ta_,
  RH_file=ts_input$RH_, ea_file=ts_input$ea_,
  VPD_file=ts_input$VPD_, u_file=ts_input$u_,
  rain_file=ts_input$rain_, LAI_file=ts_input$LAI_,
  CO2_file=rep(415, length(ts_input$t_)))

cat("\n========================================\n")
cat("Starting 2-Year CONTINUOUS MATLAB Simulation\n")
cat(sprintf("  Period: %s to %s\n", start_time, end_time))
cat(sprintf("  Timesteps: %d\n", nrow(steg_df)))
cat(sprintf("  startDOY=1, endDOY=731\n"))
cat(sprintf("  Run label: %s\n", run))
cat("  NOTE: Using same fixed .m files as Octave run\n")
cat("========================================\n\n")
t0 <- Sys.time()
run_inMATLAB(patch=patch_path, site_name=site, run_name=run, exe_method="matlab")
cat(sprintf("Done in %.1f min (%.1f hours)\n",
    as.numeric(difftime(Sys.time(), t0, units="mins")),
    as.numeric(difftime(Sys.time(), t0, units="hours"))))

out_target <- paste0(patch_path, "output/", site, "_", run, "_", out_timestamp)
writeLines(out_target, "2026Contributions/latest_2yr_continuous_final_MATLAB_output_dir.txt")
cat(sprintf("Output dir: %s\n", out_target))
