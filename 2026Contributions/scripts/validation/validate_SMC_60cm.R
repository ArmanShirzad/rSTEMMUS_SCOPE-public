# ============================================================
# validate_SMC_60cm.R
# Compare STEMMUS-SCOPE Soil Moisture (60cm) with Observations
# ============================================================
# Created: 2026-01-28
# Purpose: Plot simulated vs observed soil moisture at 60cm depth
#          for Steglitz (DE-STG) site validation
# ============================================================

library(tidyverse)
library(lubridate)

# ============================================================
# CONFIGURATION
# ============================================================

project_root <- getwd()
obs_file <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")

# Find the latest DE-STG output folder
# Find the latest DE-STG output folder
output_base <- file.path(project_root, "rSTEMMUS_SCOPE/output")
# FORCE OUTPUT DIR (Update this manually if needed)
sim_output <- file.path(output_base, "DE-STG_Test_pre_mm_Steglitz_OCTAVE_2026Feb03_1524")

if (!dir.exists(sim_output)) {
  # Fallback to auto-detection if specific folder missing
  cat("Specific output folder not found, searching...\n")
  output_dirs <- list.dirs(output_base, recursive = FALSE)
  destg_dirs <- output_dirs[grepl("DE-STG", output_dirs)]
  if (length(destg_dirs) == 0) stop("No DE-STG simulation output found!")
  sim_output <- destg_dirs[length(destg_dirs)]
}

cat("Using observation file:", obs_file, "\n")
cat("Using simulation output:", sim_output, "\n")

# ============================================================
# LOAD OBSERVATION DATA
# ============================================================

obs <- readRDS(obs_file)
cat("\nObservation data loaded:", nrow(obs), "rows\n")
cat("Time range:", as.character(min(obs$timestamp)), "to", as.character(max(obs$timestamp)), "\n")

# Extract 60cm soil moisture and convert % to m3/m3
obs_smc <- obs %>%
  select(timestamp, obs_SMC_60cm = SMC_60cm, prec_mm) %>%
  mutate(obs_SMC_60cm = obs_SMC_60cm / 100) # Fix Unit Mismatch!

cat("Observation SMC_60cm range:", round(min(obs_smc$obs_SMC_60cm, na.rm=TRUE), 3), 
    "to", round(max(obs_smc$obs_SMC_60cm, na.rm=TRUE), 3), "m³/m³\n")

# ============================================================
# LOAD SIMULATION DATA (Sim_Theta.csv)
# ============================================================

theta_file <- file.path(sim_output, "Sim_Theta.csv")
if (!file.exists(theta_file)) {
  stop("Sim_Theta.csv not found! Simulation may still be running or failed.")
}

sim_theta_raw <- read.csv(theta_file, header = FALSE)

# Row 1 = depths (cm)
# Row 2 = layer thickness
# Row 3 = units
# Data starts from row 4
depths <- as.numeric(sim_theta_raw[1, ])
cat("\nSimulation depths available (cm):", paste(head(depths, 10), collapse=", "), "...\n")

# Find column index for 60cm depth
idx_60cm <- which(depths == 60)
if (length(idx_60cm) == 0) {
  cat("Exact 60cm not found. Available depths near 60cm:\n")
  near_60 <- depths[depths >= 55 & depths <= 65]
  print(near_60)
  idx_60cm <- which.min(abs(depths - 60))  # Closest to 60cm
  cat("Using closest depth:", depths[idx_60cm], "cm\n")
}

# Extract 60cm column
sim_theta <- sim_theta_raw[-(1:3), idx_60cm]
sim_theta <- as.numeric(sim_theta)

cat("Simulation loaded:", length(sim_theta), "timesteps\n")
cat("Simulation SMC_60cm range:", round(min(sim_theta, na.rm=TRUE), 3), 
    "to", round(max(sim_theta, na.rm=TRUE), 3), "m³/m³\n")

# ============================================================
# CREATE TIMESTAMPS FOR SIMULATION
# ============================================================

# Simulation starts at same time as observations
sim_start <- as.POSIXct("2019-01-01 00:00:00", tz = "UTC")
sim_timestamps <- sim_start + hours(0:(length(sim_theta) - 1))

