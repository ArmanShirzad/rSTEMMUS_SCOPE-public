devtools::install_github("EcoExtreML/rSTEMMUS_SCOPE")
library(rSTEMMUSSCOPE)

initial_setup()

run_inMATLAB(patch = "D:/model/rSTEMMUS_SCOPE/",
             site_name = "AR-SLu",
             run_name = "2024-01-25-0911")

#download_SoilProperty

# roadmap_12_5_steglitz.R
# Simulate soil moisture for Steglitz using STEMMUS-SCOPE model

setwd('D:/R_projects/STEMMUS.SCOPE')

# Load required libraries
library(rSTEMMUS.SCOPE)
library(tidyverse)
library(utils)
library(formattable)
library(lubridate)

#Mdata <- tibble(read.table("D:/model/rSTEMMUS_SCOPE/runs/DE-STG_Test3_Steglitz/Mdata.txt"))
#summary(Mdata)

0# Define paths and configuration
patch_path <- "D:/model/rSTEMMUS_SCOPE/"
site <- "DE-STG"
run <- "Test_pre_mm_Steglitz"########### 
start_time <- "2019-01-01T00:00"
end_time <- "2020-12-31T23:00"


# Load Steglitz input data
steg_df <- readRDS("EC_DWD_ROTH_clean.rds")
dir()
names(steg_df)
steg_df$t_ <- strptime(steg_df$timestamp, "%Y-%m-%d %H:%M:%S", tz = "UTC")$hour/24
steg_df$t_[is.na(steg_df$t_)==TRUE] <- 0
steg_df$t_ <- steg_df$t_ + lubridate::yday(steg_df$timestamp)

summary(steg_df$prec_mm)

00# Create time-series input list
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
  rain_ = steg_df$prec_mm_EC/36000,
  LAI_ = steg_df$LAI_FP,
  co2 = steg_df$co2_flux,
  VPD_ = (steg_df$ea / 10) - (steg_df$RH / 100)  # estimate if not directly available
)
summary(ts_steglitz$VPD_)

# Compute VPD in hPa directly
Ta <- ts_steglitz$Ta_
RH <- ts_steglitz$RH_

es_hPa <- 6.107 * 10^((7.5 * Ta) / (237.3 + Ta))  # saturation vapor pressure in hPa
ts_steglitz$VPD_ <- es_hPa * (1 - RH / 100)       # VPD in hPa







#summary(steg_df$prec_mm_EC/36000)
#summary(steg_df$prec_mm/36000)

ts_steglitz$rain_[is.na(ts_steglitz$rain_)==T] <- 0
summary(ts_steglitz$rain_)

Ta <- ts_steglitz$Ta_             # °C
ea <- ts_steglitz$ea_ / 10        # convert hPa → kPa
es <- 0.6108 * exp((17.27 * Ta) / (Ta + 237.3))
ts_steglitz$VPD_ <- es - ea       # kPa

summary(ts_steglitz)



# Use original site for soil properties (until real values are available)
#Soil_property_steglitz <- get_SoilProperties(
#  patch = file.path(patch_path, "input/input_for_input/SoilProperty/"),
#  lon = 13.31583,
#  lat = 52.45723
#)

1# Prepare the input data folder
new_run(
  patch = patch_path,
  StartTime = start_time,
  EndTime = end_time,
  site_name = site,
  run_name = run,
  output_name = format(Sys.time(), "%Y%b%d_%H%M")
)

info_IGBP_classes()

# Initial conditions from first row of data
init_row <- steg_df[1, ]

2# Set static inputs
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
    skt = init_row$soil_temp10cm,
    stl1 = init_row$soil_temp10cm,
    stl2 = init_row$soil_temp20cm,
    stl3 = init_row$soil_temp30cm,
    stl4 = init_row$soil_temp50cm
  ),
  initial_volumetric_soil_water = data.frame(
    swvl1 = init_row$SMC_10cm,
    swvl2 = init_row$SMC_20cm,
    swvl3 = init_row$SMC_30cm,
    swvl4 = init_row$SMC_60cm
  ),
  soil_property_list = Soil_property_steglitz,
  startDOY = 1,
  endDOY = 365,
  timezn = 1,
  setoptions = c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1)
)
# --- Improved VPD calculation using standard method ---
Ta <- ts_steglitz$Ta_             # Air temperature in °C
ea <- ts_steglitz$ea_ / 10        # Convert from hPa to kPa

# Saturation vapor pressure (es) in kPa
es <- 0.6108 * exp((17.27 * Ta) / (Ta + 237.3))

# Vapor Pressure Deficit (VPD) in kPa
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

###
check_ts_inputs <- function(ts_list) {
  cat("Checking time-series input integrity:\n")
  n <- length(ts_list$t_)
  for (name in names(ts_list)) {
    cat(sprintf(" - %s: length = %d | NAs = %d | Infs = %d | Class = %s\n",
                name,
                length(ts_list[[name]]),
                sum(is.na(ts_list[[name]])),
                sum(is.infinite(ts_list[[name]])),
                class(ts_list[[name]])[1]))
    if (length(ts_list[[name]]) != n) {
      cat(sprintf("   ❗ Length mismatch (expected %d)\n", n))
    }
  }
}

check_ts_inputs(ts_steglitz)
trace(set_ts_inputs, quote(print(match.call())), print = TRUE)


Ta <- ts_steglitz$Ta_             # °C
ea <- ts_steglitz$ea_ / 10        # convert hPa → kPa
es <- 0.6108 * exp((17.27 * Ta) / (Ta + 237.3))
ts_steglitz$VPD_ <- es - ea       # kPa

summary(ts_steglitz)


3# Set time-series inputs
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
  CO2_file = rep(415,17544)

)

summary(ts_steglitz$rain_/36000)


4#####
run_inMATLAB(
  patch = patch_path,
  site_name = site,
  run_name = run
)


