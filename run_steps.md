## Sequency of steps to run one time series location

``` r
library(rSTEMMUSSCOPE)
```

First step is to create the input/output folders and patch to run the model.

#### set up the input folder for the location
``` r
new_run(patch = "D:/model/rSTEMMUS_SCOPE/", # model (src) location
        StartTime = "2023-06-01T00:00",    # datatime starts the timeseries
        EndTime = "2023-11-30T23:00",      # datatime ends the timeseries
        site_name = "DE-HoH",              # location name
        run_name = "ECdata_01",            # run name for this settings (calibration)
        output_name = format(Sys.time(), "%Y%b%d_%H%M")) # run datatime
```

Second step is to set all required static input parameters to run the model.

#### set up the static inputs for the location
``` r
 input_constants(patch = "D:/model/rSTEMMUS_SCOPE/", # model (src) location
                 site_name = "DE-HoH",              # location name
                 run_name = "ECdata_01",            # run name for this settings (calibration)
                 LAT = 51.25,
                 LON = 11.44,
                 elevation = 500,
                 IGBP_veg_long = "Grassland",       # any IGBP class (see info_ functions)
                 hc = 0.03,                         # canopy height
                 n_timestamps = 7344,               # number of timestamps steps
                 timestep_min = 30,                 # 60 for hourly and 30 for half hour
                 initial_soil_temperature = data.frame("skt"  = Initial_01June23[1,2], # see info_
                                                         "stl1" = Initial_01June23[2,2],
                                                         "stl2" = Initial_01June23[3,2],
                                                         "stl3" = Initial_01June23[4,2],
                                                         "stl4" = Initial_01June23[5,2]), #CDS ERA5Land layers 1 to 4
                 initial_volumetric_soil_water = data.frame("swvl1" = Initial_01June23[6,2],
                                                              "swvl2" = Initial_01June23[7,2],
                                                              "swvl3" = Initial_01June23[8,2],
                                                              "swvl4" = Initial_01June23[9,2]), #CDS ERA5Land layers 1 to 4
                 soil_property_list = Soil_property_CRNs, # see info_
                 startDOY = 121,    # day of the year starting the timeseries
                 endDOY = 274,      # day of the year ending the timeseries
                 timezn = 1,        # timezone)
```
**note:** see "get_SoilInitials()" for the initial_soil_temperature and initial_volumetric_soil_water, 
"get_SoilProperties()" for soil_property_list, "info_SCOPE_options()" for setoptions, 
"info_IGBP_classes()" for IGBP_veg_long, "info_SCOPE_README()" for SCOPE constants. 
STEMMUS constants and setting can be checked by "check_STEMMUS_DefineConstants()", 
"check_STEMMUS_SoilConstants()" and "check_STEMMUS_ModelSettings()".

Third step is to set all required time series input data to run the model (see README).

#### set up the input folder for the location
``` r
input_timeseries(patch = "D:/model/rSTEMMUS_SCOPE/",  # model (src) location
                 site_name = "DE-HoH",               # location name
                 run_name = "ECdata_01",             # run name for this settings (calibration)
                 t_file =	ts_DWD$t_,                # Decimal Julian Day (doy_float)
                 year_file	= year(ts_DWD$timestamp), # vector with the Calendar Year
                 Rin_file	= ts_DWD$Rin_sun,         # Incoming Shortwave Radiation [W m-2]
                 Rli_file	= ts_DWD$Rli_,            # Incoming Longwave Radiation [W m-2]
                 p_file	= ts_DWD$p_,                # Atmospheric pressure vector [hPa]
                 Ta_file =	ts_DWD$Ta_,               # Air Temperature [°C]
                 RH_file = ts_DWD$RH_,               # Relative Humidity [%]
                 ea_file =	ts_DWD$ea_,               # Air Vapor Pressure [hPa]
                 VPD_file = ts_DWD$VPD_,             # Vapour Pressure Deficit [hPa]
                 u_file	= ts_DWD$u_,                # Wind speed 	[m s-1] (u >= 0.05)
                 rain_file = ts_DWD$rain_/36000,     # Precipitation [cm s-1] (36000 mm/h))
                 tts_file	= tts_calc,               # optional Zenith Solar Angle
                 CO2_file	= DE_ICOS$CO2_,           # optional Carbon Dioxide Concentration [mg m-3] 	
                 LAI_file =	LAI500_Modis$LAI)       # Leaf Area Index [m2 m-2] (LAI >= 0.01)
```

