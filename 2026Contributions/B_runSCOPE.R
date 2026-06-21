library(rSCOPE)
library("svMisc")

# #####################################################################################################
# ## run SCOPE with the EC data - ROTH
summary(EC_ROTH_SCOPE)

# 6 versions
# SMC = NA, LAI = NA, hc = NA, soilspectrum = 0, hc_c = 2,
# SMC = NA, LAI = NA, hc = NA, soilspectrum = 1, hc_c = 2,
# SMC = "SMC60_EC", LAI = NA, hc = NA, soilspectrum = 1, hc_c = 2,
# SMC = "SMC60", LAI = NA, hc = NA, soilspectrum = 1, hc_c = 2,
# SMC = "SMC60", LAI = LAI, hc = hc_vh, soilspectrum = 1, hc_c = 2,
# SMC = "SMC60", LAI = LAI_max, hc = NA, soilspectrum = 1, hc_c = 25,

summary(EC_ROTH_SCOPE)

run_SCOPE(csv_inputs = EC_ROTH_SCOPE,
          Simulation_Name = "EC_ROTH_",
          split = FALSE,
          # variable names
          t = "t", Rin = "Rin_EC", Rli = "Rli_EC", p = "p_EC", Ta = "Ta_EC", RH = "RH_EC", ea = NA, u = "ws_EC",
          tts = "tts", tto = NA, psi = NA, SMC = "SMC60_DWD", LAI = "LAI_max", hc = NA,
          ### constants values (non-default)
          hc_c = 25,
          LAI_c = 3,
          SMC_c = 25,
          # Ca_c = 410,
          z_c = 40, # measurements height
          LAT = 52.45, 
          LON = 13.32, 
          timezn = 0,   # Lat/long and time zone
          startDOY = 20190101,
          endDOY = 20210101,  # timestamp period (endDOY should be one day after)
          ### settings values (non-default)
          lite = 1, # faster
          simulation = 1, # time series
          soilspectrum = 1, 
          soil_heat_method = 1, # soil options
          applTcorr = 1,  
          MoninObukhov = 0, 
          calc_rss_rbs = 0, # corrections
          save_spectral = 0,
          calc_fluor = 0,
          calc_planck = 0,
          calc_xanthophyllabs = 0,
          Fluorescence_model = 0,
          calc_directional = 0, # very time demanding
          calc_vert_profiles = 0)

# ## run SCOPE with the EC data - TUCC
summary(EC_TUCC_SCOPE)

# 5 versions
# SMC = NA, LAI = NA, hc = NA, soilspectrum = 0, hc_c = 2,
# SMC = NA, LAI = NA, hc = NA, soilspectrum = 1, hc_c = 2,
# SMC = "SMC60_DWD", LAI = NA, hc = NA, soilspectrum = 1, hc_c = 2,
# SMC = "SMC60_DWD", LAI = "LAI_FP", hc = "hc_vh", soilspectrum = 1, hc_c = 2,
# SMC = "SMC60_DWD", LAI = "LAI_max", hc = NA, soilspectrum = 1, hc_c = 25,

run_SCOPE(csv_inputs = EC_TUCC_SCOPE,
          Simulation_Name = "EC_TUCC_",
          split = FALSE,
          # variable names
          t = "t", Rin = "Rin_EC", Rli = "Rli_EC", p = "p_EC", Ta = "Ta_EC", RH = "RH_EC", ea = NA, u = "ws_EC",
          tts = "tts", tto = NA, psi = NA, SMC = "SMC60_DWD", LAI = "LAI_FP", hc = "hc_vh",
          ### constants values (non-default)
          hc_c = 25,
          # LAI_c = 3,
          # SMC_c = 50,
          # Ca_c = 417,
          z_c = 56, # measurements height
          LAT = 52.51, # Lat/long
          LON = 13.33,
          timezn = 0,  # time zone 0 or 1 is the same if tts is provided
          startDOY = 20190101,
          endDOY = 20210101,  # timestamp period (endDOY should be one day after)
          ### settings values (non-default)
          lite = 1, # faster
          simulation = 1, # time series
          soilspectrum = 1, 
          soil_heat_method = 1, # soil options
          applTcorr = 1,  
          MoninObukhov = 0, 
          calc_rss_rbs = 0, # corrections
          save_spectral = 0,
          calc_fluor = 0,
          calc_planck = 0,
          calc_xanthophyllabs = 0,
          Fluorescence_model = 0,
          calc_directional = 0, # very time demanding
          calc_vert_profiles = 0)

