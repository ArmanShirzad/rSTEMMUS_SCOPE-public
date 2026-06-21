# ============================================================
# compare_6mo_matlab_octave.R
# 3-Way Comparison: Observations vs MATLAB vs Octave (FIXED)
# 6-Month Period (Jan-Jun 2019) - Recovered Simulation
# ============================================================
# Created: 2026-02-13
# Purpose: Full diagnostic comparison suite for the 6-month
#          simulation (92% recovered after SIGHUP interruption)
#          Replicates the 3-month Mat_OctaveComparison plots
# ============================================================

library(tidyverse)
library(lubridate)

# ============================================================
# CONFIGURATION
# ============================================================

project_root <- getwd()
obs_file <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")

# Octave output (6-month FIXED run, recovered)
octave_theta_file <- file.path(project_root,
  "rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_6mo_OCTAVE_2026Feb11_1721/Sim_Theta.csv")

# MATLAB output (the reference confirmed 2-year run)
matlab_theta_file <- file.path(project_root,
  "2026Contributions/validation_plots/Sim_Theta.csv")

# Output folder (replaces contents of validation_plots_6mo)
output_dir <- file.path(project_root, "2026Contributions/validation_plots_6mo")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("===================================================================\n")
cat("  6-MONTH COMPARISON: MATLAB vs OCTAVE (FIXED) vs OBSERVATIONS    \n")
cat("===================================================================\n\n")
cat("Observation file:", obs_file, "\n")
cat("Octave output:", octave_theta_file, "\n")
cat("MATLAB output:", matlab_theta_file, "\n")
cat("Output folder:", output_dir, "\n\n")

# ============================================================
# HELPER: Extract 60cm column from Sim_Theta.csv
# ============================================================

extract_smc_60cm <- function(theta_file, label) {
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])

  idx_60cm <- which(depths == 60)
  if (length(idx_60cm) == 0) {
    idx_60cm <- which.min(abs(depths - 60))
    cat(sprintf("  %s: Exact 60cm not found, using %.0fcm\n", label, depths[idx_60cm]))
  }

  smc_values <- as.numeric(raw[-(1:3), idx_60cm])
  cat(sprintf("  %s: Loaded %d timesteps, SMC range: %.4f to %.4f\n",
              label, length(smc_values), min(smc_values), max(smc_values)))
  return(smc_values)
}

# ============================================================
# LOAD ALL DATA
# ============================================================

cat("Loading data...\n")

# Observations - filter to 6-month period
obs <- readRDS(obs_file)
obs_filtered <- obs %>%
  filter(timestamp >= as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
         timestamp <= as.POSIXct("2019-06-30 23:00:00", tz = "UTC")) %>%
  select(timestamp, obs_SMC_60cm = SMC_60cm, prec_mm) %>%
  mutate(obs_SMC_60cm = obs_SMC_60cm / 100)  # Convert % to m³/m³

cat("  Observations filtered to 6-month period:", nrow(obs_filtered), "rows\n")

# Octave (FIXED, 6-month, recovered ~92%)
cat("\nLoading Octave FIXED output...\n")
octave_smc <- extract_smc_60cm(octave_theta_file, "Octave FIXED")
octave_start <- as.POSIXct("2019-01-01 00:00:00", tz = "UTC")
octave_timestamps <- octave_start + hours(0:(length(octave_smc) - 1))
octave_df <- tibble(
  timestamp = octave_timestamps,
  octave_SMC_60cm = octave_smc
)

# MATLAB (2-year run, filter to same period)
cat("\nLoading MATLAB output...\n")
matlab_smc <- extract_smc_60cm(matlab_theta_file, "MATLAB")
matlab_start <- min(obs$timestamp)
matlab_timestamps <- matlab_start + hours(0:(length(matlab_smc) - 1))
matlab_df <- tibble(
  timestamp = matlab_timestamps,
  matlab_SMC_60cm = matlab_smc
) %>%
  filter(timestamp >= as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
         timestamp <= as.POSIXct("2019-06-30 23:00:00", tz = "UTC"))

cat("  MATLAB filtered to 6-month period:", nrow(matlab_df), "rows\n")

# ============================================================
# MERGE ALL DATA
# ============================================================