Last step is to run the model by informing the site_name and run_name. The MATLAB path need to be set to "D:/model/STEMMUS_SCOPE/src/".


``` r
run_inMATLAB(patch = "D:/model/rSTEMMUS_SCOPE/", # model (src) location
             site_name = "DE-HoH",               # location name
             run_name = "ECdata_01")             # run name for this settings (calibration)
```

MATLAB will open and the model will start to run, when the last timestamp is run, the window will be closed and the results will be available in the output folder.

## Check the output simulation
``` r
library(tidyverse)
library(patchwork)
library(openair)
library(hydroGOF)
```

#### SWC simulations output
``` r
Sim_Theta_files <- list.files(path = "D:/model/rSTEMMUS_SCOPE/output/",
                              pattern = "Sim_Theta", full.names=T, recursive=T)

# to subset a group by the run name if needed
# Sim_Theta_files |>
#  str_subset(pattern = "DE-001") -> Sim_Theta_files_test001
```

#### swc simulation depth in cm
``` r
depth_theta <- c(1,2,3,5,7,9,11,13,15,17,19,21,23,25,27.5,30,32.5,35,40,45,50,55,60,
                 70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,
                 245,260,280,300,320,340,360,380,400,420,440,460,480,500)
```
                 
#### swc simulation lenght of the depth in cm
``` r
depth_layer <- c(1,1,1,2, 2,2,2, 2,2, 2,2,2,2,2, 2.5,2.5, 2.5,2.5,5, 5,5,5,5,
                 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,15,15,
                 20,20,20,20,20,20,20,20,20,20,20,20)
```

#### hourly t_ timestamp (doy_float) [-]
``` r
ts_h_2023 <- seq(as.POSIXct("2023-01-01", tz = "UTC"),
                 as.POSIXct("2024-01-01", tz = "UTC"),
                 by = "hour") #"30 min"

ts_h_2023 <- ts_h_2023[-ncell(ts_h_2023)]
# timestamp of the simulation
ts_h_ <- ts_h_2023[date(ts_h_2023) >= head(CRNs_daily_obs)[[1]][1] &
                   date(ts_h_2023) <= tail(CRNs_daily_obs)[[1]][6]]
```

#### read the SWC in the output file Sim_Theta
``` r
SMC001_default <- read_csv(Sim_Theta_files[1], skip = 2)
names(SMC001_default) <- paste0("dept_", depth_theta, "_", depth_layer)
SMC001_default %>% add_column("date" = ts_h_, .before = "dept_1_1", .name_repair = "unique") -> SMC001_default

# daily simulation tocompare with the observed CRN
SMC001_default_doy <- openair::timeAverage(SMC001_default, avg.time="day")
```

#### rain data
``` r
rain_daily <- list()

for (i in 1:19) {
  ts_CRN_DWD_run[[i]] %>%
    group_by(date(timestamp)) %>%
    summarise(rain = sum(rain_)) -> rain_daily[[i]]
}
```

#### Observed SWC
``` r
CRNs_obs_daily <- read_csv("CRNs_obs_daily.csv")
```

#### plot and check accuracy
``` r
ggplot() +
  geom_line(aes(x = date(SMC001_default_doy$date), y = SMC001_default_doy$dept_15_2), color="brown", linewidth = 0.75) +
  geom_col(aes(x = date(rain_daily[[1]]$`date(timestamp)`), y = rain_daily[[1]]$rain/100), fill = "lightblue", alpha=0.7) +
  geom_line(aes(x = CRNs_obs_daily$date, y = CRNs_obs_daily$SM_C01), colour = "black", linewidth = 1.2) +
  scale_y_continuous(name = "Soil Water Content [m3 m-3]", limits = c(0,0.40), sec.axis = sec_axis(~.*100, name = "precipitation [mm]")) +
  ggtitle(paste0("CRN", 01, " - ", "test DE-001")) +
  labs(x = "Days of the year 2023 (Jun to Nov)") +
  theme(
    axis.title.y = element_text(color = "grey25"),
    axis.title.y.right = element_text(color = "blue"))

#KGE    r   Beta  Alpha
hydroGOF::KGE(CRNs_obs_daily$SM_C01, SMC001_default_doy$dept_15_2, out.type = "full")
```