sim_df <- tibble(
  timestamp = sim_timestamps,
  sim_SMC_60cm = sim_theta
)

# ============================================================
# MERGE DATA
# ============================================================

comparison <- obs_smc %>%
  left_join(sim_df, by = "timestamp")

cat("\nMatched timesteps:", sum(!is.na(comparison$sim_SMC_60cm)), 
    "out of", nrow(comparison), "\n")

# ============================================================
# PLOTTING
# ============================================================

plots_dir <- file.path(project_root, "2026Contributions/validation_plots")
if (!dir.exists(plots_dir)) dir.create(plots_dir, recursive = TRUE)

# --- PLOT 1: Time Series Comparison ---
p1 <- comparison %>%
  filter(!is.na(sim_SMC_60cm)) %>%
  pivot_longer(cols = c(obs_SMC_60cm, sim_SMC_60cm), 
               names_to = "source", 
               values_to = "SMC") %>%
  mutate(source = recode(source, 
                         obs_SMC_60cm = "Observations (Sensor at 60cm)",
                         sim_SMC_60cm = "Simulation (STEMMUS-SCOPE)")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source)) +
  geom_line(linewidth = 0.8, alpha = 0.8) +
  scale_color_manual(values = c(
    "Observations (Sensor at 60cm)" = "#2166AC",
    "Simulation (STEMMUS-SCOPE)" = "#D6604D"
  )) +
  labs(
    title = "Soil Moisture Content at 60cm Depth",
    subtitle = "DE-STG Steglitz Site | Observations vs STEMMUS-SCOPE Simulation",
    x = "Time",
    y = expression(paste("Volumetric Water Content (", m^3, " ", m^-3, ")")),
    color = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 15),
    panel.grid.minor = element_blank()
  ) +
  coord_cartesian(ylim = c(0.05, 0.45))

ggsave(file.path(plots_dir, "SMC_60cm_timeseries.png"), p1, 
       width = 14, height = 6, dpi = 150)
cat("\nSaved: SMC_60cm_timeseries.png\n")

# --- PLOT 2: Monthly Aggregated ---
monthly <- comparison %>%
  filter(!is.na(sim_SMC_60cm)) %>%
  mutate(month = floor_date(timestamp, "month")) %>%
  group_by(month) %>%
  summarise(
    obs_mean = mean(obs_SMC_60cm, na.rm = TRUE),
    sim_mean = mean(sim_SMC_60cm, na.rm = TRUE),
    .groups = "drop"
  )

p2 <- monthly %>%
  pivot_longer(cols = c(obs_mean, sim_mean), 
               names_to = "source", 
               values_to = "SMC") %>%
  mutate(source = recode(source,
                         obs_mean = "Observations",
                         sim_mean = "Simulation")) %>%
  ggplot(aes(x = month, y = SMC, color = source, group = source)) +
  geom_line(linewidth = 1.5) +
  geom_point(size = 4) +
  scale_x_datetime(date_labels = "%b %Y", date_breaks = "1 month") +
  scale_color_manual(values = c("Observations" = "#2166AC", "Simulation" = "#D6604D")) +
  labs(
    title = "Monthly Mean Soil Moisture (60cm)",
    x = "Month",
    y = expression(paste("Mean SMC (", m^3, " ", m^-3, ")")),
    color = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 15),
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  coord_cartesian(ylim = c(0.05, 0.45))

ggsave(file.path(plots_dir, "SMC_60cm_monthly.png"), p2, 
       width = 12, height = 6, dpi = 150)
cat("Saved: SMC_60cm_monthly.png\n")