comparison <- obs_filtered %>%
  left_join(octave_df, by = "timestamp") %>%
  left_join(matlab_df, by = "timestamp") %>%
  mutate(
    diff_oct_mat = octave_SMC_60cm - matlab_SMC_60cm,
    diff_oct_obs = octave_SMC_60cm - obs_SMC_60cm,
    diff_mat_obs = matlab_SMC_60cm - obs_SMC_60cm,
    hour = hour(timestamp),
    day = as.Date(timestamp),
    week = week(timestamp),
    month = month(timestamp, label = TRUE),
    timestep = row_number()
  )

cat("\nMerged comparison data:", nrow(comparison), "rows\n")
cat("  Octave matches:", sum(!is.na(comparison$octave_SMC_60cm)), "\n")
cat("  MATLAB matches:", sum(!is.na(comparison$matlab_SMC_60cm)), "\n")

# ============================================================
# 0. INITIAL VALUE CHECK
# ============================================================

cat("\n===== 0. INITIAL VALUE FIX VERIFICATION =====\n\n")
cat(sprintf("  Observations (t=0):   %.4f m³/m³\n", comparison$obs_SMC_60cm[1]))
cat(sprintf("  MATLAB (t=0):         %.4f m³/m³\n", comparison$matlab_SMC_60cm[1]))
cat(sprintf("  Octave FIXED (t=0):   %.4f m³/m³\n", comparison$octave_SMC_60cm[1]))

pct_err_oct_old <- abs(0.2701 - comparison$obs_SMC_60cm[1]) / comparison$obs_SMC_60cm[1] * 100
pct_err_matlab <- abs(comparison$matlab_SMC_60cm[1] - comparison$obs_SMC_60cm[1]) / comparison$obs_SMC_60cm[1] * 100
pct_err_oct_fix <- abs(comparison$octave_SMC_60cm[1] - comparison$obs_SMC_60cm[1]) / comparison$obs_SMC_60cm[1] * 100

cat(sprintf("\n  Percentage error vs Observations:\n"))
cat(sprintf("    Octave OLD (broken):  %.1f%%  (started at 0.2701)\n", pct_err_oct_old))
cat(sprintf("    MATLAB:               %.1f%%\n", pct_err_matlab))
cat(sprintf("    Octave FIXED:         %.1f%%\n", pct_err_oct_fix))

if (pct_err_oct_fix < pct_err_oct_old) {
  cat("  ✅ Fix improved initial value error!\n")
} else {
  cat("  ⚠️ Fix did not improve — investigate input_constants.\n")
}

# ============================================================
# 1. OVERALL STATISTICS
# ============================================================

cat("\n===== 1. OVERALL STATISTICS =====\n\n")

valid_data <- comparison %>%
  filter(!is.na(obs_SMC_60cm), !is.na(octave_SMC_60cm), !is.na(matlab_SMC_60cm))

summary_stats <- valid_data %>%
  summarise(
    obs_mean = mean(obs_SMC_60cm, na.rm = TRUE),
    octave_mean = mean(octave_SMC_60cm, na.rm = TRUE),
    matlab_mean = mean(matlab_SMC_60cm, na.rm = TRUE),
    oct_mat_bias = mean(diff_oct_mat, na.rm = TRUE),
    oct_mat_rmse = sqrt(mean(diff_oct_mat^2, na.rm = TRUE)),
    oct_mat_max_diff = max(abs(diff_oct_mat), na.rm = TRUE),
    oct_mat_r = cor(octave_SMC_60cm, matlab_SMC_60cm, use = "complete.obs"),
    oct_obs_bias = mean(diff_oct_obs, na.rm = TRUE),
    oct_obs_rmse = sqrt(mean(diff_oct_obs^2, na.rm = TRUE)),
    mat_obs_bias = mean(diff_mat_obs, na.rm = TRUE),
    mat_obs_rmse = sqrt(mean(diff_mat_obs^2, na.rm = TRUE))
  )

cat("Mean Values:\n")
cat(sprintf("  Observations: %.4f m³/m³\n", summary_stats$obs_mean))
cat(sprintf("  MATLAB:       %.4f m³/m³\n", summary_stats$matlab_mean))
cat(sprintf("  Octave FIXED: %.4f m³/m³\n", summary_stats$octave_mean))

