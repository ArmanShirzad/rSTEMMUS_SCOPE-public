# ============================================================
# fair_comparison.R
# Apples-to-apples: compare Run 1 (SMC fix only, 91.7%)
# vs Run 2 (Temp+SMC fix, 100%) over the SAME time window
# ============================================================

library(tidyverse)
library(lubridate)

project_root <- getwd()

# --- Observation data ---
obs <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
obs_filtered <- obs %>%
  filter(timestamp >= as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
         timestamp <= as.POSIXct("2019-06-30 23:00:00", tz = "UTC")) %>%
  select(timestamp, obs_SMC_60cm = SMC_60cm) %>%
  mutate(obs_SMC_60cm = obs_SMC_60cm / 100)

# --- Helper: extract SMC at 60cm ---
extract_smc_60cm <- function(theta_file) {
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])
  idx_60cm <- which.min(abs(depths - 60))
  smc_values <- as.numeric(raw[-(1:3), idx_60cm])
  return(smc_values)
}

# --- MATLAB baseline ---
matlab_file <- "2026Contributions/validation_plots/Sim_Theta.csv"
matlab_smc <- extract_smc_60cm(matlab_file)
matlab_start <- min(obs$timestamp)
matlab_df <- tibble(
  timestamp = matlab_start + hours(0:(length(matlab_smc) - 1)),
  matlab_SMC = matlab_smc
) %>% filter(timestamp >= as.POSIXct("2019-01-01", tz = "UTC"),
             timestamp <= as.POSIXct("2019-06-30 23:00", tz = "UTC"))

# --- Run 1: SMC fix only (recovered, 91.7%) ---
run1_file <- "rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_6mo_OCTAVE_2026Feb11_1721/Sim_Theta.csv"
run1_smc <- extract_smc_60cm(run1_file)
run1_df <- tibble(
  timestamp = as.POSIXct("2019-01-01 00:00:00", tz = "UTC") + hours(0:(length(run1_smc) - 1)),
  run1_SMC = run1_smc
)

# --- Run 2: Temp+SMC fix (complete, 100%) ---
run2_file <- "rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_TempSMC_6mo_OCTAVE_2026Feb13_1041/Sim_Theta.csv"
run2_smc <- extract_smc_60cm(run2_file)
run2_df <- tibble(
  timestamp = as.POSIXct("2019-01-01 00:00:00", tz = "UTC") + hours(0:(length(run2_smc) - 1)),
  run2_SMC = run2_smc
)

# --- Merge all ---
all_data <- obs_filtered %>%
  left_join(matlab_df, by = "timestamp") %>%
  left_join(run1_df, by = "timestamp") %>%
  left_join(run2_df, by = "timestamp")

cat("Total observations:", nrow(all_data), "\n")
cat("Run 1 available:", sum(!is.na(all_data$run1_SMC)), "timesteps\n")
cat("Run 2 available:", sum(!is.na(all_data$run2_SMC)), "timesteps\n")

# --- FAIR COMPARISON: over ONLY the first 3,984 timesteps (Run 1's coverage) ---
fair_window <- all_data %>%
  filter(!is.na(run1_SMC), !is.na(run2_SMC), !is.na(matlab_SMC))

cat("\n======================================================\n")
cat("  FAIR COMPARISON: Same time window (first", nrow(fair_window), "timesteps)\n")
cat("  Period:", as.character(min(fair_window$timestamp)), "to", as.character(max(fair_window$timestamp)), "\n")
cat("======================================================\n\n")

# Run 1 vs MATLAB (over overlapping period)
run1_bias <- mean(fair_window$run1_SMC - fair_window$matlab_SMC, na.rm = TRUE)
run1_rmse <- sqrt(mean((fair_window$run1_SMC - fair_window$matlab_SMC)^2, na.rm = TRUE))
run1_r <- cor(fair_window$run1_SMC, fair_window$matlab_SMC, use = "complete.obs")

# Run 2 vs MATLAB (SAME period only)
run2_bias <- mean(fair_window$run2_SMC - fair_window$matlab_SMC, na.rm = TRUE)
run2_rmse <- sqrt(mean((fair_window$run2_SMC - fair_window$matlab_SMC)^2, na.rm = TRUE))
run2_r <- cor(fair_window$run2_SMC, fair_window$matlab_SMC, use = "complete.obs")

