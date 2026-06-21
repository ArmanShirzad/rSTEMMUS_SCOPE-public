# ============================================================
# compare_matlab_octave.R
# 3-Way Comparison: Observations vs MATLAB vs Octave
# ============================================================
# Created: 2026-02-03
# Purpose: Compare soil moisture outputs from MATLAB and Octave
#          simulations against field observations at 60cm depth
# ============================================================

library(tidyverse)
library(lubridate)

# ============================================================
# CONFIGURATION
# ============================================================

project_root <- getwd()
obs_file <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")

# Octave output (from our 3-month run today)
octave_theta_file <- file.path(project_root, 
  "rSTEMMUS_SCOPE/output/DE-STG_Test_pre_mm_Steglitz_OCTAVE_2026Feb03_1524/Sim_Theta.csv")

# MATLAB output (from previous run, 2 years)
matlab_theta_file <- file.path(project_root, 
  "2026Contributions/validation_plots/Sim_Theta.csv")

# Output folder
output_dir <- file.path(project_root, "2026Contributions/validation_plots/Mat_OctaveComparison")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("=== 3-WAY COMPARISON: MATLAB vs OCTAVE vs OBSERVATIONS ===\n\n")
cat("Observation file:", obs_file, "\n")
cat("Octave output:", octave_theta_file, "\n")
cat("MATLAB output:", matlab_theta_file, "\n")
cat("Output folder:", output_dir, "\n\n")

# ============================================================
# LOAD OBSERVATION DATA
# ============================================================

obs <- readRDS(obs_file)
cat("Observations loaded:", nrow(obs), "rows\n")

# Filter to 3-month period (Jan-Mar 2019) to match Octave run
obs_filtered <- obs %>%
  filter(timestamp >= as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
         timestamp <= as.POSIXct("2019-03-31 23:00:00", tz = "UTC")) %>%
  select(timestamp, obs_SMC_60cm = SMC_60cm, prec_mm) %>%
  mutate(obs_SMC_60cm = obs_SMC_60cm / 100)  # Convert % to m³/m³

cat("Observations filtered to 3-month period:", nrow(obs_filtered), "rows\n")

# ============================================================
# HELPER FUNCTION: Extract 60cm column from Sim_Theta.csv
# ============================================================

extract_smc_60cm <- function(theta_file, label) {
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])
  
  # Find 60cm column
  idx_60cm <- which(depths == 60)
  if (length(idx_60cm) == 0) {
    idx_60cm <- which.min(abs(depths - 60))  # Closest to 60cm
    cat(sprintf("  %s: Exact 60cm not found, using %.0fcm\n", label, depths[idx_60cm]))
  }
  
  # Extract data (skip first 3 rows: depths, thickness, units)
  smc_values <- as.numeric(raw[-(1:3), idx_60cm])
  cat(sprintf("  %s: Loaded %d timesteps, SMC range: %.3f to %.3f\n", 
              label, length(smc_values), min(smc_values), max(smc_values)))
  return(smc_values)
}

# ============================================================
# LOAD OCTAVE OUTPUT
# ============================================================

cat("\nLoading Octave output...\n")
octave_smc <- extract_smc_60cm(octave_theta_file, "Octave")

# Create timestamps for Octave (3 months, hourly)
octave_start <- as.POSIXct("2019-01-01 00:00:00", tz = "UTC")
octave_timestamps <- octave_start + hours(0:(length(octave_smc) - 1))

octave_df <- tibble(
  timestamp = octave_timestamps,
  octave_SMC_60cm = octave_smc
)

# ============================================================
# LOAD MATLAB OUTPUT
# ============================================================

cat("\nLoading MATLAB output...\n")
matlab_smc <- extract_smc_60cm(matlab_theta_file, "MATLAB")

# Create timestamps for MATLAB (starts from obs start)
matlab_start <- min(obs$timestamp)
matlab_timestamps <- matlab_start + hours(0:(length(matlab_smc) - 1))

