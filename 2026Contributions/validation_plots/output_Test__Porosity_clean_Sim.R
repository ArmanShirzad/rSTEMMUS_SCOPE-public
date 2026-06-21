
# Load required libraries
library(tidyverse)
library(openair)
library(hydroGOF)
library(lubridate)

# Set working directory and load observed data
setwd("D:/data_Steglitz/11_07_2025")
steg_df <- readRDS("EC_DWD_ROTH_clean.rds")
obs_df <- steg_df %>%
  select(timestamp, SMC_60cm) %>%
  rename(Date = timestamp, Observed = SMC_60cm) %>%
  mutate(Observed = Observed / 100)  # Convert to m³/m³
#plot(obs_daily)
# Aggregate to daily means
#obs_daily <- obs_df %>%
 # rename(date = Date) %>%
#  timeAverage(avg.time = "day") %>%
#  rename(Date = date)  # optional: rename it back afterward

summary(steg_df)

# Define simulation file and depth structure
sim_path <- "D:/model/rSTEMMUS_SCOPE/output/DE-STG_Test_Porosity_2025Jul31_0919/Sim_Theta.csv"
depth_theta <- c(1,2,3,5,7,9,11,13,15,17,19,21,23,25,27.5,30,32.5,35,40,45,50,55,60,
                 70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,
                 245,260,280,300,320,340,360,380,400,420,440,460,480,500)
depth_layer <- c(1,1,1,2,2,2,2,2,2,2,2,2,2,2,2.5,2.5,2.5,2.5,5,5,5,5,5,
                 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,15,15,
                 20,20,20,20,20,20,20,20,20,20,20,20)

# Load simulation data and assign proper column names
sim_df <- read_csv(sim_path, skip = 3, col_names = FALSE)
names(sim_df) <- paste0("depth_", depth_theta, "_", depth_layer)
names(sim_df)
summary(sim_df)
# Create timestamp (assuming hourly starting from 2019-01-01)
sim_df <- sim_df %>%
  mutate(timestamp = seq.POSIXt(from = as.POSIXct("2019-01-01 00:00:00"),
                           by = "hour", length.out = nrow(sim_df)))
summary(sim_df)

#tail(sim_df$Date)

# Daily average of simulation
#sim_daily <- sim_df %>%
#  rename(date = Date) %>%
##  timeAverage(avg.time = "day") %>%
 # rename(Date = date)


# Join observed and simulated for 20 cm depth (which is depth_19_2)
# Convert to Date only (removes time zone issues)
#obs_daily <- obs_daily %>% mutate(Date = as.Date(Date))
#sim_daily <- sim_daily %>% mutate(Date = as.Date(Date))

combined_df <- inner_join(
  steg_df,
  sim_df, #%>% #select(Date, Simulated = depth_5_2),
  by = "timestamp"
)

#summary(combined_df)
#range(obs_daily$Date)
#range(sim_daily$Date)

# 
# --- Calculate model performance metrics ---
library(hydroGOF)

# Remove any NA values just in case
df_clean <- na.omit(combined_df)

# Kling-Gupta Efficiency
#kge_result <- KGE(df_clean$Simulated, df_clean$Observed, out.type = "full")

# RMSE, MAE, R²
#rmse_val <- rmse(df_clean$Simulated, df_clean$Observed)
#mae_val  <- mae(df_clean$Simulated, df_clean$Observed)
#r2_val   <- cor(df_clean$Simulated, df_clean$Observed)^2

# Print results
#cat("Model Performance Metrics:\n")
#cat("KGE       :", round(kge_result$KGE.value, 3), "\n")
#cat("  r       :", round(kge_result$KGE.elements["r"], 3), "\n")
#cat("  Beta    :", round(kge_result$KGE.elements["Beta"], 3), "\n")
#cat("  Alpha   :", round(kge_result$KGE.elements["Alpha"], 3), "\n")
#cat("RMSE      :", round(rmse_val, 3), "\n")
#cat("MAE       :", round(mae_val, 3), "\n")
#cat("R-squared :", round(r2_val, 3), "\n")

summary(combined_df$depth_60_5)
combined_df$depth_60_5[combined_df$depth_60_5< 0.1] <- 0.1

combined_df$depth_60_5[combined_df$depth_60_5> 0.31] <- 0.31

