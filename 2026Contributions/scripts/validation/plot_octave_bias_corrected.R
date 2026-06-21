# ============================================================
# plot_octave_bias_corrected.R
# the reference Bias Correction Test: Subtract 0.1 from Octave SMC
# ============================================================
# Purpose: Test whether Octave's overestimation is a systematic  
#          offset (programming artifact) rather than a physics issue.
#          If bias-corrected Octave tracks observations well,
#          then the SAME physical equations produce the right dynamics
#          — the offset comes from numerical implementation differences.
# ============================================================

library(tidyverse)
library(lubridate)
library(hydroGOF)

# ============================================================
# 1. CONFIGURATION
# ============================================================
project_root <- "C:/Users/armanshirzad/Repos/rSTEMMUS_SCOPE"

obs_file       <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")
matlab_theta   <- file.path(project_root, "2026Contributions/validation_plots/Sim_Theta.csv")
octave_theta   <- file.path(project_root, "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_continuous_final_2026Apr11_1836/Sim_Theta.csv")

BIAS_CORRECTION <- 0.10  # Subtract this from Octave SMC (the reference hypothesis)

output_dir <- file.path(project_root, "2026Contributions/validation_plots/20260413_bias_corrected_test")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# ============================================================
# 2. HELPER: Extract SMC at 60cm
# ============================================================
extract_smc <- function(theta_file, target_depth = 60) {
  if (!file.exists(theta_file)) stop(paste("File not found:", theta_file))
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])
  idx <- which(depths == target_depth)
  if (length(idx) == 0) idx <- which.min(abs(depths - target_depth)) else idx <- idx[1]
  as.numeric(raw[-(1:3), idx])
}

# ============================================================
# 3. LOAD & ALIGN DATA
# ============================================================
cat("Loading data...\n")

obs_raw <- readRDS(obs_file) %>%
  filter(timestamp >= "2019-01-01", timestamp <= "2020-12-31 23:59:59")
obs_df <- obs_raw %>%
  select(timestamp, obs_SMC = SMC_60cm) %>%
  mutate(obs_SMC = obs_SMC / 100)

matlab_smc <- extract_smc(matlab_theta, 60)
matlab_df <- tibble(
  timestamp = min(obs_raw$timestamp) + hours(0:(length(matlab_smc)-1)),
  mat_SMC = matlab_smc
) %>% filter(timestamp <= "2020-12-31 23:59:59")

octave_smc <- extract_smc(octave_theta, 60)
octave_df <- tibble(
  timestamp = as.POSIXct("2019-01-01", tz="UTC") + hours(0:(length(octave_smc)-1)),
  oct_SMC = octave_smc,
  oct_SMC_corrected = octave_smc - BIAS_CORRECTION   # <<< the reference correction
)

# Merge
combined <- obs_df %>%
  left_join(matlab_df, by = "timestamp") %>%
  left_join(octave_df, by = "timestamp") %>%
  filter(!is.na(obs_SMC), !is.na(mat_SMC), !is.na(oct_SMC))

cat(sprintf("Aligned %d matching timesteps\n\n", nrow(combined)))

# ============================================================
# 4. METRICS: Original vs Bias-Corrected
# ============================================================
kge_mat <- KGE(combined$mat_SMC, combined$obs_SMC, out.type = "full")
kge_oct <- KGE(combined$oct_SMC, combined$obs_SMC, out.type = "full")
kge_oct_corr <- KGE(combined$oct_SMC_corrected, combined$obs_SMC, out.type = "full")

rmse_mat  <- sqrt(mean((combined$mat_SMC - combined$obs_SMC)^2))
rmse_oct  <- sqrt(mean((combined$oct_SMC - combined$obs_SMC)^2))
rmse_corr <- sqrt(mean((combined$oct_SMC_corrected - combined$obs_SMC)^2))

bias_mat  <- mean(combined$mat_SMC - combined$obs_SMC)
bias_oct  <- mean(combined$oct_SMC - combined$obs_SMC)
bias_corr <- mean(combined$oct_SMC_corrected - combined$obs_SMC)

r_mat  <- cor(combined$mat_SMC, combined$obs_SMC)
r_oct  <- cor(combined$oct_SMC, combined$obs_SMC)
r_corr <- cor(combined$oct_SMC_corrected, combined$obs_SMC)

