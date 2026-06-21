## ═══════════════════════════════════════════════════════════════════════════
## run_TUCC_2yr_MCR.R  —  2-Year TUCC simulation (MCR engine)
## ═══════════════════════════════════════════════════════════════════════════
## PURPOSE: Run a full 2-year (2019–2020) STEMMUS-SCOPE simulation on the
##          TUCC (TU Berlin Campus) urban EC site using the MCR engine.
##          This is the FIRST simulation on a site other than ROTH!
##
## DATA:    EC_DWD_TUCC_clean.rds (17544 hourly timesteps)
## SITE:    TUCC, Berlin — lat=52.51, lon=13.33, elev=36m, z=56m
##
## NOTES ON DATA GAPS:
##   - Soil temperature columns (soil_temp10cm/20/30/50cm) are MISSING.
##     → Use air temperature (Ta) at t=0 as proxy for initial soil temp.
##       At Jan 1 midnight the soil-air coupling is tight (≈ 8°C).
##   - SMC columns use different naming: SMC20/SMC40/SMC60 (not SMC_10cm etc.)
##     → SMC values range 7–110; they are in % VWC (divide by 100 for m³/m³).
##     → Map: SMC20→swvl1, SMC40→swvl2, SMC60→swvl3, SMC60→swvl4 (deepest).
##
## DATE: 2026-06-02
## ═══════════════════════════════════════════════════════════════════════════

devtools::load_all(".")
library(tidyverse)
library(lubridate)

# ── Configuration ────────────────────────────────────────────────────────────
exe_method <- "mcr"

patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
site <- "TUCC"
run  <- paste0("TUCC_2yr_soilprops_", toupper(exe_method))
start_time <- "2019-01-01T00:00"
end_time   <- "2020-12-31T23:00"

cat("\n════════════════════════════════════════════════════════════════\n")
cat(sprintf("  TUCC 2-Year Run [%s]\n", toupper(exe_method)))
cat(sprintf("  Period: %s to %s\n", start_time, end_time))
cat(sprintf("  FIRST SIMULATION ON A NEW SITE (not ROTH)!\n"))
cat("════════════════════════════════════════════════════════════════\n\n")

# ── Load Observation Data ────────────────────────────────────────────────────
tucc_df <- readRDS("2026Contributions/EC_DWD_TUCC_clean.rds")
tucc_df <- tucc_df %>%
  filter(timestamp >= as.POSIXct(start_time, format="%Y-%m-%dT%H:%M", tz="UTC"),
         timestamp <= as.POSIXct(end_time,   format="%Y-%m-%dT%H:%M", tz="UTC"))
cat(sprintf("Loaded %d timesteps\n", nrow(tucc_df)))

# ── Build Time Vector ────────────────────────────────────────────────────────
tucc_df$t_ <- yday(tucc_df$timestamp) + hour(tucc_df$timestamp)/24 + minute(tucc_df$timestamp)/1440
tucc_df$t_[is.na(tucc_df$t_)] <- 0

# ── Build Timeseries Input ───────────────────────────────────────────────────
ts_input <- tibble(
  t_ = tucc_df$t_, timestamp = tucc_df$timestamp,
  Rin_sun = as.numeric(tucc_df$Rin), Rli_ = as.numeric(tucc_df$Rli),
  p_ = as.numeric(tucc_df$p), Ta_ = as.numeric(tucc_df$Ta),
  RH_ = as.numeric(tucc_df$RH), ea_ = as.numeric(tucc_df$ea),
  u_ = as.numeric(tucc_df$ws),
  rain_ = as.numeric(ifelse(is.na(tucc_df$prec_mm_EC), 0, tucc_df$prec_mm_EC/36000)),
  LAI_ = as.numeric(tucc_df$LAI_FP), co2 = as.numeric(tucc_df$co2_flux)
)

# VPD calculation (FAO-56 Penman-Monteith)
Ta <- ts_input$Ta_; ea <- ts_input$ea_/10
es <- 0.6108 * exp((17.27*Ta)/(Ta+237.3))
ts_input$VPD_ <- as.numeric(es - ea)
ts_input$rain_[is.na(ts_input$rain_)] <- 0

# ── Initial Conditions ───────────────────────────────────────────────────────
# Soil temperature: use air temperature as proxy (no soil temp sensors at TUCC)
init_row <- tucc_df[1, ]
init_Ta <- init_row$Ta  # 8.14°C at Jan 1 midnight

