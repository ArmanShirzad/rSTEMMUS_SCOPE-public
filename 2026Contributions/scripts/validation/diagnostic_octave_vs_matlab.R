# ============================================================
# diagnostic_octave_vs_matlab.R
# Deep Analysis: Octave vs MATLAB Divergence Investigation
# ============================================================
# Created: 2026-02-03
# Purpose: Identify WHERE and WHY Octave differs from MATLAB
#          to guide debugging efforts for the Octave maintainer
# ============================================================

library(tidyverse)
library(lubridate)

# ============================================================
# CONFIGURATION
# ============================================================

project_root <- getwd()
obs_file <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")

# Octave output (our 3-month run)
octave_theta_file <- file.path(project_root, 
  "rSTEMMUS_SCOPE/output/DE-STG_Test_pre_mm_Steglitz_OCTAVE_2026Feb03_1524/Sim_Theta.csv")

# MATLAB output (the reference confirmed run)
matlab_theta_file <- file.path(project_root, 
  "2026Contributions/validation_plots/Sim_Theta.csv")

# Output folder
output_dir <- file.path(project_root, "2026Contributions/validation_plots/Mat_OctaveComparison")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("===================================================================\n")
cat("       DIAGNOSTIC ANALYSIS: OCTAVE vs MATLAB DIVERGENCE           \n")
cat("===================================================================\n\n")

# ============================================================
# HELPER: Extract SMC at 60cm
# ============================================================

extract_smc_60cm <- function(theta_file) {
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])
  idx_60cm <- which(depths == 60)
  if (length(idx_60cm) == 0) idx_60cm <- which.min(abs(depths - 60))
  smc_values <- as.numeric(raw[-(1:3), idx_60cm])
  return(smc_values)
}

# ============================================================
# LOAD ALL DATA
# ============================================================

cat("Loading data...\n")

# Observations
obs <- readRDS(obs_file) %>%
  filter(timestamp >= as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
         timestamp <= as.POSIXct("2019-03-31 23:00:00", tz = "UTC")) %>%
  select(timestamp, obs_SMC_60cm = SMC_60cm, prec_mm) %>%
  mutate(obs_SMC_60cm = obs_SMC_60cm / 100)

# Octave
octave_smc <- extract_smc_60cm(octave_theta_file)
octave_start <- as.POSIXct("2019-01-01 00:00:00", tz = "UTC")
octave_df <- tibble(
  timestamp = octave_start + hours(0:(length(octave_smc) - 1)),
  octave = octave_smc
)

# MATLAB
matlab_smc <- extract_smc_60cm(matlab_theta_file)
matlab_start <- as.POSIXct("2019-01-01 00:00:00", tz = "UTC")
matlab_df <- tibble(
  timestamp = matlab_start + hours(0:(length(matlab_smc) - 1)),
  matlab = matlab_smc
) %>%
  filter(timestamp >= as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
         timestamp <= as.POSIXct("2019-03-31 23:00:00", tz = "UTC"))

# Merge all
df <- obs %>%
  left_join(octave_df, by = "timestamp") %>%
  left_join(matlab_df, by = "timestamp") %>%
  mutate(
    diff_oct_mat = octave - matlab,            # Octave - MATLAB
    diff_oct_obs = octave - obs_SMC_60cm,      # Octave bias vs Obs
    diff_mat_obs = matlab - obs_SMC_60cm,      # MATLAB bias vs Obs
    hour = hour(timestamp),
    day = as.Date(timestamp),
    week = week(timestamp),
    month = month(timestamp, label = TRUE),
    timestep = row_number()
  )

cat("  Total timesteps:", nrow(df), "\n")
cat("  Period:", as.character(min(df$timestamp)), "to", as.character(max(df$timestamp)), "\n\n")

# ============================================================
# 1. SUMMARY STATISTICS
# ============================================================

cat("===== 1. OVERALL STATISTICS =====\n\n")

summary_stats <- df %>%
  summarise(
    # Means
    obs_mean = mean(obs_SMC_60cm, na.rm = TRUE),
    octave_mean = mean(octave, na.rm = TRUE),
    matlab_mean = mean(matlab, na.rm = TRUE),
    
    # Octave vs MATLAB difference
    oct_mat_bias = mean(diff_oct_mat, na.rm = TRUE),
    oct_mat_rmse = sqrt(mean(diff_oct_mat^2, na.rm = TRUE)),
    oct_mat_max_diff = max(abs(diff_oct_mat), na.rm = TRUE),
    oct_mat_r = cor(octave, matlab, use = "complete.obs"),
    
    # Octave vs Observations
    oct_obs_bias = mean(diff_oct_obs, na.rm = TRUE),
    oct_obs_rmse = sqrt(mean(diff_oct_obs^2, na.rm = TRUE)),
    
    # MATLAB vs Observations
    mat_obs_bias = mean(diff_mat_obs, na.rm = TRUE),
    mat_obs_rmse = sqrt(mean(diff_mat_obs^2, na.rm = TRUE))
  )