matlab_df <- tibble(
  timestamp = matlab_timestamps,
  matlab_SMC_60cm = matlab_smc
) %>%
  filter(timestamp >= as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
         timestamp <= as.POSIXct("2019-03-31 23:00:00", tz = "UTC"))

cat("  MATLAB filtered to 3-month period:", nrow(matlab_df), "rows\n")

# ============================================================
# MERGE ALL DATA
# ============================================================

comparison <- obs_filtered %>%
  left_join(octave_df, by = "timestamp") %>%
  left_join(matlab_df, by = "timestamp")

cat("\nMerged comparison data:", nrow(comparison), "rows\n")
cat("  Octave matches:", sum(!is.na(comparison$octave_SMC_60cm)), "\n")
cat("  MATLAB matches:", sum(!is.na(comparison$matlab_SMC_60cm)), "\n")

# ============================================================
# PLOT 1: 3-Way Time Series Comparison
# ============================================================

p1 <- comparison %>%
  select(timestamp, obs_SMC_60cm, octave_SMC_60cm, matlab_SMC_60cm) %>%
  pivot_longer(cols = c(obs_SMC_60cm, octave_SMC_60cm, matlab_SMC_60cm),
               names_to = "source",
               values_to = "SMC") %>%
  mutate(source = recode(source,
                         obs_SMC_60cm = "Observations",
                         octave_SMC_60cm = "Octave Simulation",
                         matlab_SMC_60cm = "MATLAB Simulation")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source)) +
  geom_line(linewidth = 0.8, alpha = 0.85) +
  scale_color_manual(values = c(
    "Observations" = "black",
    "MATLAB Simulation" = "#2166AC",
    "Octave Simulation" = "#B2182B"
  )) +
  labs(
    title = "3-Way Comparison: Soil Moisture at 60cm Depth",
    subtitle = "DE-STG Steglitz Site | Jan-Mar 2019",
    x = "Time",
    y = expression(paste("Volumetric Water Content (", m^3, "/", m^3, ")")),
    color = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 15),
    panel.grid.minor = element_blank()
  ) +
  coord_cartesian(ylim = c(0.05, 0.45))

ggsave(file.path(output_dir, "01_3way_SMC_60cm_timeseries.png"), p1,
       width = 14, height = 6, dpi = 150)
cat("\nSaved: 01_3way_SMC_60cm_timeseries.png\n")

# ============================================================
# PLOT 2: Monthly Aggregated Comparison
# ============================================================

monthly <- comparison %>%
  mutate(month = floor_date(timestamp, "month")) %>%
  group_by(month) %>%
  summarise(
    obs = mean(obs_SMC_60cm, na.rm = TRUE),
    octave = mean(octave_SMC_60cm, na.rm = TRUE),
    matlab = mean(matlab_SMC_60cm, na.rm = TRUE),
    .groups = "drop"
  )

p2 <- monthly %>%
  pivot_longer(cols = c(obs, octave, matlab),
               names_to = "source",
               values_to = "SMC") %>%
  mutate(source = recode(source,
                         obs = "Observations",
                         octave = "Octave",
                         matlab = "MATLAB")) %>%
  ggplot(aes(x = month, y = SMC, color = source, group = source)) +
  geom_line(linewidth = 1.5) +
  geom_point(size = 4) +
  scale_x_datetime(date_labels = "%b %Y", date_breaks = "1 month") +
  scale_color_manual(values = c(
    "Observations" = "black",
    "MATLAB" = "#2166AC",
    "Octave" = "#B2182B"
  )) +
  labs(
    title = "Monthly Mean Soil Moisture (60cm)",
    subtitle = "3-Way Comparison: Observations vs MATLAB vs Octave",
    x = "Month",
    y = expression(paste("Mean SMC (", m^3, "/", m^3, ")")),
    color = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 15)
  ) +
  coord_cartesian(ylim = c(0.15, 0.45))

ggsave(file.path(output_dir, "02_3way_monthly_comparison.png"), p2,
       width = 12, height = 6, dpi = 150)