summary(combined_df$depth_60_5)
sum(combined_df$depth_60_5 == 0.1)


# Plot comparison with optional rainfall if available
#png("soil moisture.png", width = 800,height = 600)
ggplot(combined_df, aes(x = timestamp)) +
  geom_line(aes(y = SMC_60cm/100, color = "Observed"), linewidth = 1.1) +
  #geom_line(aes(y = SMC60BFGSL /100, color = "red"), linewidth = 1.1) +#
  geom_line(aes(y = depth_60_5, color = "Simulated"), linewidth = 1.1) +
  labs(title = "Soil Moisture Comparison at 60 cm Depth (Daily Avg)",
       x = "Date",
       y = "Volumetric Soil Moisture [m³/m³]",
       color = "Legend") +
  scale_color_manual(values = c("Observed" = "black", "Simulated" = "blue", "red"="red")) +
  theme_minimal()
#dev.off()
# Compute KGE and other metrics
KGE_result <- hydroGOF::KGE(combined_df$SMC_60cm/100, combined_df$depth_60_5, out.type = "full")
print(KGE_result)


##
##
##
##

# Load libraries
library(tidyverse)
library(lubridate)
library(openair)
library(hydroGOF)
library(patchwork)

# === 1. Load Observed Data ===
obs_path <- "D:/data_Steglitz/11_07_2025/EC_DWD_ROTH_clean.rds"
steg_df <- readRDS(obs_path)

steg_df <- steg_df %>%
  filter(!is.na(timestamp)) %>%
  mutate(
    timestamp = as.POSIXct(timestamp, tz = "UTC"),
    SM_60cm_obs = SMC_60cm / 100,
    ET_obs = ET_clean_0,
    rain_mmhr = prec_mm_EC * (1000 / 36000)  # Convert from m/s to mm/hour
  )

# === 2. Load Simulated Soil Moisture ===
sim_path <- "D:/model/rSTEMMUS_SCOPE/output/DE-STG_Test_Porosity_2025Jul31_0919/Sim_Theta.csv"
depth_theta <- c(1,2,3,5,7,9,11,13,15,17,19,21,23,25,27.5,30,32.5,35,40,45,50,55,60,
                 70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,
                 245,260,280,300,320,340,360,380,400,420,440,460,480,500)
depth_layer <- c(1,1,1,2,2,2,2,2,2,2,2,2,2,2,2.5,2.5,2.5,2.5,5,5,5,5,5,
                 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,15,15,
                 20,20,20,20,20,20,20,20,20,20,20,20)

sim_df <- read_csv(sim_path, skip = 3, col_names = FALSE)
names(sim_df) <- paste0("depth_", depth_theta, "_", depth_layer)

sim_df <- sim_df %>%
  mutate(timestamp = seq.POSIXt(
    from = as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
    by = "hour",
    length.out = nrow(sim_df)
  )) %>%
  rename(SM_60cm_sim = depth_60_5)

# === 3. Merge for Plotting ===
plot_df <- steg_df %>%
  select(timestamp, SM_60cm_obs, ET_obs, rain_mmhr) %>%
  inner_join(sim_df %>% select(timestamp, SM_60cm_sim), by = "timestamp")

# === 4. Plot Observed ET ===
plot_ET <- ggplot(plot_df, aes(x = timestamp, y = ET_obs)) +
  geom_line(color = "blue", size = 0.25) +
  scale_y_reverse() +
  labs(y = "Observed ET [mm/hour]") +
  theme_minimal(base_size = 13) +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank())

# === 5. Plot Soil Moisture (Obs vs Sim) ===
plot_SWC <- ggplot(plot_df) +
  geom_line(aes(x = timestamp, y = SM_60cm_obs, color = "Observed"), linewidth = 1.2) +
  geom_line(aes(x = timestamp, y = SM_60cm_sim, color = "Simulated"), linewidth = 0.8) +
  scale_color_manual(values = c("Observed" = "black", "Simulated" = "brown")) +
  labs(y = "Soil Moisture [m³/m³]", title = "Observed vs Simulated at 60 cm", color = "Legend") +
  scale_y_continuous(limits = c(0.05, 0.45)) +
  theme_minimal(base_size = 13)