cat("\nOctave vs MATLAB (Engine Equivalence):\n")
cat(sprintf("  Bias (Octave - MATLAB): %+.4f m³/m³\n", summary_stats$oct_mat_bias))
cat(sprintf("  RMSE: %.4f m³/m³\n", summary_stats$oct_mat_rmse))
cat(sprintf("  Max Absolute Diff: %.4f m³/m³\n", summary_stats$oct_mat_max_diff))
cat(sprintf("  Correlation: %.4f\n", summary_stats$oct_mat_r))

cat("\nOctave FIXED vs Observations:\n")
cat(sprintf("  Bias: %+.4f m³/m³ (Octave %s)\n",
            summary_stats$oct_obs_bias,
            ifelse(summary_stats$oct_obs_bias > 0, "OVER-predicts", "UNDER-predicts")))
cat(sprintf("  RMSE: %.4f m³/m³\n", summary_stats$oct_obs_rmse))

cat("\nMATLAB vs Observations:\n")
cat(sprintf("  Bias: %+.4f m³/m³ (MATLAB %s)\n",
            summary_stats$mat_obs_bias,
            ifelse(summary_stats$mat_obs_bias > 0, "OVER-predicts", "UNDER-predicts")))
cat(sprintf("  RMSE: %.4f m³/m³\n", summary_stats$mat_obs_rmse))

# ============================================================
# 2. DIVERGENCE TIMELINE
# ============================================================

cat("\n===== 2. DIVERGENCE TIMELINE =====\n")

first_24h <- valid_data %>% filter(timestep <= 24)
first_week <- valid_data %>% filter(timestep <= 168)
first_month <- valid_data %>% filter(timestep <= 720)

cat("\nDivergence at different stages:\n")
cat(sprintf("  First 24 hours: Bias = %+.4f, RMSE = %.4f\n",
            mean(first_24h$diff_oct_mat), sqrt(mean(first_24h$diff_oct_mat^2))))
cat(sprintf("  First week:     Bias = %+.4f, RMSE = %.4f\n",
            mean(first_week$diff_oct_mat), sqrt(mean(first_week$diff_oct_mat^2))))
cat(sprintf("  First month:    Bias = %+.4f, RMSE = %.4f\n",
            mean(first_month$diff_oct_mat), sqrt(mean(first_month$diff_oct_mat^2))))

# ============================================================
# PLOT 1: 3-Way Time Series (Full 6 Months)
# ============================================================

p1 <- comparison %>%
  select(timestamp, obs_SMC_60cm, octave_SMC_60cm, matlab_SMC_60cm) %>%
  pivot_longer(cols = c(obs_SMC_60cm, octave_SMC_60cm, matlab_SMC_60cm),
               names_to = "source",
               values_to = "SMC") %>%
  mutate(source = recode(source,
                         obs_SMC_60cm = "Observations",
                         octave_SMC_60cm = "Octave (Fixed)",
                         matlab_SMC_60cm = "MATLAB")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source)) +
  geom_line(linewidth = 0.8, alpha = 0.85) +
  scale_color_manual(values = c(
    "Observations" = "black",
    "MATLAB" = "#2166AC",
    "Octave (Fixed)" = "#B2182B"
  )) +
  labs(
    title = "3-Way Comparison: Soil Moisture at 60cm Depth",
    subtitle = "DE-STG Steglitz Site | Jan-Jun 2019 (6 Months, 92% Recovered)",
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
  mutate(month_floor = floor_date(timestamp, "month")) %>%
  group_by(month_floor) %>%
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
                         octave = "Octave (Fixed)",
                         matlab = "MATLAB")) %>%
  ggplot(aes(x = month_floor, y = SMC, color = source, group = source)) +
  geom_line(linewidth = 1.5) +
  geom_point(size = 4) +
  scale_x_datetime(date_labels = "%b %Y", date_breaks = "1 month") +
  scale_color_manual(values = c(
    "Observations" = "black",
    "MATLAB" = "#2166AC",
    "Octave (Fixed)" = "#B2182B"
  )) +
  labs(
    title = "Monthly Mean Soil Moisture (60cm)",
    subtitle = "3-Way Comparison: Observations vs MATLAB vs Octave (Fixed) | Jan-Jun 2019",
    x = "Month",
    y = expression(paste("Mean SMC (", m^3, "/", m^3, ")")),
    color = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 15)
  ) +
  coord_cartesian(ylim = c(0.05, 0.45))

