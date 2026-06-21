# ============================================================================
# validate_multi_depth.R
# Multi-Depth Validation: MATLAB vs Octave vs Observations
# ============================================================================
# Purpose:  Extend the definitive 60cm validation (Contribution #36) to all
#           available observation depths (10cm, 20cm, 30cm, 60cm).
#           Uses EXISTING 2yr simulation outputs — no new runs needed.
#
# Key claim: "MATLAB-Octave engine parity holds across all soil depths"
#
# Created:  2026-05-10
# Author:   Arman Shirzad
# ============================================================================

library(tidyverse)
library(lubridate)

# ============================================================================
# 1. CONFIGURATION — UPDATE THESE PATHS
# ============================================================================

project_root <- getwd()
obs_file     <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")

# Point to the definitive 2yr runs from April 22 (Contribution #36)
# Definitive 2yr runs (Contribution #36)
matlab_theta_file <- file.path(project_root,
  "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_final_soilprops_MATLAB_2026Apr22_1927/Sim_Theta.csv")

octave_theta_file <- file.path(project_root,
  "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_final_soilprops_OCTAVE_2026Apr20_1646/Sim_Theta.csv")

# Observation depth columns in the .rds file → model depths in Sim_Theta
depth_map <- tibble(
  obs_col   = c("SMC_10cm", "SMC_20cm", "SMC_30cm", "SMC_60cm"),
  depth_cm  = c(10, 20, 30, 60),
  label     = c("10 cm", "20 cm", "30 cm", "60 cm")
)

# Simulation time window
sim_start <- as.POSIXct("2019-01-01 00:00:00", tz = "UTC")
sim_end   <- as.POSIXct("2020-12-31 23:00:00", tz = "UTC")

# Output directory
output_dir <- file.path(project_root, "2026Contributions/validation_plots_multidepth")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("================================================================\n")
cat("  MULTI-DEPTH VALIDATION: MATLAB vs OCTAVE vs OBSERVATIONS\n")
cat("================================================================\n\n")

# ============================================================================
# 2. HELPER FUNCTIONS
# ============================================================================

# Extract SMC column for a given target depth from Sim_Theta.csv
extract_smc_at_depth <- function(theta_file, target_depth_cm, label) {
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])

  # Find column closest to target depth
  idx <- which.min(abs(depths - target_depth_cm))
  actual_depth <- depths[idx]

  if (abs(actual_depth - target_depth_cm) > 5) {
    warning(sprintf("  %s: Target %dcm, nearest is %.0fcm (>5cm off!)",
                    label, target_depth_cm, actual_depth))
  }

  smc_values <- as.numeric(raw[-(1:3), idx])
  cat(sprintf("  %s @ %dcm (col %d, actual %.0fcm): %d timesteps, range [%.4f, %.4f]\n",
              label, target_depth_cm, idx, actual_depth,
              length(smc_values), min(smc_values, na.rm=T), max(smc_values, na.rm=T)))
  return(smc_values)
}

# Compute KGE (Kling-Gupta Efficiency)
compute_KGE <- function(sim, obs) {
  valid <- !is.na(sim) & !is.na(obs)
  s <- sim[valid]; o <- obs[valid]
  if (length(s) < 10) return(NA)
  r_val  <- cor(s, o)
  alpha  <- sd(s) / sd(o)
  beta   <- mean(s) / mean(o)
  kge    <- 1 - sqrt((r_val - 1)^2 + (alpha - 1)^2 + (beta - 1)^2)
  return(kge)
}

# ============================================================================
# 3. LOAD OBSERVATIONS
# ============================================================================

cat("\nLoading observations...\n")
obs <- readRDS(obs_file)
obs_filtered <- obs %>%
  filter(timestamp >= sim_start, timestamp <= sim_end)
cat(sprintf("  Observations: %d rows (%s to %s)\n",
            nrow(obs_filtered),
            format(min(obs_filtered$timestamp), "%Y-%m-%d"),
            format(max(obs_filtered$timestamp), "%Y-%m-%d")))