# #####################################################################################################

####################################################################################################
# ## run SCOPE with the DWD data - ROTH
summary(EC_ROTH_SCOPE)
# 2 versions
# SMC = "SMC60_DWD", LAI = LAI_FP, hc = hc_vh, soilspectrum = 1, hc_c = 2,
# SMC = "SMC60_DWD", LAI = LAI_max, hc = NA, soilspectrum = 1, hc_c = 25,

run_SCOPE(csv_inputs = EC_ROTH_SCOPE,
          Simulation_Name = "DWD_ROTH_",
          split = FALSE,
          # variable names
          t = "t", Rin = "Rin_DWD", Rli = "Rli_DWD", p = "p_DWD", Ta = "Ta_DWD", RH = "RH_DWD", 
          ea = NA, u = "ws_DWD", tts = "tts", tto = NA, psi = NA, 
          SMC = "SMC60_DWD", LAI = "LAI_max", hc = NA,
          ### constants values (non-default)
          hc_c = 25,
          LAI_c = 3,
          SMC_c = 25,
          # Ca_c = 410,
          z_c = 40, # measurements height
          LAT = 52.45, 
          LON = 13.32, 
          timezn = 0,   # Lat/long and time zone
          startDOY = 20190101,
          endDOY = 20210101,  # timestamp period (endDOY should be one day after)
          ### settings values (non-default)
          lite = 1, # faster
          simulation = 1, # time series
          soilspectrum = 1, 
          soil_heat_method = 1, # soil options
          applTcorr = 1,  
          MoninObukhov = 0, 
          calc_rss_rbs = 0, # corrections
          save_spectral = 0,
          calc_fluor = 0,
          calc_planck = 0,
          calc_xanthophyllabs = 0,
          Fluorescence_model = 0,
          calc_directional = 0, # very time demanding
          calc_vert_profiles = 0)

# 2 versions
# SMC = "SMC60_DWD", LAI = "LAI_FP", hc = "hc_vh", soilspectrum = 1, hc_c = 2,
# SMC = "SMC60_DWD", LAI = "LAI_max", hc = NA, soilspectrum = 1, hc_c = 25,

run_SCOPE(csv_inputs = EC_TUCC_SCOPE,
          Simulation_Name = "DWD_TUCC_",
          split = FALSE,
          # variable names
          # variable names
          t = "t", Rin = "Rin_DWD", Rli = "Rli_DWD", p = "p_DWD", Ta = "Ta_DWD", RH = "RH_DWD", 
          ea = NA, u = "ws_DWD", tts = "tts", tto = NA, psi = NA, 
          SMC = "SMC60_DWD", LAI = "LAI_max", hc = NA,
          ### constants values (non-default)
          hc_c = 25,
          # LAI_c = 3,
          # SMC_c = 50,
          # Ca_c = 417,
          z_c = 56, # measurements height
          LAT = 52.51, # Lat/long
          LON = 13.33,
          timezn = 0,  # time zone 0 or 1 is the same if tts is provided
          startDOY = 20190101,
          endDOY = 20210101,  # timestamp period (endDOY should be one day after)
          ### settings values (non-default)
          lite = 1, # faster
          simulation = 1, # time series
          soilspectrum = 1, 
          soil_heat_method = 1, # soil options
          applTcorr = 1,  
          MoninObukhov = 0, 
          calc_rss_rbs = 0, # corrections
          save_spectral = 0,
          calc_fluor = 0,
          calc_planck = 0,
          calc_xanthophyllabs = 0,
          Fluorescence_model = 0,
          calc_directional = 0, # very time demanding
          calc_vert_profiles = 0)

####################################################################################################


#####################################################################################################
# Forest types - the same for TUCC and ROTH
# 12 versions
1 # Simulation_Name = "Forest_average", hc_c = 25, LAI = "LAI_max",
2 # Simulation_Name = "Forest_average_LAIav", hc_c = 4.8, LAI = "LAI",
3 # Simulation_Name = "Forest_LAI_forest_max", hc_c = 33.1, LAI = "max_forest",
4 # Simulation_Name = "Forest_LAI_forest_mean", hc_c = 17.7, LAI = "mean_forest",
5 # Simulation_Name = "Forest_LAI_raster_max", hc_c = 40, LAI = "max_raster",
6 # Simulation_Name = "Forest_LAI_raster_mean", hc_c = 14, LAI = "mean_raster",
7 # Simulation_Name = "Forest_LAI_beech_max", hc_c = 29.7, LAI = "max_Beech",
8 # Simulation_Name = "Forest_LAI_beech_mean", hc_c = 19.6, LAI = "mean_Beech",
9 # Simulation_Name = "Forest_LAI_oak_max", hc_c = 26.3, LAI = "max_oak",
10 # Simulation_Name = "Forest_LAI_oak_mean", hc_c = 16.8, LAI = "mean_oak",
11 # Simulation_Name = "Forest_LAI_pine_max", hc_c = 23.5, LAI = "max_Pine",
12 # Simulation_Name = "Forest_LAI_pine_mean", hc_c = 14.2, LAI = "mean_Pine",