ggsave(file.path(output_dir, "02_3way_monthly_comparison.png"), p2,
       width = 12, height = 6, dpi = 150)
cat("Saved: 02_3way_monthly_comparison.png\n")

# ============================================================
# PLOT 3: MATLAB vs Octave Scatter
# ============================================================

p3 <- valid_data %>%
  ggplot(aes(x = matlab_SMC_60cm, y = octave_SMC_60cm)) +
  geom_point(alpha = 0.5, color = "#4393C3", size = 2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              color = "red", linewidth = 1.2) +
  geom_smooth(method = "lm", color = "#D6604D", se = TRUE, alpha = 0.2) +
  labs(
    title = "MATLAB vs Octave (Fixed): Soil Moisture at 60cm",
    subtitle = "Perfect agreement = points on red dashed 1:1 line | 6 Months",
    x = expression(paste("MATLAB SMC (", m^3, "/", m^3, ")")),
    y = expression(paste("Octave SMC (", m^3, "/", m^3, ")"))
  ) +
  coord_equal(xlim = c(0.05, 0.5), ylim = c(0.05, 0.5)) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 15))

ggsave(file.path(output_dir, "03_matlab_vs_octave_scatter.png"), p3,
       width = 8, height = 8, dpi = 150)
cat("Saved: 03_matlab_vs_octave_scatter.png\n")

# ============================================================
# PLOT 4: Rolling 24-Hour Difference
# ============================================================

rollmean_simple <- function(x, k) {
  n <- length(x)
  result <- rep(NA, n)
  for (i in k:n) {
    result[i] <- mean(x[(i-k+1):i], na.rm = TRUE)
  }
  return(result)
}

df_rolling <- valid_data %>%
  mutate(
    rolling_diff = rollmean_simple(diff_oct_mat, 24),
    rolling_abs_diff = rollmean_simple(abs(diff_oct_mat), 24)
  )

p4 <- ggplot(df_rolling, aes(x = timestamp)) +
  geom_line(aes(y = rolling_diff), color = "#D6604D", linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  geom_hline(yintercept = c(-0.05, 0.05), linetype = "dotted", color = "gray50") +
  labs(
    title = "Rolling 24-Hour Difference: Octave (Fixed) - MATLAB",
    subtitle = "Positive = Octave predicts HIGHER moisture than MATLAB | 6 Months",
    x = "Time",
    y = expression(paste(Delta, " SMC (Octave - MATLAB) [", m^3, "/", m^3, "]"))
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "04_rolling_difference.png"), p4, width = 14, height = 5, dpi = 150)
cat("Saved: 04_rolling_difference.png\n")

# ============================================================
# PLOT 5: Difference By Hour of Day
# ============================================================

hourly_pattern <- valid_data %>%
  group_by(hour) %>%
  summarise(
    mean_diff = mean(diff_oct_mat, na.rm = TRUE),
    sd_diff = sd(diff_oct_mat, na.rm = TRUE),
    .groups = "drop"
  )

p5 <- ggplot(hourly_pattern, aes(x = hour, y = mean_diff)) +
  geom_bar(stat = "identity", fill = "#4393C3", alpha = 0.7) +
  geom_errorbar(aes(ymin = mean_diff - sd_diff, ymax = mean_diff + sd_diff),
                width = 0.3, color = "gray40") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  scale_x_continuous(breaks = seq(0, 23, 3)) +
  labs(
    title = "Octave-MATLAB Difference by Hour of Day",
    subtitle = "Looking for diurnal patterns (energy balance iteration) | 6 Months",
    x = "Hour of Day",
    y = expression(paste("Mean ", Delta, " SMC [", m^3, "/", m^3, "]"))
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "05_hourly_pattern.png"), p5, width = 10, height = 5, dpi = 150)
cat("Saved: 05_hourly_pattern.png\n")