cat("===== METRICS COMPARISON =====\n\n")
cat(sprintf("%-30s  %10s  %10s  %10s\n", "", "MATLAB", "Octave", "Octave-0.1"))
cat(sprintf("%-30s  %10.4f  %10.4f  %10.4f\n", "RMSE (m3/m3)", rmse_mat, rmse_oct, rmse_corr))
cat(sprintf("%-30s  %10.4f  %10.4f  %10.4f\n", "Bias (m3/m3)", bias_mat, bias_oct, bias_corr))
cat(sprintf("%-30s  %10.3f  %10.3f  %10.3f\n", "Correlation (r)", r_mat, r_oct, r_corr))
cat(sprintf("%-30s  %10.3f  %10.3f  %10.3f\n", "KGE", kge_mat$KGE.value, kge_oct$KGE.value, kge_oct_corr$KGE.value))
cat(sprintf("%-30s  %10.3f  %10.3f  %10.3f\n", "  Alpha (variability)", 
            kge_mat$KGE.elements["Alpha"], kge_oct$KGE.elements["Alpha"], kge_oct_corr$KGE.elements["Alpha"]))
cat(sprintf("%-30s  %10.3f  %10.3f  %10.3f\n", "  Beta (bias ratio)",
            kge_mat$KGE.elements["Beta"], kge_oct$KGE.elements["Beta"], kge_oct_corr$KGE.elements["Beta"]))

# ============================================================
# 5. PLOT 1: 4-Way Time Series (Obs, MATLAB, Octave, Octave-0.1)
# ============================================================
annotation_text <- paste0(
  "             RMSE    Bias     KGE\n",
  sprintf("MATLAB    %6.4f  %+6.4f  %6.3f\n", rmse_mat, bias_mat, kge_mat$KGE.value),
  sprintf("Octave    %6.4f  %+6.4f  %6.3f\n", rmse_oct, bias_oct, kge_oct$KGE.value),
  sprintf("Oct-0.10  %6.4f  %+6.4f  %6.3f", rmse_corr, bias_corr, kge_oct_corr$KGE.value)
)

p1 <- combined %>%
  select(timestamp, obs_SMC, mat_SMC, oct_SMC, oct_SMC_corrected) %>%
  pivot_longer(cols = c(obs_SMC, mat_SMC, oct_SMC, oct_SMC_corrected),
               names_to = "source", values_to = "SMC") %>%
  mutate(source = recode(source,
    obs_SMC = "Observations",
    mat_SMC = "MATLAB",
    oct_SMC = "Octave (raw)",
    oct_SMC_corrected = "Octave − 0.10")) %>%
  mutate(source = factor(source, levels = c("Observations", "MATLAB", "Octave (raw)", "Octave − 0.10"))) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source, linewidth = source, alpha = source)) +
  geom_line() +
  scale_color_manual(values = c(
    "Observations" = "black",
    "MATLAB" = "#2166AC",
    "Octave (raw)" = "#B2182B",
    "Octave − 0.10" = "#E08214"
  )) +
  scale_linewidth_manual(values = c(
    "Observations" = 1.0,
    "MATLAB" = 0.8,
    "Octave (raw)" = 0.5,
    "Octave − 0.10" = 1.0
  ), guide = "none") +
  scale_alpha_manual(values = c(
    "Observations" = 0.9,
    "MATLAB" = 0.7,
    "Octave (raw)" = 0.4,
    "Octave − 0.10" = 0.9
  ), guide = "none") +
  annotate("label", x = as.POSIXct("2020-04-01", tz="UTC"), y = 0.44,
           label = annotation_text,
           hjust = 0, vjust = 1, size = 3.0, family = "mono", fill = "white", color = "gray20") +
  coord_cartesian(ylim = c(0.0, 0.48)) +
  labs(
    title = "the reference Bias Correction Test: Octave − 0.10",
    subtitle = "DE-STG | Jan 2019 – Dec 2020 | Does removing offset reveal matching dynamics?",
    x = "Date",
    y = expression(paste("VWC (m"^3, " m"^-3, ")")),
    color = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "01_Bias_Corrected_4way.png"), p1, width = 14, height = 7, dpi = 150)
cat("\nSaved: 01_Bias_Corrected_4way.png\n")

