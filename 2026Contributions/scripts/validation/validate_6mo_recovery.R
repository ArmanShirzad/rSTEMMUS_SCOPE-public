# ============================================================
# validate_6mo_recovery.R
# Compare STEMMUS-SCOPE simulation output with observations
# Specifically for the 6-month simulation recovered after interruption
# ============================================================

# Load required packages
if (!require(tidyverse)) install.packages("tidyverse")
if (!require(lubridate)) install.packages("lubridate")
library(tidyverse)
library(lubridate)

# ============================================================
# CONFIGURATION
# ============================================================

# Paths
project_root <- getwd()
obs_file <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")

# FORCE OUTPUT DIR to the recovered folder
output_base <- file.path(project_root, "rSTEMMUS_SCOPE/output")
octave_output <- file.path(output_base, "DE-STG_Test_FIXED_6mo_OCTAVE_2026Feb11_1721")

cat("Using observation file:", obs_file, "\n")
cat("Using simulation output:", octave_output, "\n")

# ============================================================
# LOAD OBSERVATION DATA
# ============================================================

obs <- readRDS(obs_file)
cat("\nObservation data loaded:", nrow(obs), "rows\n")
cat("Time range:", as.character(min(obs$timestamp)), "to", as.character(max(obs$timestamp)), "\n")

# ============================================================
# LOAD SIMULATION DATA
# ============================================================

# Read fluxes (contains LE, H, ET, etc.)
fluxes_file <- file.path(octave_output, "fluxes.csv")
if (file.exists(fluxes_file)) {
  sim_fluxes <- read.csv(fluxes_file, skip = 1)  # Skip unit row
  colnames(sim_fluxes) <- c("sim_num", "iterations", "year", "DoY", 
                            "Rntot", "lEtot", "Htot", "Rnctot", "lEctot", "Hctot",
                            "Actot", "Rnstot", "lEstot", "Hstot", "Gtot", "Resp",
                            "aPAR", "aPAR_Cab", "aPAR_ratio", "aPAR_Wm2", "PAR",
                            "Eoutf", "Eoutf_ratio", "Trap", "Evap", "ET", "GPP", "NEE")
  cat("Fluxes loaded:", nrow(sim_fluxes), "timesteps\n")
} else {
  stop("Fluxes file not found!")
}

# Read soil moisture (Sim_Theta.csv)
theta_file <- file.path(octave_output, "Sim_Theta.csv")
if (file.exists(theta_file)) {
  # Read header again carefully as recover script appended header
  sim_theta_raw <- read.csv(theta_file, header = FALSE)
  # Rows 1-3 are headers
  depths <- as.numeric(sim_theta_raw[1, ])
  sim_theta <- sim_theta_raw[-(1:3), ]
  colnames(sim_theta) <- paste0("depth_", depths, "cm")
  sim_theta <- as.data.frame(lapply(sim_theta, as.numeric))
  cat("Soil moisture loaded:", nrow(sim_theta), "timesteps,", ncol(sim_theta), "layers\n")
} else {
  sim_theta <- NULL
  cat("Soil moisture file not found, skipping.\n")
}

# Read soil temperature (Sim_Temp.csv)
temp_file <- file.path(octave_output, "Sim_Temp.csv")
if (file.exists(temp_file)) {
  sim_temp_raw <- read.csv(temp_file, header = FALSE)
  depths_temp <- as.numeric(sim_temp_raw[1, ])
  sim_temp <- sim_temp_raw[-(1:3), ]
  colnames(sim_temp) <- paste0("depth_", depths_temp, "cm")
  sim_temp <- as.data.frame(lapply(sim_temp, as.numeric))
  cat("Soil temperature loaded:", nrow(sim_temp), "timesteps\n")
} else {
  sim_temp <- NULL
  cat("Soil temperature file not found, skipping.\n")
}

# ============================================================
# CREATE TIMESTAMP FOR SIMULATION DATA
# ============================================================

# Simulation uses DoY (Day of Year) - need to convert to timestamp
sim_start <- min(obs$timestamp) # Assumes simulation aligns with obs start
# OR explicit start:
sim_start_explicit <- as.POSIXct("2019-01-01 00:00:00", tz="UTC") 

# Check if obs start matches 2019-01-01
cat("Simulation start assumed:", as.character(sim_start), "\n")

sim_timestamps <- sim_start + hours(0:(nrow(sim_fluxes) - 1))

# Add timestamps to simulation data
sim_fluxes$timestamp <- sim_timestamps[1:nrow(sim_fluxes)]
if (!is.null(sim_theta)) sim_theta$timestamp <- sim_timestamps[1:nrow(sim_theta)]
if (!is.null(sim_temp)) sim_temp$timestamp <- sim_timestamps[1:nrow(sim_temp)]

# ============================================================
# ALIGN DATA FOR COMPARISON
# ============================================================