cat(sprintf("\n→ Initial conditions (row 1):\n"))
cat(sprintf("  Air temperature (proxy for soil): %.2f°C\n", init_Ta))
cat(sprintf("  SMC20: %.2f%%  SMC40: %.2f%%  SMC60: %.2f%%\n",
    init_row$SMC20, init_row$SMC40, init_row$SMC60))

# ── Create Run Directory ─────────────────────────────────────────────────────
out_timestamp <- format(Sys.time(), "%Y%b%d_%H%M")
new_run(patch=patch_path, StartTime=start_time, EndTime=end_time,
        site_name=site, run_name=run, output_name=out_timestamp)

# ══════════════════════════════════════════════════════════════════════════════
# ██  Load TUCC soil properties (same Berlin region, different coords)      ██
# ══════════════════════════════════════════════════════════════════════════════
cat("\n→ Loading TUCC soil properties (Van Genuchten parameters)...\n")
Soil_property_tucc <- get_SoilProperties(
  patch = file.path(patch_path, "input/SoilProperty/"),
  lon = 13.33,
  lat = 52.51
)
cat("  ✓ Soil properties loaded successfully\n")
cat(sprintf("  porosity[1]: %.4f | SaturatedK[1]: %.6f | Coefficient_n[1]: %.4f\n",
    Soil_property_tucc$porosity[1],
    Soil_property_tucc$SaturatedK[1],
    Soil_property_tucc$Coefficient_n[1]))
cat("\n")

# ── Set Constants ─────────────────────────────────────────────────────────────
# TUCC site parameters from B_runSCOPE.R:
#   LAT=52.51, LON=13.33, z_c=56m, hc_c=25
#   IGBP: "Closed Shrublands" (urban mix with vegetation)
input_constants(
  patch=patch_path, site_name=site, run_name=run,
  LAT=52.51, LON=13.33, elevation=36,
  IGBP_veg_long="Closed Shrublands", hc=5,
  n_timestamps=length(ts_input$t_), timestep_min=60,
  initial_soil_temperature=data.frame(
    skt=init_Ta+273.15,          # Use air temp as proxy → Kelvin
    stl1=init_Ta+273.15,
    stl2=init_Ta+273.15,
    stl3=init_Ta+273.15,
    stl4=init_Ta+273.15),
  initial_volumetric_soil_water=data.frame(
    swvl1=init_row$SMC20/100,    # SMC20 (%) → m³/m³
    swvl2=init_row$SMC40/100,    # SMC40 (%) → m³/m³
    swvl3=init_row$SMC60/100,    # SMC60 (%) → m³/m³
    swvl4=init_row$SMC60/100),   # deepest = reuse SMC60
  soil_property_list = Soil_property_tucc,
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
cat(sprintf("  Starting 2-Year %s Simulation — TUCC\n", toupper(exe_method)))
cat(sprintf("  Period: %s to %s\n", start_time, end_time))
cat(sprintf("  Timesteps: %d\n", nrow(tucc_df)))
cat(sprintf("  startDOY=1, endDOY=731\n"))
cat(sprintf("  Run label: %s\n", run))
cat(sprintf("  Engine: %s\n", toupper(exe_method)))
cat("  Soil properties: Soil_property_tucc (TUCC coords) ✓\n")
cat("  Temperature units: Kelvin (correct) ✓\n")
cat("  SMC units: fraction 0-1 (correct) ✓\n")
cat("  NOTE: soil temp initial = air temp proxy ✓\n")
cat("════════════════════════════════════════════════════════════════\n\n")

t0 <- Sys.time()
run_inMATLAB(patch=patch_path, site_name=site, run_name=run, exe_method=exe_method)
elapsed <- difftime(Sys.time(), t0, units="hours")
cat(sprintf("\n✓ %s simulation completed in %.1f hours (%.1f min)\n",
    toupper(exe_method), as.numeric(elapsed), as.numeric(elapsed)*60))

# ── Save Output Path ─────────────────────────────────────────────────────────
out_target <- paste0(patch_path, "output/", site, "_", run, "_", out_timestamp)
out_file <- "2026Contributions/logs/latest_TUCC_2yr_mcr_output_dir.txt"
dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
writeLines(out_target, out_file)
cat(sprintf("Output dir saved to: %s\n", out_file))
cat(sprintf("Output dir: %s\n", out_target))