# ============================================================================
# 4. LOAD SIMULATIONS & COMPUTE METRICS AT EACH DEPTH
# ============================================================================

cat("\nLoading simulation outputs...\n")

# Check files exist
if (!file.exists(matlab_theta_file)) {
  stop("MATLAB Sim_Theta.csv not found at:\n  ", matlab_theta_file,
       "\n  Please update 'matlab_theta_file' in the configuration section.")
}
if (!file.exists(octave_theta_file)) {
  stop("Octave Sim_Theta.csv not found at:\n  ", octave_theta_file,
       "\n  Please update 'octave_theta_file' in the configuration section.")
}

# Results accumulator
results <- tibble()

for (i in seq_len(nrow(depth_map))) {
  d <- depth_map[i, ]
  cat(sprintf("\n--- Depth: %s ---\n", d$label))

  # Extract simulated SMC
  mat_smc <- extract_smc_at_depth(matlab_theta_file, d$depth_cm, "MATLAB")
  oct_smc <- extract_smc_at_depth(octave_theta_file, d$depth_cm, "Octave")

  # Build timestamps (hourly from sim_start)
  mat_ts <- sim_start + hours(0:(length(mat_smc) - 1))
  oct_ts <- sim_start + hours(0:(length(oct_smc) - 1))

  # Get observations for this depth
  if (!d$obs_col %in% names(obs_filtered)) {
    cat(sprintf("  WARNING: Column '%s' not found in observations. Skipping.\n", d$obs_col))
    next
  }
  obs_smc_raw <- obs_filtered[[d$obs_col]]
  obs_smc     <- obs_smc_raw / 100  # Convert % → m³/m³
  obs_ts      <- obs_filtered$timestamp

  # Merge on timestamp
  df_mat <- tibble(timestamp = mat_ts, sim_matlab = mat_smc)
  df_oct <- tibble(timestamp = oct_ts, sim_octave = oct_smc)
  df_obs <- tibble(timestamp = obs_ts, obs = obs_smc)

  merged <- df_obs %>%
    left_join(df_mat, by = "timestamp") %>%
    left_join(df_oct, by = "timestamp") %>%
    filter(!is.na(obs), !is.na(sim_matlab), !is.na(sim_octave))

  cat(sprintf("  Merged: %d valid timesteps\n", nrow(merged)))

  if (nrow(merged) < 100) {
    cat("  WARNING: Too few data points. Check time alignment.\n")
    next
  }

  # Compute metrics
  r_mat_obs <- cor(merged$sim_matlab, merged$obs, use = "complete.obs")
  r_oct_obs <- cor(merged$sim_octave, merged$obs, use = "complete.obs")
  r_mat_oct <- cor(merged$sim_matlab, merged$sim_octave, use = "complete.obs")

  rmse_mat_obs <- sqrt(mean((merged$sim_matlab - merged$obs)^2, na.rm = TRUE))
  rmse_oct_obs <- sqrt(mean((merged$sim_octave - merged$obs)^2, na.rm = TRUE))
  rmse_mat_oct <- sqrt(mean((merged$sim_matlab - merged$sim_octave)^2, na.rm = TRUE))

  bias_mat_obs <- mean(merged$sim_matlab - merged$obs, na.rm = TRUE)
  bias_oct_obs <- mean(merged$sim_octave - merged$obs, na.rm = TRUE)
  bias_mat_oct <- mean(merged$sim_matlab - merged$sim_octave, na.rm = TRUE)

  kge_mat_obs <- compute_KGE(merged$sim_matlab, merged$obs)
  kge_oct_obs <- compute_KGE(merged$sim_octave, merged$obs)

  # Check for Octave dry-collapse anomaly (SMC near zero)
  oct_zero_count <- sum(merged$sim_octave < 0.001, na.rm = TRUE)

  results <- bind_rows(results, tibble(
    depth = d$label, depth_cm = d$depth_cm,
    r_mat_obs, r_oct_obs, r_mat_oct,
    rmse_mat_obs, rmse_oct_obs, rmse_mat_oct,
    bias_mat_obs, bias_oct_obs, bias_mat_oct,
    kge_mat_obs, kge_oct_obs,
    n_points = nrow(merged),
    octave_zero_count = oct_zero_count
  ))

  cat(sprintf("  MATLAB vs Obs:  r=%.3f  KGE=%.3f  RMSE=%.4f  Bias=%+.4f\n",
              r_mat_obs, kge_mat_obs, rmse_mat_obs, bias_mat_obs))
  cat(sprintf("  Octave vs Obs:  r=%.3f  KGE=%.3f  RMSE=%.4f  Bias=%+.4f\n",
              r_oct_obs, kge_oct_obs, rmse_oct_obs, bias_oct_obs))
  cat(sprintf("  MATLAB vs Oct:  r=%.3f  RMSE=%.4f  Bias=%+.4f\n",
              r_mat_oct, rmse_mat_oct, bias_mat_oct))
  if (oct_zero_count > 0) {
    cat(sprintf("  ⚠️  Octave dry-collapse: %d timesteps with SMC < 0.001\n", oct_zero_count))
  }
}