run_SCOPE(csv_inputs = Inputs_forest,            
          Simulation_Name = "Forest_LAI_pine_mean", hc_c = 14.2, LAI = "mean_Pine",
          split = FALSE,
          t = "t", # time BerkeleyJulianDate  
          Rin = "Rin", Rli = "Rli", 
          p = "p", Ta = "Ta", RH = "RH", ea = NA, 
          u = "ws", # atmosphere conditions
          tts = "tts", tto = NA, psi = NA,
          SMC = "SMC60",
          hc = NA,
          z_c = 40,
          startDOY = 20181201, endDOY = 20210130,  # timestamp period
          LAT = 52.5, LON = 13.32, timezn = 0,   # Lat/long and time zone
          lite = 1,
          soilspectrum = 1, 
          applTcorr = 1, 
          soil_heat_method = 1, 
          calc_rss_rbs = 0, 
          MoninObukhov = 0)
####################################################################################################


# Grid per pixel 
####################################################################################################
# - FP version
print(Inputs_Berlin_19, n = 9000)$id_pixel
Inputs_Berlin_19$split_55 <- c(rep(seq(1:54), each = 20*8760), rep(55, 148920))

split_20pixels <- 1:55
n_split = 55

for (i in 1:55) {
  run_SCOPE(csv_inputs = Inputs_Berlin_19,
            Simulation_Name = paste0("FP_pixels", i),
            split = TRUE,
            col_split = "split_55", #dataset_for_verification
            split_values = split_20pixels[i],
            t = "t", # time BerkeleyJulianDate  
            Rin = "Rin", Rli = "Rli", 
            p = "p", Ta = "Ta", RH = "RH", ea = NA, 
            u = "ws", # atmosphere conditions
            tts = "tts", tto = NA, psi = NA,
            SMC = "SMC60",
            LAI = "LAI", 
            hc = "hc_vh",
            z_c = 40,
            startDOY = 20181201, endDOY = 20200130,  # timestamp period
            LAT = 52.5, LON = 13.32, timezn = 0,   # Lat/long and time zone
            lite = 1,
            soilspectrum = 1, 
            applTcorr = 1, 
            soil_heat_method = 1, 
            calc_rss_rbs = 0, 
            MoninObukhov = 0)
  progress(i, n, progress.bar = TRUE, init = T)
  Sys.sleep(240) # time delay in seconds - 1 hour
  if (i == n) message("Done!")
}

# - Forest version
n2 = 55
#
for (i in 1:55) {
  run_SCOPE(csv_inputs = Inputs_Berlin_19,
            Simulation_Name = paste0("Forest_pixels_", i),
            split = TRUE,
            col_split = "split_55", #dataset_for_verification
            split_values = split_20pixels[i],
            t = "t", # time BerkeleyJulianDate  
            Rin = "Rin", Rli = "Rli", 
            p = "p", Ta = "Ta", RH = "RH", ea = NA, 
            u = "ws", # atmosphere conditions
            tts = "tts", tto = NA, psi = NA,
            SMC = "SMC60",
            LAI = "LAI_max", 
            hc = NA,
            hc_c = 25,
            z_c = 40,
            startDOY = 20181201, endDOY = 20200130,  # timestamp period
            LAT = 52.5, LON = 13.32, timezn = 0,   # Lat/long and time zone
            lite = 1,
            soilspectrum = 1, 
            applTcorr = 1, 
            soil_heat_method = 1, 
            calc_rss_rbs = 0, 
            MoninObukhov = 0)
  progress(i, n, progress.bar = TRUE, init = T)
  Sys.sleep(1800) # time delay in seconds - 1 hour
  if (i == n) message("Done!")
}
####################################################################################################






####################################################################################################
# stress scenarios 
####################################################################################################
# ## run SCOPE with the DWD data - ROTH, TUCC and forest 
summary(EC_ROTH_SCOPE)
summary(EC_TUCC_SCOPE)
summary(Inputs_forest)