# Merge observations with simulation by timestamp
comparison_df <- obs %>%
  select(timestamp, 
         obs_LE = LE, 
         obs_H = H, 
         obs_ET = ET,
         obs_SMC_5cm = SMC_5cm,
         obs_SMC_60cm = SMC_60cm,
         obs_temp_5cm = soil_temp05cm,
         obs_temp_10cm = soil_temp10cm) %>%
  mutate(obs_SMC_5cm = obs_SMC_5cm / 100,    # Convert % to m³/m³
         obs_SMC_60cm = obs_SMC_60cm / 100) %>%  # Convert % to m³/m³
  inner_join(sim_fluxes %>% # Use inner_join to only keep matched times (shorter sim)
              select(timestamp, 
                     sim_LE = lEtot, 
                     sim_H = Htot,
                     sim_ET = ET),
            by = "timestamp")

# Add soil moisture comparison
if (!is.null(sim_theta) && "depth_60cm" %in% colnames(sim_theta)) {
  comparison_df <- comparison_df %>%
    left_join(sim_theta %>% 
                select(timestamp, 
                       sim_SMC_5cm = `depth_5cm`,
                       sim_SMC_60cm = `depth_60cm`), 
              by = "timestamp")
}

# Add soil temperature comparison
if (!is.null(sim_temp) && "depth_5cm" %in% colnames(sim_temp)) {
  comparison_df <- comparison_df %>%
    left_join(sim_temp %>% 
                select(timestamp, 
                       sim_temp_5cm = `depth_5cm`,
                       sim_temp_10cm = `depth_9cm`), # Check if 9cm is closest to 10cm
              by = "timestamp")
}

cat("\nComparison data prepared:", nrow(comparison_df), "matched timesteps\n")

# ============================================================
# PLOTTING
# ============================================================

# Create output directory for plots
plots_dir <- file.path(project_root, "2026Contributions/validation_plots_6mo")
if (!dir.exists(plots_dir)) dir.create(plots_dir, recursive = TRUE)

# --- PLOT: Latent Heat Flux ---
p1 <- comparison_df %>%
  pivot_longer(cols = c(obs_LE, sim_LE), names_to = "source", values_to = "LE") %>%
  ggplot(aes(x = timestamp, y = LE, color = source)) +
  geom_line(alpha = 0.7) +
  labs(title = "Latent Heat Flux Comparison (Jan-Jun 2019)", 
       subtitle = "Analysis of Recovered Simulation Data (92% Complete)") +
  theme_minimal()
ggsave(file.path(plots_dir, "01_LE_recovery.png"), p1, width = 12, height = 6)

# --- PLOT: Soil Moisture 60cm ---
p5 <- comparison_df %>%
  ggplot(aes(x = timestamp)) +
  geom_line(aes(y = obs_SMC_60cm, color = "Observation"), linewidth = 1) +
  geom_line(aes(y = sim_SMC_60cm, color = "Simulation"), linewidth = 1) +
  scale_color_manual(values = c("Observation" = "blue", "Simulation" = "red")) +
  labs(title = "Soil Moisture at 60cm (Jan-Jun 2019)",
       y = "Volumetric Water Content (m3/m3)",
       subtitle = "Recovered Simulation vs Observations") +
  theme_minimal()
ggsave(file.path(plots_dir, "05_SMC_60cm_recovery.png"), p5, width = 12, height = 6)

# --- PLOT: Soil Moisture 5cm ---
p6 <- comparison_df %>%
  ggplot(aes(x = timestamp)) +
  geom_line(aes(y = obs_SMC_5cm, color = "Observation"), linewidth = 1) +
  geom_line(aes(y = sim_SMC_5cm, color = "Simulation"), linewidth = 1) +
  scale_color_manual(values = c("Observation" = "blue", "Simulation" = "red")) +
  labs(title = "Soil Moisture at 5cm (Jan-Jun 2019)",
       y = "Volumetric Water Content (m3/m3)") +
  theme_minimal()
ggsave(file.path(plots_dir, "06_SMC_5cm_recovery.png"), p6, width = 12, height = 6)

cat("\nPlots saved to:", plots_dir, "\n")

# --- PLOT: Initial 48h Zoom (Initialization Check) ---
p7 <- comparison_df %>%
  filter(timestamp <= min(timestamp) + hours(48)) %>%
  pivot_longer(cols = c(obs_SMC_60cm, sim_SMC_60cm), names_to = "source", values_to = "SMC") %>%
  mutate(source = ifelse(source == "obs_SMC_60cm", "Observations", "Simulation (Octave)")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source)) +
  geom_line(linewidth = 1.2) +
  geom_point(data = . %>% filter(source == "Simulation (Octave)"), size = 2) +
  scale_color_manual(values = c("Observations" = "blue", "Simulation (Octave)" = "red")) +
  labs(title = "Soil Moisture Initialization Check (First 48h)",
       subtitle = "Recovered Simulation (Red) vs Observations (Blue) - Confirming Fix matches Obs",
       y = "Volumetric Water Content (m3/m3)",
       x = "Time") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(plots_dir, "07_initial_48h_recovery.png"), p7, width = 10, height = 6)
cat("Saved: 07_initial_48h_recovery.png\n")