# ============================================================
# PLOT 6: Weekly Evolution of Bias
# ============================================================

weekly_stats <- valid_data %>%
  group_by(week) %>%
  summarise(
    mean_diff = mean(diff_oct_mat, na.rm = TRUE),
    rmse = sqrt(mean(diff_oct_mat^2, na.rm = TRUE)),
    n = n(),
    .groups = "drop"
  )

p6 <- ggplot(weekly_stats, aes(x = week)) +
  geom_col(aes(y = mean_diff), fill = "#B2182B", alpha = 0.7) +
  geom_line(aes(y = rmse), color = "black", linewidth = 1.2) +
  geom_point(aes(y = rmse), color = "black", size = 3) +
  labs(
    title = "Weekly Bias Evolution (Octave Fixed - MATLAB)",
    subtitle = "Bars = Mean Bias | Line = RMSE | 6 Months",
    x = "Week of Year",
    y = expression(paste(Delta, " SMC [", m^3, "/", m^3, "]"))
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "06_weekly_bias.png"), p6, width = 10, height = 5, dpi = 150)
cat("Saved: 06_weekly_bias.png\n")

# ============================================================
# PLOT 7: Initial 48 Hours
# ============================================================

first_48h <- comparison %>% filter(timestep <= 48)

p7 <- first_48h %>%
  select(timestep, octave_SMC_60cm, matlab_SMC_60cm, obs_SMC_60cm) %>%
  pivot_longer(cols = c(octave_SMC_60cm, matlab_SMC_60cm, obs_SMC_60cm),
               names_to = "source", values_to = "SMC") %>%
  mutate(source = recode(source,
                         obs_SMC_60cm = "Observations",
                         matlab_SMC_60cm = "MATLAB",
                         octave_SMC_60cm = "Octave (Fixed)")) %>%
  ggplot(aes(x = timestep, y = SMC, color = source)) +
  geom_line(linewidth = 1.2) +
  scale_color_manual(values = c(
    "Observations" = "black",
    "MATLAB" = "#2166AC",
    "Octave (Fixed)" = "#B2182B"
  )) +
  labs(
    title = "First 48 Hours: Initial Conditions & Early Divergence",
    subtitle = "Critical check: Does the InitSMC fix bring Octave closer to MATLAB/Observations?",
    x = "Timestep (Hours from Jan 1, 00:00)",
    y = expression(paste("SMC at 60cm [", m^3, "/", m^3, "]")),
    color = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave(file.path(output_dir, "07_initial_48h.png"), p7, width = 12, height = 6, dpi = 150)
cat("Saved: 07_initial_48h.png\n")

# ============================================================
# PLOT 8: Density Scatter
# ============================================================

p8 <- valid_data %>%
  ggplot(aes(x = matlab_SMC_60cm, y = octave_SMC_60cm)) +
  geom_bin2d(bins = 50) +
  scale_fill_viridis_c(option = "plasma") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "white", linewidth = 1) +
  labs(
    title = "Octave (Fixed) vs MATLAB: Density Plot",
    subtitle = "White dashed = 1:1 line. Color = point density | 6 Months",
    x = expression(paste("MATLAB SMC [", m^3, "/", m^3, "]")),
    y = expression(paste("Octave SMC [", m^3, "/", m^3, "]")),
    fill = "Count"
  ) +
  coord_equal(xlim = c(0.05, 0.45), ylim = c(0.05, 0.45)) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "08_density_scatter.png"), p8, width = 8, height = 8, dpi = 150)
cat("Saved: 08_density_scatter.png\n")

# ============================================================
# PLOT 9: Error Distribution Histogram
# ============================================================

p9 <- valid_data %>%
  ggplot(aes(x = diff_oct_mat)) +
  geom_histogram(bins = 50, fill = "#4393C3", color = "white", alpha = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 1) +
  geom_vline(xintercept = mean(valid_data$diff_oct_mat, na.rm = TRUE),
             linetype = "solid", color = "darkred", linewidth = 1) +
  labs(
    title = "Distribution of Octave(Fixed)-MATLAB Difference",
    subtitle = paste("Mean bias:", round(mean(valid_data$diff_oct_mat, na.rm = TRUE), 4),
                     "| Red dashed = zero | 6 Months"),
    x = expression(paste(Delta, " SMC (Octave - MATLAB) [", m^3, "/", m^3, "]")),
    y = "Frequency"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "09_error_distribution.png"), p9, width = 10, height = 5, dpi = 150)