# ============================================================
# 6. PLOT 2: Octave−0.10 vs Observations only (clean comparison)
# ============================================================
p2 <- combined %>%
  select(timestamp, obs_SMC, oct_SMC_corrected) %>%
  pivot_longer(cols = c(obs_SMC, oct_SMC_corrected),
               names_to = "source", values_to = "SMC") %>%
  mutate(source = recode(source,
    obs_SMC = "Observations",
    oct_SMC_corrected = "Octave − 0.10")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source)) +
  geom_line(linewidth = 0.9, alpha = 0.9) +
  scale_color_manual(values = c("Observations" = "black", "Octave − 0.10" = "#E08214")) +
  annotate("label", x = as.POSIXct("2020-06-01", tz="UTC"), y = 0.42,
           label = sprintf("Octave − 0.10 vs Obs\nRMSE: %.4f | Bias: %+.4f | KGE: %.3f | r: %.3f",
                           rmse_corr, bias_corr, kge_oct_corr$KGE.value, r_corr),
           hjust = 0, vjust = 1, size = 3.5, family = "mono", fill = "white") +
  coord_cartesian(ylim = c(0.0, 0.45)) +
  labs(
    title = "Bias-Corrected Octave vs Observations",
    subtitle = "DE-STG | Can Octave dynamics track the observed seasonality after removing the systematic offset?",
    x = "Date",
    y = expression(paste("VWC (m"^3, " m"^-3, ")")),
    color = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "02_Bias_Corrected_vs_Observations.png"), p2, width = 14, height = 6, dpi = 150)
cat("Saved: 02_Bias_Corrected_vs_Observations.png\n")

# ============================================================
# 7. PLOT 3: Fluctuation Analysis (Octave high-freq variability)
# ============================================================
# Compute hourly deltas (derivative proxy) — high-freq fluctuations
combined <- combined %>%
  mutate(
    d_obs = c(NA, diff(obs_SMC)),
    d_oct = c(NA, diff(oct_SMC)),
    d_mat = c(NA, diff(mat_SMC))
  )

# Standard deviation of hourly changes — measures "jitteriness"
sd_obs <- sd(combined$d_obs, na.rm = TRUE)
sd_oct <- sd(combined$d_oct, na.rm = TRUE)
sd_mat <- sd(combined$d_mat, na.rm = TRUE)

cat(sprintf("\n===== FLUCTUATION ANALYSIS =====\n"))
cat(sprintf("Std Dev of hourly ∆SMC:\n"))
cat(sprintf("  Observations: %.6f m3/m3/hr\n", sd_obs))
cat(sprintf("  MATLAB:       %.6f m3/m3/hr\n", sd_mat))
cat(sprintf("  Octave:       %.6f m3/m3/hr\n", sd_oct))
cat(sprintf("  Octave/Obs ratio: %.2f (>1 = Octave is more jittery)\n", sd_oct/sd_obs))
cat(sprintf("  Octave/MATLAB ratio: %.2f\n", sd_oct/sd_mat))

p3 <- combined %>%
  filter(!is.na(d_obs)) %>%
  select(timestamp, d_obs, d_oct, d_mat) %>%
  pivot_longer(cols = c(d_obs, d_oct, d_mat), names_to = "source", values_to = "delta") %>%
  mutate(source = recode(source, d_obs="Observations", d_oct="Octave", d_mat="MATLAB")) %>%
  ggplot(aes(x = delta, fill = source)) +
  geom_density(alpha = 0.5, linewidth = 0.3) +
  scale_fill_manual(values = c("Observations"="gray40", "MATLAB"="#2166AC", "Octave"="#B2182B")) +
  annotate("label", x = 0.03, y = Inf,
           label = sprintf("SD of hourly ΔSMC\nObs: %.5f\nMATLAB: %.5f\nOctave: %.5f\nOctave/Obs: %.1fx",
                           sd_obs, sd_mat, sd_oct, sd_oct/sd_obs),
           hjust = 0, vjust = 1.2, size = 3.5, family = "mono", fill = "white") +
  coord_cartesian(xlim = c(-0.05, 0.05)) +
  labs(
    title = "Fluctuation Analysis: Hourly ΔSMC Distribution",
    subtitle = "Wider tails = more high-frequency variability (potential numerical jitter in Octave)",
    x = expression(paste(Delta, " SMC per hour (m"^3, " m"^-3, " hr"^-1, ")")),
    y = "Density",
    fill = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "03_Fluctuation_Analysis.png"), p3, width = 12, height = 6, dpi = 150)
cat("Saved: 03_Fluctuation_Analysis.png\n")

