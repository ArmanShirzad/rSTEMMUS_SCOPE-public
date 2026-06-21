## ═══════════════════════════════════════════════════════════════════════════
## run_TUCC_2yr_OCTAVE_realSTL.R — TUCC 2yr Octave with real ERA5 soil temps
## ═══════════════════════════════════════════════════════════════════════════
## Same as run_TUCC_2yr_OCTAVE.R but the initial soil-temperature condition
## comes from ERA5-Land STL1/2/3/4 .nc files (Jan 1 2019 00:00) instead of
## air-temperature proxy. All other inputs unchanged.
##
## Inputs:
##   2026Contributions/2026Contributions/era5/era5land_stl{1..4}_2019_Q1.nc
##   2026Contributions/EC_DWD_TUCC_clean.rds
##
## DATE: 2026-06-12
## ═══════════════════════════════════════════════════════════════════════════

suppressPackageStartupMessages({
  devtools::load_all(".")
  library(tidyverse); library(lubridate); library(terra)
})

# ── Configuration ────────────────────────────────────────────────────────────
exe_method <- "octave"
patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
site <- "TUCC"
run  <- paste0("TUCC_2yr_realSTL_", toupper(exe_method))
start_time <- "2019-01-01T00:00"
end_time   <- "2020-12-31T23:00"

cat("\n════════════════════════════════════════════════════════════════\n")
cat(sprintf("  TUCC 2-Year Run with REAL ERA5 soil temperatures [%s]\n", toupper(exe_method)))
cat(sprintf("  Period: %s to %s\n", start_time, end_time))
cat("════════════════════════════════════════════════════════════════\n\n")

# ── Read ERA5 STL Jan 1 2019 00:00 UTC values (first timestep of each Q1 file) ──
era5_dir <- "2026Contributions/2026Contributions/era5"
read_stl_t0 <- function(nc_path) {
  r <- rast(nc_path)
  vals <- values(r[[1]])             # first timestep = 2019-01-01 00:00 UTC
  k    <- mean(vals, na.rm = TRUE)    # spatial mean over the small TUCC box
  c    <- k - 273.15
  list(K = k, C = c, file = nc_path)
}
stl1 <- read_stl_t0(file.path(era5_dir, "era5land_stl1_2019_Q1.nc"))
stl2 <- read_stl_t0(file.path(era5_dir, "era5land_stl2_2019_Q1.nc"))
stl3 <- read_stl_t0(file.path(era5_dir, "era5land_stl3_2019_Q1.nc"))
stl4 <- read_stl_t0(file.path(era5_dir, "era5land_stl4_2019_Q1.nc"))

cat("→ ERA5-Land soil temperatures at 2019-01-01 00:00 UTC (TUCC box):\n")
cat(sprintf("  STL1 (0-7 cm)     : %6.2f K = %5.2f °C\n", stl1$K, stl1$C))
cat(sprintf("  STL2 (7-28 cm)    : %6.2f K = %5.2f °C\n", stl2$K, stl2$C))
cat(sprintf("  STL3 (28-100 cm)  : %6.2f K = %5.2f °C\n", stl3$K, stl3$C))
cat(sprintf("  STL4 (100-289 cm) : %6.2f K = %5.2f °C\n", stl4$K, stl4$C))

# ── Load Observation Data ────────────────────────────────────────────────────
tucc_df <- readRDS("2026Contributions/EC_DWD_TUCC_clean.rds") %>%
  filter(timestamp >= as.POSIXct(start_time, format="%Y-%m-%dT%H:%M", tz="UTC"),
         timestamp <= as.POSIXct(end_time,   format="%Y-%m-%dT%H:%M", tz="UTC"))
cat(sprintf("\nLoaded %d TUCC timesteps\n", nrow(tucc_df)))

# Time vector
tucc_df$t_ <- yday(tucc_df$timestamp) + hour(tucc_df$timestamp)/24 +
              minute(tucc_df$timestamp)/1440
tucc_df$t_[is.na(tucc_df$t_)] <- 0