plot(y=Inputs_forest$SMC60, x=Inputs_forest$id_time)

summary(Inputs_forest)
Inputs_forest$SMC60_d2 <- Inputs_forest$SMC60/2
Inputs_forest$SMC60_d3 <- Inputs_forest$SMC60/3
Inputs_forest$SMC60_m2 <- Inputs_forest$SMC60*2
# EC_TUCC_SCOPE$SMC60_dry_2 <- EC_TUCC_SCOPE$SMC60_DWD/2
# EC_ROTH_SCOPE$SMC60_dry_2 <- EC_ROTH_SCOPE$SMC60_DWD/2

Inputs_forest$Ta_plus1 <- Inputs_forest$Ta + 1
Inputs_forest$Ta_plus2 <- Inputs_forest$Ta + 2
Inputs_forest$Ta_plus3 <- Inputs_forest$Ta + 3
Inputs_forest$Ta_plus4 <- Inputs_forest$Ta + 4

# EC_TUCC_SCOPE$Ta_plus4 <- EC_TUCC_SCOPE$Ta_DWD + 4
# EC_ROTH_SCOPE$Ta_plus4 <- EC_ROTH_SCOPE$Ta_DWD + 4

Inputs_forest$RH_60p <- Inputs_forest$RH * 0.60
Inputs_forest$RH_75p <- Inputs_forest$RH * 0.75
Inputs_forest$RH_90p <- Inputs_forest$RH * 0.90
Inputs_forest$RH_95p <- Inputs_forest$RH * 0.95

# EC_TUCC_SCOPE$RH_75p <- EC_TUCC_SCOPE$RH_DWD * 0.75
# EC_ROTH_SCOPE$RH_75p <- EC_ROTH_SCOPE$RH_DWD * 0.75

# stressfactor = 1 (default), 2, 3, 5 - reduce Vcmax25 as SMC or leaf age
# BallBerrySlope = 8 (default), 6, 4
# SMC_c = 25 (default), 20, 15, 10, 5 and SMC = "SMC60_dry_3"
# Ta + 2C = Ta_plus2 and 4C = Ta_plus4 , 
# Ta_plus4 and RH_75p
# Ta_plus4 and RH_75p and SMC60_dry_2


# 2 versions
# SMC = "SMC60_DWD", LAI = LAI_FP, hc = hc_vh, soilspectrum = 1, hc_c = 2,
# SMC = "SMC60_DWD", LAI = LAI_max, hc = NA, soilspectrum = 1, hc_c = 25,

run_SCOPE(csv_inputs = EC_ROTH_SCOPE,
          Simulation_Name = "Stress_ROTH_SMC",
          split = FALSE,
          # variable names
          t = "t", Rin = "Rin_DWD", Rli = "Rli_DWD", p = "p_DWD", Ta = "Ta_plus4", RH = "RH_75p", 
          ea = NA, u = "ws_DWD", tts = "tts", tto = NA, psi = NA, 
          SMC = "SMC60_dry_2", LAI = "LAI_FP", hc = "hc_vh",
          ### constants values (non-default)
          hc_c = 25,
          LAI_c = 3,
          SMC_c = 5,
          stressfactor = 1,
          BallBerrySlope_c = 8,
          # Ca_c = 410,
          z_c = 40, # measurements height
          LAT = 52.45, 
          LON = 13.32, 
          timezn = 0,   # Lat/long and time zone
          startDOY = 20190101,
          endDOY = 20210101,  # timestamp period (endDOY should be one day after)
          ### settings values (non-default)
          lite = 1, # faster
          simulation = 1, # time series
          soilspectrum = 1, 
          soil_heat_method = 1, # soil options
          applTcorr = 1,  
          MoninObukhov = 0, 
          calc_rss_rbs = 0, # corrections
          save_spectral = 0,
          calc_fluor = 0,
          calc_planck = 0,
          calc_xanthophyllabs = 0,
          Fluorescence_model = 0,
          calc_directional = 0, # very time demanding
          calc_vert_profiles = 0)

# 2 versions
# SMC = "SMC60_DWD", LAI = "LAI_FP", hc = "hc_vh", soilspectrum = 1, hc_c = 2,
# SMC = "SMC60_DWD", LAI = "LAI_max", hc = NA, soilspectrum = 1, hc_c = 25,