cat("Saved: 09_error_distribution.png\n")

# ============================================================
# KEY DIAGNOSTIC FINDINGS
# ============================================================

cat("\n===================================================================\n")
cat("                    KEY DIAGNOSTIC FINDINGS                         \n")
cat("===================================================================\n\n")

# Initial divergence
init_diff <- comparison$diff_oct_mat[1]
cat(sprintf("1. INITIAL DIVERGENCE: At timestep 1, Octave(Fixed) - MATLAB = %+.4f\n", init_diff))
if (abs(init_diff) > 0.01) {
  cat("   ⚠️  SIGNIFICANT initial difference! InitSMC values differ.\n")
} else {
  cat("   ✅ Initial conditions appear similar.\n")
}

# Bias evolution
early_bias <- mean(first_24h$diff_oct_mat, na.rm = TRUE)
late_bias <- mean(valid_data$diff_oct_mat[valid_data$timestep > (max(valid_data$timestep) - 24)], na.rm = TRUE)
cat(sprintf("\n2. BIAS EVOLUTION:\n"))
cat(sprintf("   First 24 hours bias: %+.4f\n", early_bias))
cat(sprintf("   Last 24 hours bias:  %+.4f\n", late_bias))
if (abs(late_bias) > abs(early_bias) * 1.5) {
  cat("   ⚠️  Bias GROWS over time! Possible drift or accumulation error.\n")
} else {
  cat("   ➡️  Bias is relatively stable over time.\n")
}

# Diurnal pattern
daytime_diff <- mean(valid_data$diff_oct_mat[valid_data$hour >= 6 & valid_data$hour <= 18], na.rm = TRUE)
nighttime_diff <- mean(valid_data$diff_oct_mat[valid_data$hour < 6 | valid_data$hour > 18], na.rm = TRUE)
cat(sprintf("\n3. DIURNAL PATTERN:\n"))
cat(sprintf("   Daytime bias (6-18h):   %+.4f\n", daytime_diff))
cat(sprintf("   Nighttime bias (other): %+.4f\n", nighttime_diff))
if (abs(daytime_diff - nighttime_diff) > 0.01) {
  cat("   ⚠️  Diurnal pattern detected!\n")
} else {
  cat("   ➡️  No strong diurnal pattern.\n")
}

# Overall verdict
cat("\n4. OVERALL ASSESSMENT:\n")
if (summary_stats$oct_mat_rmse < 0.02) {
  cat("   ✅ EXCELLENT: Octave closely matches MATLAB (RMSE < 0.02)\n")
} else if (summary_stats$oct_mat_rmse < 0.05) {
  cat("   ⚠️  ACCEPTABLE: Minor numerical differences (RMSE 0.02-0.05)\n")
} else {
  cat("   ❌ INVESTIGATE: Significant divergence (RMSE > 0.05)\n")
  cat("      Likely causes to investigate:\n")
  cat("        - InitSMC values differ between engines\n")
  cat("        - Evapotranspiration calculation\n")
  cat("        - Infiltration / drainage functions\n")
  cat("        - Energy balance iteration convergence\n")
}

# Compare with 3-month run (old broken Octave)
cat("\n5. COMPARISON WITH OLD (BROKEN) OCTAVE RUN:\n")
cat(sprintf("   Old Octave initial value:   0.2701 m³/m³ (broken)\n"))
cat(sprintf("   Fixed Octave initial value: %.4f m³/m³\n", comparison$octave_SMC_60cm[1]))
cat(sprintf("   MATLAB initial value:       %.4f m³/m³\n", comparison$matlab_SMC_60cm[1]))
cat(sprintf("   Observations initial value: %.4f m³/m³\n", comparison$obs_SMC_60cm[1]))

cat("\n===== ALL PLOTS SAVED TO =====\n")
cat(output_dir, "\n\n")