ts_input <- tibble(
  t_ = tucc_df$t_, timestamp = tucc_df$timestamp,
  Rin_sun = as.numeric(tucc_df$Rin), Rli_ = as.numeric(tucc_df$Rli),
  p_ = as.numeric(tucc_df$p),         Ta_ = as.numeric(tucc_df$Ta),
  RH_ = as.numeric(tucc_df$RH),       ea_ = as.numeric(tucc_df$ea),
  u_  = as.numeric(tucc_df$ws),
  rain_ = as.numeric(ifelse(is.na(tucc_df$prec_mm_EC), 0, tucc_df$prec_mm_EC/36000)),
  LAI_  = as.numeric(tucc_df$LAI_FP), co2 = as.numeric(tucc_df$co2_flux)
)
Ta <- ts_input$Ta_; ea <- ts_input$ea_/10
es <- 0.6108 * exp((17.27*Ta)/(Ta+237.3))
ts_input$VPD_ <- as.numeric(es - ea)
ts_input$rain_[is.na(ts_input$rain_)] <- 0

init_row <- tucc_df[1, ]

# ── Create run dir + soil properties ─────────────────────────────────────────
out_timestamp <- format(Sys.time(), "%Y%b%d_%H%M")
new_run(patch=patch_path, StartTime=start_time, EndTime=end_time,
        site_name=site, run_name=run, output_name=out_timestamp)

cat("\n→ Loading TUCC soil properties (Van Genuchten parameters)...\n")
Soil_property_tucc <- get_SoilProperties(
  patch = file.path(patch_path, "input/SoilProperty/"),
  lon = 13.33, lat = 52.51
)
cat(sprintf("  porosity[1]=%.4f  Ks[1]=%.6f  n[1]=%.4f\n",
            Soil_property_tucc$porosity[1],
            Soil_property_tucc$SaturatedK[1],
            Soil_property_tucc$Coefficient_n[1]))

# ── input_constants() with REAL STLs (in Kelvin, as input_constants expects) ─
input_constants(
  patch=patch_path, site_name=site, run_name=run,
  LAT=52.51, LON=13.33, elevation=36,
  IGBP_veg_long="Closed Shrublands", hc=5,
  n_timestamps=length(ts_input$t_), timestep_min=60,
  initial_soil_temperature = data.frame(
    skt  = stl1$K,    # skin ~ shallow soil
    stl1 = stl1$K,    # 0-7 cm
    stl2 = stl2$K,    # 7-28 cm
    stl3 = stl3$K,    # 28-100 cm
    stl4 = stl4$K     # 100-289 cm
  ),
  initial_volumetric_soil_water = data.frame(
    swvl1 = init_row$SMC20/100,
    swvl2 = init_row$SMC40/100,
    swvl3 = init_row$SMC60/100,
    swvl4 = init_row$SMC60/100
  ),
  soil_property_list = Soil_property_tucc,
  startDOY=1, endDOY=731, timezn=1,
  setoptions=c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1)
)
cat("  ✓ input_constants() set with ERA5 STL Kelvin values\n")

# ── Timeseries inputs ────────────────────────────────────────────────────────
input_timeseries(
  patch=patch_path, site_name=site, run_name=run,
  t_file=ts_input$t_, year_file=year(ts_input$timestamp),
  Rin_file=ts_input$Rin_sun, Rli_file=ts_input$Rli_,
  p_file=ts_input$p_, Ta_file=ts_input$Ta_,
  RH_file=ts_input$RH_, ea_file=ts_input$ea_,
  VPD_file=ts_input$VPD_, u_file=ts_input$u_,
  rain_file=ts_input$rain_, LAI_file=ts_input$LAI_,
  CO2_file=rep(415, length(ts_input$t_))
)

# ── Launch ───────────────────────────────────────────────────────────────────
cat("\n════════════════════════════════════════════════════════════════\n")
cat(sprintf("  Starting 2-Year %s Simulation — TUCC with real ERA5 STLs\n",
            toupper(exe_method)))
cat(sprintf("  Run label: %s\n", run))
cat("  Initial soil T: ERA5-Land STL1-4 at 2019-01-01 00:00 ✓\n")
cat("════════════════════════════════════════════════════════════════\n\n")

t0 <- Sys.time()
run_inMATLAB(patch=patch_path, site_name=site, run_name=run, exe_method=exe_method)
elapsed <- difftime(Sys.time(), t0, units="hours")
cat(sprintf("\n✓ %s simulation completed in %.1f hours\n",
            toupper(exe_method), as.numeric(elapsed)))

out_target <- paste0(patch_path, "output/", site, "_", run, "_", out_timestamp)
out_file <- "2026Contributions/logs/latest_TUCC_2yr_realSTL_octave_output_dir.txt"
dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
writeLines(out_target, out_file)
cat(sprintf("Output dir saved to: %s\n", out_file))
cat(sprintf("Output dir: %s\n", out_target))