# === 6. Plot Rainfall ===
plot_Rain <- ggplot(plot_df, aes(x = timestamp, y = rain_mmhr)) +
  geom_col(fill = "lightblue", color = "blue", alpha = 0.6) +
  labs(y = "Rainfall [mm/hour]", x = "Date-Time") +
  theme_minimal(base_size = 13)

# === 7. Combine the Plots ===
final_plot <- plot_ET / plot_SWC / plot_Rain + plot_layout(heights = c(1.2, 3, 1.2))
final_plot


##
##
##
# Load libraries
library(tidyverse)
library(lubridate)

# Load your observed data
obs_path <- "D:/data_Steglitz/11_07_2025/EC_DWD_ROTH_clean.rds"
steg_df <- readRDS(obs_path)

# Clean timestamp and convert precipitation to mm/hour
rain_df <- steg_df %>%
  filter(!is.na(timestamp)) %>%
  mutate(
    timestamp = as.POSIXct(timestamp, tz = "UTC"),
    rain_mmhr = prec_mm_EC * (1000 / 36000)  # Convert from m/s to mm/hour
  ) %>%
  select(timestamp, rain_mmhr)

# Plot the hourly precipitation
ggplot(rain_df, aes(x = timestamp, y = rain_mmhr)) +
  geom_col(fill = "lightblue", color = "blue", alpha = 0.6) +
  labs(title = "Hourly Observed Precipitation",
       x = "Date-Time",
       y = "Rainfall [mm/hour]") +
  theme_minimal(base_size = 13)


summary(steg_df$prec_mm)
summary(steg_df$prec_mm_EC)

library(tidyverse)
library(lubridate)

# Load and process data
steg_df <- readRDS("D:/data_Steglitz/11_07_2025/EC_DWD_ROTH_clean.rds")

rain_df <- steg_df %>%
  filter(!is.na(timestamp)) %>%
  mutate(timestamp = as.POSIXct(timestamp, tz = "UTC")) %>%
  select(timestamp, rain_mm = prec_mm)

# Plot hourly rainfall
ggplot(rain_df, aes(x = timestamp, y = rain_mm)) +
  geom_col(fill = "lightblue", color = "blue", alpha = 0.6) +
  labs(
    title = "Hourly Observed Precipitation",
    x = "Date-Time",
    y = "Rainfall [mm/hour]"
  ) +
  theme_minimal(base_size = 13)


###
library(tidyverse)
library(lubridate)

steg_df <- readRDS("D:/data_Steglitz/11_07_2025/EC_DWD_ROTH_clean.rds")

steg_df <- steg_df %>%
  filter(!is.na(timestamp)) %>%
  mutate(
    timestamp = as.POSIXct(timestamp, tz = "UTC"),
    rain_mmhr_EC = prec_mm_EC * (1000 / 3600),  # convert m/s → mm/hour
    rain_mm_direct = prec_mm
  )

# Reshape for plotting both
rain_long <- steg_df %>%
  select(timestamp, rain_mmhr_EC, rain_mm_direct) %>%
  pivot_longer(cols = -timestamp, names_to = "source", values_to = "rain")

# Plot to compare both precipitation sources
ggplot(rain_long, aes(x = timestamp, y = rain, color = source)) +
  geom_line(alpha = 0.8) +
  labs(title = "Comparison of Precipitation Sources",
       y = "Rainfall [mm/hour]", x = "Date-Time", color = "Data Source") +
  theme_minimal()


###

# Load libraries
library(dplyr)
library(readr)
names(combind_data)
sim <- combind_data[, c(1, 120)]
head(sim)
write_csv(sim, "sim.csv")

# Load required libraries
library(dplyr)
library(readr)
library(lubridate)

# Read the uploaded CSV
sim <- read_csv("sim.csv")  # adjust path if needed
summary(sim)
library(dplyr)
library(readr)

# Load your data
sim <- read_csv("sim.csv")   # Adjust if needed

# Convert timestamp
sim$timestamp <- as.POSIXct(sim$timestamp)

# Test structure
print(names(sim))
summary(sim)
sim[which.min(sim$depth_60_5), ]
sim$depth_60_5[sim$timestamp == as.POSIXct("2019-07-21 15:00:00")] <- 0.1
View(sim)