# Run 1 vs Obs
run1_obs_rmse <- sqrt(mean((fair_window$run1_SMC - fair_window$obs_SMC_60cm)^2, na.rm = TRUE))
# Run 2 vs Obs
run2_obs_rmse <- sqrt(mean((fair_window$run2_SMC - fair_window$obs_SMC_60cm)^2, na.rm = TRUE))
# MATLAB vs Obs
mat_obs_rmse <- sqrt(mean((fair_window$matlab_SMC - fair_window$obs_SMC_60cm)^2, na.rm = TRUE))

cat(sprintf("%-35s %-20s %-20s\n", "Metric", "Run 1 (SMC fix)", "Run 2 (Temp+SMC fix)"))
cat(paste(rep("-", 75), collapse=""), "\n")
cat(sprintf("%-35s %-20s %-20s\n", "Fixes applied", "SMC /100 only", "SMC /100 + Temp +273"))
cat(sprintf("%-35s %-20s %-20s\n", "Tss in soil_init.mat", "-266.85 C", "6.30 C"))
cat(sprintf("%-35s %-20s %-20s\n", "Coverage", "91.7% (crashed)", "100% (complete)"))
cat(sprintf("%-35s %-20.4f %-20.4f\n", "vs MATLAB: Bias", run1_bias, run2_bias))
cat(sprintf("%-35s %-20.4f %-20.4f\n", "vs MATLAB: RMSE", run1_rmse, run2_rmse))
cat(sprintf("%-35s %-20.4f %-20.4f\n", "vs MATLAB: Correlation (r)", run1_r, run2_r))
cat(sprintf("%-35s %-20.4f %-20.4f\n", "vs Observations: RMSE", run1_obs_rmse, run2_obs_rmse))
cat(sprintf("%-35s %-20.4f %-20.4f\n", "MATLAB vs Obs: RMSE", mat_obs_rmse, mat_obs_rmse))

cat(sprintf("\nInitial values @ 60cm (t=0):\n"))
cat(sprintf("  Run 1: %.4f\n", all_data$run1_SMC[1]))
cat(sprintf("  Run 2: %.4f\n", all_data$run2_SMC[1]))
cat(sprintf("  MATLAB: %.4f\n", all_data$matlab_SMC[1]))
cat(sprintf("  Observations: %.4f\n", all_data$obs_SMC_60cm[1]))

# --- FULL RUN 2 stats (all 4,344 timesteps) ---
full_run2 <- all_data %>% filter(!is.na(run2_SMC), !is.na(matlab_SMC))
run2_full_bias <- mean(full_run2$run2_SMC - full_run2$matlab_SMC, na.rm = TRUE)
run2_full_rmse <- sqrt(mean((full_run2$run2_SMC - full_run2$matlab_SMC)^2, na.rm = TRUE))
run2_full_r <- cor(full_run2$run2_SMC, full_run2$matlab_SMC, use = "complete.obs")

cat(sprintf("\n%-35s %-20s %-20s\n", "", "Run 2 (same window)", "Run 2 (full 100%%)"))
cat(paste(rep("-", 75), collapse=""), "\n")
cat(sprintf("%-35s %-20d %-20d\n", "Timesteps compared", nrow(fair_window), nrow(full_run2)))
cat(sprintf("%-35s %-20.4f %-20.4f\n", "vs MATLAB: Bias", run2_bias, run2_full_bias))
cat(sprintf("%-35s %-20.4f %-20.4f\n", "vs MATLAB: RMSE", run2_rmse, run2_full_rmse))
cat(sprintf("%-35s %-20.4f %-20.4f\n", "vs MATLAB: Correlation (r)", run2_r, run2_full_r))

delta_rmse <- run2_rmse - run1_rmse
pct_change <- (run2_rmse - run1_rmse) / run1_rmse * 100
cat(sprintf("\n===== VERDICT (fair comparison, same time window) =====\n"))
cat(sprintf("  RMSE change: %.4f -> %.4f (delta: %+.4f, %+.1f%%)\n", run1_rmse, run2_rmse, delta_rmse, pct_change))
cat(sprintf("  Bias change: %+.4f -> %+.4f\n", run1_bias, run2_bias))
cat(sprintf("  Corr change: %.4f -> %.4f\n", run1_r, run2_r))

if (abs(pct_change) < 3) {
  cat("  => RMSE essentially unchanged (within noise)\n")
} else if (pct_change < 0) {
  cat("  => Temp fix IMPROVED RMSE\n")
} else {
  cat("  => Temp fix made RMSE slightly worse\n")
}