cat("Mean Values:\n")
cat(sprintf("  Observations: %.4f m³/m³\n", summary_stats$obs_mean))
cat(sprintf("  MATLAB:       %.4f m³/m³\n", summary_stats$matlab_mean))
cat(sprintf("  Octave:       %.4f m³/m³\n", summary_stats$octave_mean))

cat("\nOctave vs MATLAB (Engine Equivalence):\n")
cat(sprintf("  Bias (Octave - MATLAB): %+.4f m³/m³\n", summary_stats$oct_mat_bias))
cat(sprintf("  RMSE: %.4f m³/m³\n", summary_stats$oct_mat_rmse))
cat(sprintf("  Max Absolute Diff: %.4f m³/m³\n", summary_stats$oct_mat_max_diff))
cat(sprintf("  Correlation: %.4f\n", summary_stats$oct_mat_r))

cat("\nOctave vs Observations:\n")
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
# 2. DIVERGENCE OVER TIME (Cumulative Analysis)
# ============================================================

cat("\n===== 2. DIVERGENCE TIMELINE =====\n")

# Check if divergence is immediate or grows
first_24h <- df %>% filter(timestep <= 24)
first_week <- df %>% filter(timestep <= 168)  # 7 days
first_month <- df %>% filter(timestep <= 720)  # 30 days

cat("\nDivergence at different stages:\n")
cat(sprintf("  First 24 hours: Bias = %+.4f, RMSE = %.4f\n", 
            mean(first_24h$diff_oct_mat), sqrt(mean(first_24h$diff_oct_mat^2))))
cat(sprintf("  First week:     Bias = %+.4f, RMSE = %.4f\n", 
            mean(first_week$diff_oct_mat), sqrt(mean(first_week$diff_oct_mat^2))))
cat(sprintf("  First month:    Bias = %+.4f, RMSE = %.4f\n", 
            mean(first_month$diff_oct_mat), sqrt(mean(first_month$diff_oct_mat^2))))

# ============================================================
# PLOT 4: Rolling Difference Over Time
# ============================================================

# Rolling mean without zoo package
rollmean_simple <- function(x, k) {
  n <- length(x)
  result <- rep(NA, n)
  for (i in k:n) {
    result[i] <- mean(x[(i-k+1):i], na.rm = TRUE)
  }
  return(result)
}

df_rolling <- df %>%
  mutate(
    rolling_diff = rollmean_simple(diff_oct_mat, 24),
    rolling_abs_diff = rollmean_simple(abs(diff_oct_mat), 24)
  )

p4 <- ggplot(df_rolling, aes(x = timestamp)) +
  geom_line(aes(y = rolling_diff), color = "#D6604D", linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  geom_hline(yintercept = c(-0.05, 0.05), linetype = "dotted", color = "gray50") +
  labs(
    title = "Rolling 24-Hour Difference: Octave - MATLAB",
    subtitle = "Positive = Octave predicts HIGHER moisture than MATLAB",
    x = "Time",
    y = expression(paste(Delta, " SMC (Octave - MATLAB) [", m^3, "/", m^3, "]"))
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "04_rolling_difference.png"), p4, width = 14, height = 5, dpi = 150)
cat("\nSaved: 04_rolling_difference.png\n")

# ============================================================
# PLOT 5: Difference By Hour of Day (Diurnal Pattern)
# ============================================================

hourly_pattern <- df %>%
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
    subtitle = "Looking for diurnal patterns (e.g., energy balance iteration differences)",
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

weekly_stats <- df %>%
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
    title = "Weekly Bias Evolution (Octave - MATLAB)",
    subtitle = "Bars = Mean Bias | Line = RMSE",
    x = "Week of Year",
    y = expression(paste(Delta, " SMC [", m^3, "/", m^3, "]"))
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "06_weekly_bias.png"), p6, width = 10, height = 5, dpi = 150)
cat("Saved: 06_weekly_bias.png\n")

# ============================================================
# PLOT 7: Initial Conditions Divergence (First 48 Hours)
# ============================================================

first_48h <- df %>% filter(timestep <= 48)