# ============================================================================
# 5. SUMMARY TABLE
# ============================================================================

cat("\n\n================================================================\n")
cat("  MULTI-DEPTH SUMMARY TABLE\n")
cat("================================================================\n\n")

cat("MATLAB vs Observations:\n")
cat(sprintf("%-8s  %6s  %6s  %8s  %8s\n", "Depth", "r", "KGE", "RMSE", "Bias"))
cat(paste(rep("-", 45), collapse = ""), "\n")
for (i in seq_len(nrow(results))) {
  r <- results[i, ]
  cat(sprintf("%-8s  %6.3f  %6.3f  %8.4f  %+8.4f\n",
              r$depth, r$r_mat_obs, r$kge_mat_obs, r$rmse_mat_obs, r$bias_mat_obs))
}

cat("\nOctave vs Observations:\n")
cat(sprintf("%-8s  %6s  %6s  %8s  %8s  %s\n", "Depth", "r", "KGE", "RMSE", "Bias", "Zero-SMC"))
cat(paste(rep("-", 60), collapse = ""), "\n")
for (i in seq_len(nrow(results))) {
  r <- results[i, ]
  flag <- ifelse(r$octave_zero_count > 0, sprintf("⚠️ %d", r$octave_zero_count), "✅ 0")
  cat(sprintf("%-8s  %6.3f  %6.3f  %8.4f  %+8.4f  %s\n",
              r$depth, r$r_oct_obs, r$kge_oct_obs, r$rmse_oct_obs, r$bias_oct_obs, flag))
}

cat("\nEngine Parity (MATLAB vs Octave):\n")
cat(sprintf("%-8s  %6s  %8s  %8s\n", "Depth", "r", "RMSE", "Bias"))
cat(paste(rep("-", 35), collapse = ""), "\n")
for (i in seq_len(nrow(results))) {
  r <- results[i, ]
  cat(sprintf("%-8s  %6.3f  %8.4f  %+8.4f\n",
              r$depth, r$r_mat_oct, r$rmse_mat_oct, r$bias_mat_oct))
}

# ============================================================================
# 6. PASS/FAIL ASSESSMENT
# ============================================================================

cat("\n\n================================================================\n")
cat("  PASS/FAIL ASSESSMENT\n")
cat("================================================================\n\n")

# Engine parity check
parity_pass <- all(abs(results$bias_mat_oct) < 0.05)
cat(sprintf("1. Engine parity (all depths, |bias| < 0.05): %s\n",
            ifelse(parity_pass, "✅ PASS", "❌ FAIL")))

# Model skill check
skill_pass <- all(results$r_mat_obs > 0.5) && all(results$r_oct_obs > 0.5)
cat(sprintf("2. Model skill (all depths, r > 0.5 vs obs):  %s\n",
            ifelse(skill_pass, "✅ PASS", "❌ FAIL")))