# --- PLOT 3: Scatter Plot ---
p3 <- comparison %>%
  filter(!is.na(obs_SMC_60cm), !is.na(sim_SMC_60cm)) %>%
  ggplot(aes(x = obs_SMC_60cm, y = sim_SMC_60cm)) +
  geom_point(alpha = 0.4, color = "#4393C3", size = 2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", 
              color = "red", linewidth = 1.2) +
  geom_smooth(method = "lm", color = "#D6604D", se = TRUE, alpha = 0.2) +
  labs(
    title = "Observed vs Simulated Soil Moisture (60cm)",
    subtitle = "1:1 line (red dashed) | Linear fit (red solid)",
    x = expression(paste("Observed SMC (", m^3, " ", m^-3, ")")),
    y = expression(paste("Simulated SMC (", m^3, " ", m^-3, ")"))
  ) +
  coord_equal(xlim = c(0, 0.5), ylim = c(0, 0.5)) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 15))

ggsave(file.path(plots_dir, "SMC_60cm_scatter.png"), p3, 
       width = 8, height = 8, dpi = 150)
cat("Saved: SMC_60cm_scatter.png\n")


# --- PLOT 4: 3-Way Comparison (Obs vs Sim vs Precip) ---
# Reshape data for plotting
plot_data <- comparison %>%
  filter(!is.na(sim_SMC_60cm)) 

# Top panel: Precipitation
p_precip <- ggplot(plot_data, aes(x = timestamp, y = prec_mm)) +
  geom_bar(stat = "identity", fill = "blue", alpha = 0.5) +
  scale_y_reverse() + # Rain 'falls' from top usually, or just keep standard
  labs(y = "Precip (mm)", x = NULL, title = "Precipitation & Soil Moisture Comparison") +
  theme_minimal(base_size = 13) +
  theme(axis.text.x = element_blank()) # Hide x-axis text for top plot

# Bottom panel: Soil Moisture
p_smc <- plot_data %>%
  pivot_longer(cols = c(obs_SMC_60cm, sim_SMC_60cm), 
               names_to = "source", 
               values_to = "SMC") %>%
  mutate(source = recode(source, 
                         obs_SMC_60cm = "Observed",
                         sim_SMC_60cm = "Simulated")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("Observed" = "#2166AC", "Simulated" = "#D6604D")) +
  labs(y = expression(paste("SMC (", m^3, "/ ", m^3, ")")), x = "Time") +
  coord_cartesian(ylim = c(0.05, 0.45)) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")

# Combine plots
# library(gridExtra) # Package missing on this environment
# p4 <- grid.arrange(p_precip, p_smc, ncol = 1, heights = c(1, 2))

# ggsave(file.path(plots_dir, "SMC_60cm_3way_comparison.png"), p4, 
#        width = 14, height = 10, dpi = 150)
cat("Skipped: SMC_60cm_3way_comparison.png (gridExtra package missing)\n")
cat("Saved: SMC_60cm_3way_comparison.png\n")

# ============================================================
# SUMMARY STATISTICS
# ============================================================

valid_data <- comparison %>% 
  filter(!is.na(obs_SMC_60cm), !is.na(sim_SMC_60cm))

if (nrow(valid_data) > 0) {
  rmse <- sqrt(mean((valid_data$obs_SMC_60cm - valid_data$sim_SMC_60cm)^2))
  mae <- mean(abs(valid_data$obs_SMC_60cm - valid_data$sim_SMC_60cm))
  bias <- mean(valid_data$sim_SMC_60cm - valid_data$obs_SMC_60cm)
  r <- cor(valid_data$obs_SMC_60cm, valid_data$sim_SMC_60cm)
  r2 <- r^2
  
  cat("\n===== VALIDATION SUMMARY =====\n")
  cat("Soil Moisture at 60cm depth:\n")
  cat("  N matched timesteps:", nrow(valid_data), "\n")
  cat("  RMSE:", round(rmse, 4), "m³/m³\n")
  cat("  MAE:", round(mae, 4), "m³/m³\n")
  cat("  Bias:", round(bias, 4), "m³/m³\n")
  cat("  Correlation (r):", round(r, 3), "\n")
  cat("  R²:", round(r2, 3), "\n")
  cat("\n  Observed mean:", round(mean(valid_data$obs_SMC_60cm), 3), "m³/m³\n")
  cat("  Simulated mean:", round(mean(valid_data$sim_SMC_60cm), 3), "m³/m³\n")
}

cat("\n===== PLOTS SAVED TO =====\n")
cat(plots_dir, "\n\n")