p7 <- first_48h %>%
  select(timestep, octave, matlab, obs_SMC_60cm) %>%
  pivot_longer(cols = c(octave, matlab, obs_SMC_60cm),
               names_to = "source", values_to = "SMC") %>%
  mutate(source = recode(source,
                         obs_SMC_60cm = "Observations",
                         matlab = "MATLAB",
                         octave = "Octave")) %>%
  ggplot(aes(x = timestep, y = SMC, color = source)) +
  geom_line(linewidth = 1.2) +
  scale_color_manual(values = c(
    "Observations" = "black",
    "MATLAB" = "#2166AC",
    "Octave" = "#B2182B"
  )) +
  labs(
    title = "First 48 Hours: Initial Conditions & Early Divergence",
    subtitle = "Critical check: Do they start the same and diverge, or start different?",
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
# PLOT 8: Scatter with Error Density
# ============================================================

p8 <- df %>%
  ggplot(aes(x = matlab, y = octave)) +
  geom_bin2d(bins = 50) +
  scale_fill_viridis_c(option = "plasma") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "white", linewidth = 1) +
  labs(
    title = "Octave vs MATLAB: Density Plot",
    subtitle = "White dashed = 1:1 line. Color = point density",
    x = expression(paste("MATLAB SMC [", m^3, "/", m^3, "]")),
    y = expression(paste("Octave SMC [", m^3, "/", m^3, "]")),
    fill = "Count"
  ) +
  coord_equal(xlim = c(0.15, 0.45), ylim = c(0.15, 0.45)) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "08_density_scatter.png"), p8, width = 8, height = 8, dpi = 150)
cat("Saved: 08_density_scatter.png\n")

# ============================================================
# PLOT 9: Error Distribution Histogram
# ============================================================

p9 <- df %>%
  ggplot(aes(x = diff_oct_mat)) +
  geom_histogram(bins = 50, fill = "#4393C3", color = "white", alpha = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 1) +
  geom_vline(xintercept = mean(df$diff_oct_mat, na.rm = TRUE), 
             linetype = "solid", color = "darkred", linewidth = 1) +
  labs(
    title = "Distribution of Octave-MATLAB Difference",
    subtitle = paste("Mean bias:", round(mean(df$diff_oct_mat, na.rm = TRUE), 4), "| Red dashed = zero"),
    x = expression(paste(Delta, " SMC (Octave - MATLAB) [", m^3, "/", m^3, "]")),
    y = "Frequency"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "09_error_distribution.png"), p9, width = 10, height = 5, dpi = 150)
cat("Saved: 09_error_distribution.png\n")

# ============================================================
# 3. KEY FINDINGS SUMMARY
# ============================================================

cat("\n===================================================================\n")
cat("                    KEY DIAGNOSTIC FINDINGS                         \n")
cat("===================================================================\n\n")

# Check initial divergence
init_diff <- df$diff_oct_mat[1]
cat(sprintf("1. INITIAL DIVERGENCE: At timestep 1, Octave - MATLAB = %+.4f\n", init_diff))
if (abs(init_diff) > 0.01) {
  cat("   ⚠️  SIGNIFICANT initial difference! Check initial conditions.\n")
} else {
  cat("   ✅ Initial conditions appear similar.\n")
}

# Check if bias grows
early_bias <- mean(first_24h$diff_oct_mat)
late_bias <- mean(df$diff_oct_mat[df$timestep > (nrow(df) - 24)])
cat(sprintf("\n2. BIAS EVOLUTION:\n"))
cat(sprintf("   First 24 hours bias: %+.4f\n", early_bias))
cat(sprintf("   Last 24 hours bias:  %+.4f\n", late_bias))
if (abs(late_bias) > abs(early_bias) * 1.5) {
  cat("   ⚠️  Bias GROWS over time! Possible drift or accumulation error.\n")
} else {
  cat("   ➡️  Bias is relatively stable over time.\n")
}

# Check diurnal pattern
daytime_diff <- mean(df$diff_oct_mat[df$hour >= 6 & df$hour <= 18], na.rm = TRUE)
nighttime_diff <- mean(df$diff_oct_mat[df$hour < 6 | df$hour > 18], na.rm = TRUE)
cat(sprintf("\n3. DIURNAL PATTERN:\n"))
cat(sprintf("   Daytime bias (6-18h):   %+.4f\n", daytime_diff))
cat(sprintf("   Nighttime bias (other): %+.4f\n", nighttime_diff))
if (abs(daytime_diff - nighttime_diff) > 0.01) {
  cat("   ⚠️  Diurnal pattern detected! Likely energy balance / radiation calculation difference.\n")
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
  cat("      Octave consistently OVER-PREDICTS soil moisture.\n")
  cat("      Likely causes to investigate:\n")
  cat("        - Evapotranspiration calculation (lower ET → higher SMC)\n")
  cat("        - Infiltration / drainage functions\n")
  cat("        - Energy balance iteration convergence\n")
  cat("        - Root water uptake calculations\n")
}

cat("\n===== ALL DIAGNOSTIC PLOTS SAVED TO =====\n")
cat(output_dir, "\n\n")
