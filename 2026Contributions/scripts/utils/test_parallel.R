# test_parallel.R
# Smoke test to ensure parallel execution handles Octave isolation perfectly

# Load the package from the current directory (Local Development)
devtools::load_all(".")

library(tidyverse)
library(utils)
library(lubridate)
library(parallel) # For mclapply

patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
site <- "DE-STG"
start_time <- "2019-01-01T00:00"
end_time <- "2019-01-01T23:00" # Just 1 day (24 steps)

# 1. Load data once
if (file.exists("2026Contributions/EC_DWD_ROTH_clean.rds")) {
  steg_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
} else {
  steg_df <- readRDS("EC_DWD_ROTH_clean.rds")
}

steg_df <- steg_df %>% 
  filter(timestamp >= as.POSIXct(start_time, format="%Y-%m-%dT%H:%M", tz="UTC"),
         timestamp <= as.POSIXct(end_time, format="%Y-%m-%dT%H:%M", tz="UTC"))

steg_df$t_ <- strptime(steg_df$timestamp, "%Y-%m-%d %H:%M:%S", tz = "UTC")$hour/24
steg_df$t_[is.na(steg_df$t_)==TRUE] <- 0
steg_df$t_ <- steg_df$t_ + lubridate::yday(steg_df$timestamp)

# Calculate VPD
Ta <- steg_df$Ta
RH <- steg_df$RH
es_hPa <- 6.107 * 10^((7.5 * Ta) / (237.3 + Ta))
VPD_val <- es_hPa * (1 - RH / 100)

ts_base <- tibble(
  t_ = steg_df$t_,
  timestamp = steg_df$timestamp,
  Rin_sun = as.numeric(steg_df$Rin),
  Rli_ = as.numeric(steg_df$Rli),
  p_ = as.numeric(steg_df$p),
  Ta_ = as.numeric(steg_df$Ta),
  RH_ = as.numeric(steg_df$RH),
  ea_ = as.numeric(steg_df$ea),
  u_ = as.numeric(steg_df$ws),
  rain_ = as.numeric(ifelse(is.na(steg_df$prec_mm_EC), 0, steg_df$prec_mm_EC/36000)),
  LAI_ = as.numeric(steg_df$LAI_FP),
  co2 = as.numeric(steg_df$co2_flux),
  VPD_ = as.numeric(VPD_val)
)

init_row <- steg_df[1, ]

# 2. Define the worker function that sets up and runs a simulation
run_simulation <- function(i) {
  run_name <- paste0("Test_Parallel_LAI_Multiplier_", i)
  
  # Adjust LAI to create 5 distinct scenarios
  ts_sim <- ts_base
  ts_sim$LAI_ <- ts_sim$LAI_ * (0.5 + 0.5 * i) # e.g., 1x, 1.5x, 2.0x, 2.5x, 3.0x
  
  # Create directory
  new_run(
    patch = patch_path,
    StartTime = start_time,
    EndTime = end_time,
    site_name = site,
    run_name = run_name,
    output_name = paste0(run_name, "_OUT")
  )
  
  # Set Constants
  input_constants(
    patch = patch_path,
    site_name = site,
    run_name = run_name,
    LAT = 52.456, LON = 13.323, elevation = 50,
    IGBP_veg_long = "Closed Shrublands",
    hc = 5,
    n_timestamps = length(ts_sim$t_), timestep_min = 60,
    initial_soil_temperature = data.frame(
      skt = init_row$soil_temp10cm + 273.15,
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
    startDOY = 1, endDOY = 365, timezn = 1,
    setoptions = c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1)
  )
  
  # Set Timeseries
  input_timeseries(
    patch = patch_path,
    site_name = site,
    run_name = run_name,
    t_file = ts_sim$t_, year_file = year(ts_sim$timestamp),
    Rin_file = ts_sim$Rin_sun, Rli_file = ts_sim$Rli_,
    p_file = ts_sim$p_, Ta_file = ts_sim$Ta_,
    RH_file = ts_sim$RH_, ea_file = ts_sim$ea_,
    VPD_file = ts_sim$VPD_, u_file = ts_sim$u_,
    rain_file = ts_sim$rain_, LAI_file  = ts_sim$LAI_,
    CO2_file = rep(415, length(ts_sim$t_))
  )
  
  cat(sprintf("[Sim %d] Starting execution...\n", i))
  # Run execution
  res <- tryCatch({
    run_inMATLAB(
      patch = patch_path,
      site_name = site,
      run_name = run_name,
      exe_method = "octave"
    )
    "SUCCESS"
  }, error = function(e) { e$message })
  
  cat(sprintf("[Sim %d] Finished with status: %s\n", i, res))
  return(list(run_name=run_name, status=res))
}

# 3. Run in parallel using 5 cores
cat("Launching 5 parallel jobs...\n")
start_job <- Sys.time()
results <- mclapply(1:5, run_simulation, mc.cores = 5)
end_job <- Sys.time()

cat("\n==============================\n")
cat("Parallel Run Summary\n")
cat("Total Time:", round(as.numeric(difftime(end_job, start_job, units = "mins")), 2), "minutes\n")
for (res in results) {
  cat("Run:", res$run_name, " | Status:", res$status, "\n")
}
cat("==============================\n")
