# Load the package from the current directory (Local Development)
devtools::load_all(".")

# Define paths relative to the project root
patch_path <- paste0(dirname(getwd()), "/rSTEMMUS_SCOPE/")

library(tidyverse)
library(utils)
library(formattable)
library(lubridate)

# Define paths and configuration relative to the project root
patch_path <- paste0(dirname(getwd()), "/rSTEMMUS_SCOPE/")
site <- "DE-STG"
run <- "Test_FIXED_TempSMC_3d_Zerorain_OCTAVE" 
start_time <- "2019-01-01T00:00"
end_time <- "2019-01-03T23:00"

# Load Steglitz input data
if (file.exists("2026Contributions/EC_DWD_ROTH_clean.rds")) {
  steg_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
} else {
  steg_df <- readRDS("EC_DWD_ROTH_clean.rds")
}

# Filter data to match simulation period
steg_df <- steg_df %>% 
  filter(timestamp >= as.POSIXct(start_time, format="%Y-%m-%dT%H:%M", tz="UTC"),
         timestamp <= as.POSIXct(end_time, format="%Y-%m-%dT%H:%M", tz="UTC"))

steg_df$t_ <- strptime(steg_df$timestamp, "%Y-%m-%d %H:%M:%S", tz = "UTC")$hour/24
steg_df$t_[is.na(steg_df$t_)==TRUE] <- 0
steg_df$t_ <- steg_df$t_ + lubridate::yday(steg_df$timestamp)

# Create time-series input list
ts_steglitz <- tibble(
  t_ = steg_df$t_,
  timestamp = steg_df$timestamp,
  Rin_sun = steg_df$Rin,
  Rli_ = steg_df$Rli,
  p_ = steg_df$p,
  Ta_ = steg_df$Ta,
  RH_ = steg_df$RH,
  ea_ = steg_df$ea,
  u_ = steg_df$ws,
  rain_ = rep(0, nrow(steg_df)), # SET TO ZERO AS REQUESTED
  LAI_ = steg_df$LAI_FP,
  co2 = steg_df$co2_flux
)

# Compute VPD in hPa directly
Ta <- ts_steglitz$Ta_
RH <- ts_steglitz$RH_

es_hPa <- 6.107 * 10^((7.5 * Ta) / (237.3 + Ta))  # saturation vapor pressure in hPa
ts_steglitz$VPD_ <- es_hPa * (1 - RH / 100)       # VPD in hPa

ts_steglitz$rain_[is.na(ts_steglitz$rain_)==T] <- 0

Ta <- ts_steglitz$Ta_             # °C
ea <- ts_steglitz$ea_ / 10        # convert hPa → kPa
es <- 0.6108 * exp((17.27 * Ta) / (Ta + 237.3))
ts_steglitz$VPD_ <- es - ea       # kPa

# Prepare the input data folder
new_run(
  patch = patch_path,
  StartTime = start_time,
  EndTime = end_time,
  site_name = site,
  run_name = run,
  output_name = format(Sys.time(), "%Y%b%d_%H%M%S")
)

info_IGBP_classes()

# Initial conditions from first row of data
init_row <- steg_df[1, ]

input_constants(
  patch = patch_path,
  site_name = site,
  run_name = run,
  LAT = 52.456,
  LON = 13.323,
  elevation = 50,  # approximate
  IGBP_veg_long = "Closed Shrublands",
  hc = 5,
  n_timestamps = length(ts_steglitz$t_),
  timestep_min = 60,
  initial_soil_temperature = data.frame(
    skt = init_row$soil_temp10cm + 273.15,   # °C → K (input_constants expects Kelvin)
    stl1 = init_row$soil_temp10cm + 273.15,  # °C → K
    stl2 = init_row$soil_temp20cm + 273.15,  # °C → K
    stl3 = init_row$soil_temp30cm + 273.15,  # °C → K
    stl4 = init_row$soil_temp50cm + 273.15   # °C → K
  ),
  initial_volumetric_soil_water = data.frame(
    swvl1 = init_row$SMC_10cm / 100,  # Convert % to m³/m³
    swvl2 = init_row$SMC_20cm / 100,  # Convert % to m³/m³
    swvl3 = init_row$SMC_30cm / 100,  # Convert % to m³/m³
    swvl4 = init_row$SMC_60cm / 100   # Convert % to m³/m³
  ),
  startDOY = 1,
  endDOY = 365,
  timezn = 1,
  setoptions = c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1)
)

# --- Improved VPD calculation using standard method ---
Ta <- ts_steglitz$Ta_             # Air temperature in °C
ea <- ts_steglitz$ea_ / 10        # Convert from hPa to kPa
es <- 0.6108 * exp((17.27 * Ta) / (Ta + 237.3))
ts_steglitz$VPD_ <- es - ea

# Ensure all inputs are numeric vectors with no NA, Inf, or wrong type
ts_steglitz$Rin_sun <- as.numeric(ts_steglitz$Rin_sun)
ts_steglitz$Rli_    <- as.numeric(ts_steglitz$Rli_)
ts_steglitz$p_      <- as.numeric(ts_steglitz$p_)
ts_steglitz$Ta_     <- as.numeric(ts_steglitz$Ta_)
ts_steglitz$RH_     <- as.numeric(ts_steglitz$RH_)
ts_steglitz$ea_     <- as.numeric(ts_steglitz$ea_)
ts_steglitz$u_      <- as.numeric(ts_steglitz$u_)
ts_steglitz$rain_   <- as.numeric(ts_steglitz$rain_)
ts_steglitz$VPD_    <- as.numeric(ts_steglitz$VPD_)

input_timeseries(
  patch = patch_path,
  site_name = site,
  run_name = run,
  t_file = ts_steglitz$t_,
  year_file = year(ts_steglitz$timestamp),
  Rin_file = ts_steglitz$Rin_sun,
  Rli_file = ts_steglitz$Rli_,
  p_file = ts_steglitz$p_,
  Ta_file = ts_steglitz$Ta_,
  RH_file = ts_steglitz$RH_,
  ea_file = ts_steglitz$ea_,
  VPD_file = ts_steglitz$VPD_,
  u_file = ts_steglitz$u_,
  rain_file = ts_steglitz$rain_,
  LAI_file  = ts_steglitz$LAI_,
  CO2_file = rep(415, length(ts_steglitz$t_))
)

run_inMATLAB(
  patch = patch_path,
  site_name = site,
  run_name = run,
  exe_method = "octave"
)