#### Fluxes simulation output
``` r
Sim_Fluxes_files <- list.files(path = "D:/model/rSTEMMUS_SCOPE/output/",
                               pattern = "fluxes", full.names=T, recursive=T)

# to subset a group by the run name if needed
# Sim_Fluxes_files |>
#   str_subset(pattern = "DE-001") -> Fluxes_files_test001

name_units = read_csv(Sim_Fluxes_files[[1]], skip = 0, col_names = F, n_max = 2)
fluxes_DE001 <- read_csv(Sim_Fluxes_files[[1]], skip = 2, col_names = F, col_types = "d")
name_units[,26] # 60*60*24
names(fluxes_DE001) <- unlist(name_units[1,])
```

#### daily ET converted to mm
``` r
fluxes_DE001 |>
  group_by(round(DoY, 0)) |>
  summarise(ET = sum(ET)*86400) -> ET_DE001

ET_DE001 <- ET_DE001[-168,]

ET_001 <- tibble("date" = CRNs_obs_daily$date, "ET" = ET_DE001$ET)
```

#### ET plot reversed
``` r
ET_001 |>
  ggplot() +
  geom_col(aes(x = date, y = ET), fill = "cyan", col="blue", alpha=0.7) +
  scale_y_reverse() +
  labs(y = "ET [mm]") +
  theme(panel.background = element_rect(fill = "white",
                                        colour = "lightblue",
                                        size = 0.5, linetype = "solid"),
        panel.grid.minor.y = element_line( size=.1, color="lightblue" , linetype = "dotted"),
        panel.grid.major.y = element_line( size=.1, color="lightblue" , linetype = "dotted"),
        axis.title.y = element_text(color = "grey45"),
        axis.title.y.right = element_text(color = "blue"),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) -> plotET_DE001
```

#### precipitation plot       
``` r
rain_daily[[1]] |>
  ggplot() +
  geom_col(aes(x = `date(timestamp)`, y = rain), fill = "lightblue", col="blue", alpha=0.7) +
  labs(y = "Preciptation [mm]", x = "Days of the year 2023 (Jun to Nov)") +
  theme(panel.background = element_rect(fill = "white",
                                        colour = "lightblue",
                                        size = 0.5, linetype = "solid"),
        panel.grid.minor.y = element_line( size=.1, color="lightblue" , linetype = "dotted"),
        panel.grid.major.y = element_line( size=.1, color="lightblue" , linetype = "dotted"),
        axis.title.y = element_text(color = "grey45"),
        axis.title.y.right = element_text(color = "blue"),
        axis.title.x = element_text(color = "grey45"),
        #axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) -> plotRain_DE001
```

#### SWC plot
``` r
ggplot() +
  geom_line(aes(x = date(SMC001_default_doy$date), y = SMC001_default_doy$dept_15_2), color="brown", linewidth = 0.75) +
  geom_line(aes(x = CRNs_obs_daily$date, y = CRNs_obs_daily$SM_C01), colour = "black", linewidth = 1.2) +
  scale_y_continuous(name = "Soil Water Content [m3 m-3]", limits = c(0.05,0.40)) +
  ggtitle("observed (black) - predicted (brown)") +
  theme(panel.background = element_rect(fill = "white",
                                        colour = "lightblue",
                                        size = 0.5, linetype = "solid"),
        panel.grid.minor.y = element_line( size=.1, color="lightblue" , linetype = "dotted"),
        panel.grid.major.y = element_line( size=.1, color="lightblue" , linetype = "dotted"),
        axis.title.y = element_text(color = "grey45"),
        axis.title.y.right = element_text(color = "blue"),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) -> plotSWC_DE001
```

##### combined (patchwork) plot
``` r
plotET_DE001 / plotSWC_DE001 / plotRain_DE001 + plot_layout(heights = c(1, 3 , 1))
```
![image](https://github.com/user-attachments/assets/007a574c-f46b-486a-97db-cdb37d24d65a)