# ============================================================
# 8. PLOT 4: Rolling window comparison (7-day moving average)
# ============================================================
# Smooth out the fluctuations — does the trend match?
window_size <- 168  # 7 days * 24 hours
combined <- combined %>%
  mutate(
    oct_smooth = stats::filter(oct_SMC_corrected, rep(1/window_size, window_size), sides = 2),
    obs_smooth = stats::filter(obs_SMC, rep(1/window_size, window_size), sides = 2),
    mat_smooth = stats::filter(mat_SMC, rep(1/window_size, window_size), sides = 2)
  )

rmse_smooth <- sqrt(mean((combined$oct_smooth - combined$obs_smooth)^2, na.rm=TRUE))
r_smooth <- cor(combined$oct_smooth, combined$obs_smooth, use="complete.obs")

p4 <- combined %>%
  filter(!is.na(oct_smooth), !is.na(obs_smooth)) %>%
  select(timestamp, obs_smooth, mat_smooth, oct_smooth) %>%
  pivot_longer(cols = c(obs_smooth, mat_smooth, oct_smooth), names_to = "source", values_to = "SMC") %>%
  mutate(source = recode(source,
    obs_smooth = "Observations (7d avg)",
    mat_smooth = "MATLAB (7d avg)",
    oct_smooth = "Octave−0.10 (7d avg)")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source)) +
  geom_line(linewidth = 1.1, alpha = 0.9) +
  scale_color_manual(values = c(
    "Observations (7d avg)" = "black",
    "MATLAB (7d avg)" = "#2166AC",
    "Octave−0.10 (7d avg)" = "#E08214"
  )) +
  annotate("label", x = as.POSIXct("2020-04-01", tz="UTC"), y = 0.40,
           label = sprintf("7-day smoothed Octave−0.10 vs Obs\nRMSE: %.4f | r: %.3f", rmse_smooth, r_smooth),
           hjust = 0, vjust = 1, size = 3.5, family = "mono", fill = "white") +
  coord_cartesian(ylim = c(0.0, 0.42)) +
  labs(
    title = "7-Day Moving Average: Removing High-Freq Fluctuations",
    subtitle = "If smoothed Octave−0.10 tracks Obs, fluctuations are numerical noise, not physics errors",
    x = "Date",
    y = expression(paste("VWC (m"^3, " m"^-3, ")")),
    color = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "04_Smoothed_7day_Comparison.png"), p4, width = 14, height = 6, dpi = 150)
cat("Saved: 04_Smoothed_7day_Comparison.png\n")

# ============================================================
# 9. SUMMARY FILE
# ============================================================
summary_text <- sprintf(
"============================================================
 the reference BIAS CORRECTION TEST
 Hypothesis: Subtracting 0.10 from Octave SMC reveals that
 the physical dynamics are correct and only a systematic
 offset (programming artifact) separates Octave from observations.
============================================================

METRICS TABLE:
                              MATLAB    Octave    Octave-0.1
  RMSE (m3/m3)               %.4f     %.4f     %.4f
  Bias (m3/m3)              %+.4f    %+.4f    %+.4f
  Correlation (r)              %.3f      %.3f      %.3f
  KGE                         %.3f      %.3f      %.3f

FLUCTUATION ANALYSIS:
  SD of hourly ΔSMC:
    Observations: %.6f m3/m3/hr
    MATLAB:       %.6f m3/m3/hr
    Octave:       %.6f m3/m3/hr
    Octave/Obs ratio: %.2fx

  If ratio > 1: Octave has MORE high-frequency variability
  than observations → likely numerical solver jitter, NOT physics.

7-DAY SMOOTHED (bias-corrected):
  RMSE: %.4f | r: %.3f

INTERPRETATION:
  - If Octave−0.10 KGE improves significantly → offset is systematic (fixable)
  - If fluctuations vanish under 7d smoothing → jitter is numerical noise
  - Since Octave uses SAME equations as MATLAB, fluctuations must come
    from programming differences (solver tolerances, FP precision, etc.)
",
  rmse_mat, rmse_oct, rmse_corr,
  bias_mat, bias_oct, bias_corr,
  r_mat, r_oct, r_corr,
  kge_mat$KGE.value, kge_oct$KGE.value, kge_oct_corr$KGE.value,
  sd_obs, sd_mat, sd_oct, sd_oct/sd_obs,
  rmse_smooth, r_smooth
)

writeLines(summary_text, file.path(output_dir, "05_Bias_Correction_Summary.txt"))
cat(summary_text)

cat(sprintf("\nAll outputs saved to:\n  -> %s\n", output_dir))