# Octave anomaly check
anomaly_pass <- all(results$octave_zero_count == 0)
cat(sprintf("3. Octave dry-collapse absent:                %s\n",
            ifelse(anomaly_pass, "✅ PASS", "⚠️  PRESENT (see depths above)")))

# ============================================================================
# 7. SAVE RESULTS
# ============================================================================

csv_file <- file.path(output_dir, "multi_depth_metrics.csv")
write.csv(results, csv_file, row.names = FALSE)
cat(sprintf("\nMetrics saved to: %s\n", csv_file))

# ============================================================================
# 8. PLOT: Multi-Depth Metric Comparison
# ============================================================================

cat("\nGenerating multi-depth comparison plot...\n")

plot_data <- results %>%
  select(depth, r_mat_obs, r_oct_obs, r_mat_oct) %>%
  pivot_longer(cols = starts_with("r_"),
               names_to = "comparison", values_to = "correlation") %>%
  mutate(
    comparison = recode(comparison,
      r_mat_obs = "MATLAB vs Obs",
      r_oct_obs = "Octave vs Obs",
      r_mat_oct = "MATLAB vs Octave"),
    depth = factor(depth, levels = c("10 cm", "20 cm", "30 cm", "60 cm"))
  )

p_corr <- ggplot(plot_data, aes(x = depth, y = correlation, fill = comparison)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
  scale_fill_manual(values = c(
    "MATLAB vs Obs"    = "#2166AC",
    "Octave vs Obs"    = "#B2182B",
    "MATLAB vs Octave" = "#4DAF4A"
  )) +
  geom_hline(yintercept = 0.8, linetype = "dashed", color = "gray40", linewidth = 0.5) +
  annotate("text", x = 0.6, y = 0.82, label = "r = 0.8 target", hjust = 0, size = 3, color = "gray40") +
  labs(
    title = "Multi-Depth Correlation Comparison",
    subtitle = "DE-STG Steglitz | 2yr Simulation | MATLAB vs Octave vs Observations",
    x = "Soil Depth",
    y = "Pearson Correlation (r)",
    fill = "Comparison"
  ) +
  coord_cartesian(ylim = c(0, 1)) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 15),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(output_dir, "01_multi_depth_correlation.png"), p_corr,
       width = 10, height = 6, dpi = 150)
cat("Saved: 01_multi_depth_correlation.png\n")

# RMSE by depth
plot_rmse <- results %>%
  select(depth, rmse_mat_obs, rmse_oct_obs, rmse_mat_oct) %>%
  pivot_longer(cols = starts_with("rmse_"),
               names_to = "comparison", values_to = "rmse") %>%
  mutate(
    comparison = recode(comparison,
      rmse_mat_obs = "MATLAB vs Obs",
      rmse_oct_obs = "Octave vs Obs",
      rmse_mat_oct = "MATLAB vs Octave"),
    depth = factor(depth, levels = c("10 cm", "20 cm", "30 cm", "60 cm"))
  )

p_rmse <- ggplot(plot_rmse, aes(x = depth, y = rmse, fill = comparison)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
  scale_fill_manual(values = c(
    "MATLAB vs Obs"    = "#2166AC",
    "Octave vs Obs"    = "#B2182B",
    "MATLAB vs Octave" = "#4DAF4A"
  )) +
  labs(
    title = "Multi-Depth RMSE Comparison",
    subtitle = "DE-STG Steglitz | 2yr Simulation",
    x = "Soil Depth",
    y = expression(paste("RMSE (", m^3, "/", m^3, ")")),
    fill = "Comparison"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 15),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(output_dir, "02_multi_depth_rmse.png"), p_rmse,
       width = 10, height = 6, dpi = 150)
cat("Saved: 02_multi_depth_rmse.png\n")

cat("\n================================================================\n")
cat("  VALIDATION COMPLETE\n")
cat("  Results saved to:", output_dir, "\n")
cat("================================================================\n")