run_SCOPE(csv_inputs = EC_TUCC_SCOPE,
          Simulation_Name = "Stress_TUCC_SMC",
          split = FALSE,
          # variable names
          # variable names
          t = "t", Rin = "Rin_DWD", Rli = "Rli_DWD", p = "p_DWD", Ta = "Ta_plus4", RH = "RH_75p", 
          ea = NA, u = "ws_DWD", tts = "tts", tto = NA, psi = NA, 
          SMC = "SMC60_dry_2", LAI = "LAI_FP", hc = "hc_vh",
          ### constants values (non-default)
          hc_c = 25,
          LAI_c = 3,
          SMC_c = 5,
          stressfactor = 1,
          BallBerrySlope_c = 8,
          z_c = 56, # measurements height
          LAT = 52.51, # Lat/long
          LON = 13.33,
          timezn = 0,  # time zone 0 or 1 is the same if tts is provided
          startDOY = 20190101,
          endDOY = 20210101,  # timestamp period (endDOY should be one day after)
          ### settings values (non-default)
          lite = 1, # faster
          simulation = 1, # time series
          soilspectrum = 1, 
          soil_heat_method = 1, # soil options
          applTcorr = 1,  
          MoninObukhov = 0, 
          calc_rss_rbs = 0, # corrections
          save_spectral = 0,
          calc_fluor = 0,
          calc_planck = 0,
          calc_xanthophyllabs = 0,
          Fluorescence_model = 0,
          calc_directional = 0, # very time demanding
          calc_vert_profiles = 0)

####################################################################################################

# Scenarios
#####################################################################################################
# Forest mean

run_SCOPE(csv_inputs = Inputs_forest,
          Simulation_Name = "forest_SMC_sp0_c025", 
          split = FALSE,
          t = "t", # time BerkeleyJulianDate  
          Rin = "Rin", Rli = "Rli", 
          hc_c = 17.7, hc = NA, LAI = "mean_forest",
          p = "p", ea = NA, u = "ws", # atmosphere conditions
          tts = "tts", tto = NA, psi = NA,
          Ta = "Ta", RH = "RH",  
          SMC =  NA, #"SMC60", 
          SMC_c = 0.25,
          stressfactor = 1,
          BallBerrySlope_c = 8,
          z_c = 40,
          startDOY = 20181201, endDOY = 20210130,  # timestamp period
          LAT = 52.5, LON = 13.32, timezn = 0,   # Lat/long and time zone
          lite = 1,
          soilspectrum = 0, 
          applTcorr = 1, 
          soil_heat_method = 1, 
          calc_rss_rbs = 0,
          MoninObukhov = 0)

# grassland 
run_SCOPE(csv_inputs = Inputs_forest,
          Simulation_Name = "grassland_SMC01", 
          split = FALSE,
          t = "t", Rin = "Rin", Rli = "Rli", p = "p", ea = NA, u = "ws", tts = "tts", tto = NA, psi = NA,
          hc_c = 0.10, hc = NA, LAI = "LAI_grass",
          Ta = "Ta", RH = "RH",  
          SMC =  NA, #"SMC60", # 
          SMC_c = 0.01,
          stressfactor = 1,
          BallBerrySlope_c = 8,
          z_c = 40,
          startDOY = 20181201, endDOY = 20210130,  # timestamp period
          LAT = 52.5, LON = 13.32, timezn = 0,   # Lat/long and time zone
          lite = 1,
          soilspectrum = 1, 
          applTcorr = 1, 
          soil_heat_method = 1, 
          calc_rss_rbs = 0,
          MoninObukhov = 0)

# max Hc 
run_SCOPE(csv_inputs = Inputs_forest,
          Simulation_Name = "LAI_hcmax_", 
          split = FALSE,
          t = "t", Rin = "Rin", Rli = "Rli", p = "p", ea = NA, u = "ws", tts = "tts", tto = NA, psi = NA,
          hc_c = 26.30, hc = NA, LAI = "LAI_hcmax",
          Ta = "Ta", RH = "RH",  
          SMC = "SMC60", # NA, # 
          SMC_c = 0.25,
          stressfactor = 1,
          BallBerrySlope_c = 8,
          z_c = 40,
          startDOY = 20181201, endDOY = 20210130,  # timestamp period
          LAT = 52.5, LON = 13.32, timezn = 0,   # Lat/long and time zone
          lite = 1,
          soilspectrum = 1, 
          applTcorr = 1, 
          soil_heat_method = 1, 
          calc_rss_rbs = 0,
          MoninObukhov = 0)
####################################################################################################