cat("Saved: 02_3way_monthly_comparison.png\n")

# ============================================================
# PLOT 3: MATLAB vs Octave Direct Comparison (Scatter)
# ============================================================

p3 <- comparison %>%
  filter(!is.na(octave_SMC_60cm), !is.na(matlab_SMC_60cm)) %>%
  ggplot(aes(x = matlab_SMC_60cm, y = octave_SMC_60cm)) +
  geom_point(alpha = 0.5, color = "#4393C3", size = 2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", 
              color = "red", linewidth = 1.2) +
  geom_smooth(method = "lm", color = "#D6604D", se = TRUE, alpha = 0.2) +
  labs(
    title = "MATLAB vs Octave: Soil Moisture at 60cm",
    subtitle = "Perfect agreement = points on red dashed 1:1 line",
    x = expression(paste("MATLAB SMC (", m^3, "/", m^3, ")")),
    y = expression(paste("Octave SMC (", m^3, "/", m^3, ")"))
  ) +
  coord_equal(xlim = c(0.2, 0.5), ylim = c(0.2, 0.5)) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 15))

ggsave(file.path(output_dir, "03_matlab_vs_octave_scatter.png"), p3,
       width = 8, height = 8, dpi = 150)
cat("Saved: 03_matlab_vs_octave_scatter.png\n")

# ============================================================
# SUMMARY STATISTICS
# ============================================================

valid_data <- comparison %>%
  filter(!is.na(obs_SMC_60cm), !is.na(octave_SMC_60cm), !is.na(matlab_SMC_60cm))

if (nrow(valid_data) > 0) {
  # Octave vs Observations
  rmse_octave <- sqrt(mean((valid_data$obs_SMC_60cm - valid_data$octave_SMC_60cm)^2))
  bias_octave <- mean(valid_data$octave_SMC_60cm - valid_data$obs_SMC_60cm)
  r_octave <- cor(valid_data$obs_SMC_60cm, valid_data$octave_SMC_60cm)
  
  # MATLAB vs Observations
  rmse_matlab <- sqrt(mean((valid_data$obs_SMC_60cm - valid_data$matlab_SMC_60cm)^2))
  bias_matlab <- mean(valid_data$matlab_SMC_60cm - valid_data$obs_SMC_60cm)
  r_matlab <- cor(valid_data$obs_SMC_60cm, valid_data$matlab_SMC_60cm)
  
  # Octave vs MATLAB (equivalence)
  rmse_equiv <- sqrt(mean((valid_data$matlab_SMC_60cm - valid_data$octave_SMC_60cm)^2))
  r_equiv <- cor(valid_data$matlab_SMC_60cm, valid_data$octave_SMC_60cm)
  
  cat("\n===== VALIDATION SUMMARY =====\n")
  cat("Matched timesteps:", nrow(valid_data), "\n\n")
  
  cat("Octave vs Observations:\n")
  cat(sprintf("   RMSE: %.4f m³/m³ | Bias: %.4f | r: %.3f\n", rmse_octave, bias_octave, r_octave))
  
  cat("MATLAB vs Observations:\n")
  cat(sprintf("   RMSE: %.4f m³/m³ | Bias: %.4f | r: %.3f\n", rmse_matlab, bias_matlab, r_matlab))
  
  cat("\nOctave vs MATLAB (Equivalence Check):\n")
  cat(sprintf("   RMSE: %.4f m³/m³ | r: %.3f\n", rmse_equiv, r_equiv))
  
  if (rmse_equiv < 0.01) {
    cat("   ✅ EXCELLENT: Octave and MATLAB outputs are nearly identical!\n")
  } else if (rmse_equiv < 0.05) {
    cat("   ⚠️ ACCEPTABLE: Small numerical differences between engines.\n")
  } else {
    cat("   ❌ INVESTIGATE: Significant differences between engines.\n")
  }
}

cat("\n===== PLOTS SAVED TO =====\n")
cat(output_dir, "\n\n")
