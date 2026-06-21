# ============================================================
# validate_2year_final.R
# Final 2-Year 3-Way Validation (Octave vs MATLAB vs Observations)
# ============================================================
# Purpose: This script is prepared to execute immediately once
#          the 2-year Octave simulation on the Windows machine finishes.
#          It automatically locates the latest Octave output, matches it
#          with the 2-year MATLAB baseline, and compares them against
#          field observations (2019-2020).
# ============================================================

library(tidyverse)
library(lubridate)

# ============================================================
# PATHS & CONFIGURATION
# ============================================================
project_root  <- getwd()  # Should be run from .../rSTEMMUS_SCOPE
contrib_dir   <- file.path(project_root, "2026Contributions")

# Inputs (Observations & MATLAB Baseline Phase)
obs_file      <- file.path(contrib_dir, "EC_DWD_ROTH_clean.rds")
matlab_theta  <- file.path(contrib_dir, "validation_plots/Sim_Theta.csv")
matlab_flux   <- file.path(contrib_dir, "matlabfluxes.csv")

# Find the latest 2-year Octave Output Directory
output_base   <- file.path(project_root, "rSTEMMUS_SCOPE", "output")
octave_dirs   <- list.dirs(output_base, recursive = FALSE)
yr2_dirs      <- octave_dirs[grepl("DE-STG_Test_FIXED_Final_2yr_OCTAVE", octave_dirs)]

if (length(yr2_dirs) == 0) {
  stop("❌ Could not find the 2-year Octave output folder in rSTEMMUS_SCOPE/output/ ! Make sure the simulation finished and produced outputs.")
}
# Pick latest by name/timestamp
octave_out_dir <- sort(yr2_dirs, decreasing = TRUE)[1]
octave_theta   <- file.path(octave_out_dir, "Sim_Theta.csv")
octave_flux    <- file.path(octave_out_dir, "fluxes.csv")

if (!file.exists(octave_theta)) stop(sprintf("❌ Sim_Theta.csv missing in %s", octave_out_dir))

plots_dir     <- file.path(contrib_dir, "validation_plots_2year")
if (!dir.exists(plots_dir)) dir.create(plots_dir, recursive = TRUE)

cat("=== FINAL 2-YEAR VALIDATION SCRIPT ===\n")
cat("Octave Data: ", octave_out_dir, "\n")
cat("Saving Plots to: ", plots_dir, "\n\n")

# Time window parameters (2 full years)
t_start <- as.POSIXct("2019-01-01 00:00:00", tz = "UTC")
t_end   <- as.POSIXct("2020-12-31 23:00:00", tz = "UTC")

# ============================================================
# DATA EXTRACTION HELPERS
# ============================================================

extract_smc <- function(path, name_label) {
  raw    <- read.csv(path, header = FALSE)
  depths <- as.numeric(raw[1, ])
  idx    <- which.min(abs(depths - 60))
  cat(sprintf("-> %s: Found closest SMC column to 60cm at %.0fcm\n", name_label, depths[idx]))
  as.numeric(raw[-(1:3), idx])
}

extract_le <- function(path, name_label) {
  raw <- read.csv(path, header = FALSE)
  cols <- as.character(raw[1, ])
  idx <- grep("lEtot", cols, ignore.case = TRUE)[1]
  if(is.na(idx)) idx <- grep("latentHeat", cols, ignore.case = TRUE)[1]
  cat(sprintf("-> %s: Found Latent Heat in column #%d\n", name_label, idx))
  as.numeric(raw[-(1:3), idx])
}

# ============================================================
# LOAD & ALIGN ALL DATA
# ============================================================

cat("Loading and processing data...\n")

# 1. Observations
obs <- readRDS(obs_file) %>%
  filter(timestamp >= t_start, timestamp <= t_end) %>%
  select(timestamp, obs_SMC_60cm = SMC_60cm, obs_LE = LE) %>%
  mutate(obs_SMC_60cm = obs_SMC_60cm / 100) # Convert % to m3/m3

n_obs <- nrow(obs)

# 2. MATLAB Baseline Data (17,544 timesteps)
matlab_smc_vals <- extract_smc(matlab_theta, "MATLAB")
matlab_le_vals  <- extract_le(matlab_flux, "MATLAB")

# 3. Octave Validation Data
octave_smc_vals <- extract_smc(octave_theta, "Octave")
octave_le_vals  <- extract_le(octave_flux, "Octave")

# Merge safely (pad/trim if needed, though they should all be 17544)
ts_seq <- seq(t_start, by = "hour", length.out = n_obs)

df <- tibble(timestamp = ts_seq) %>%
  left_join(obs, by = "timestamp") %>%
  mutate(
    matlab_SMC = head(c(matlab_smc_vals, rep(NA, n_obs)), n_obs),
    matlab_LE  = head(c(matlab_le_vals, rep(NA, n_obs)), n_obs),
    octave_SMC = head(c(octave_smc_vals, rep(NA, n_obs)), n_obs),
    octave_LE  = head(c(octave_le_vals, rep(NA, n_obs)), n_obs)
  )

cat(sprintf("\nMerger Complete. Working with %d timesteps.\n", nrow(df)))

# ============================================================
# PLOTTING 
# ============================================================
cat("\nGenerating Validation Plots...\n")

### PLOT 1: Full 2-Year Time Series for SMC 60cm
p1 <- df %>%
  select(timestamp, obs_SMC_60cm, matlab_SMC, octave_SMC) %>%
  pivot_longer(-timestamp, names_to = "Source", values_to = "SMC") %>%
  mutate(Source = recode(Source, 
                         obs_SMC_60cm = "Observations",
                         matlab_SMC   = "MATLAB Baseline",
                         octave_SMC   = "Octave 2-Year Run")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = Source, alpha = Source)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("Observations"="black", "MATLAB Baseline"="#2166AC", "Octave 2-Year Run"="#B2182B")) +
  scale_alpha_manual(values = c("Observations"=0.5, "MATLAB Baseline"=0.8, "Octave 2-Year Run"=0.8)) +
  coord_cartesian(ylim = c(0.05, 0.45)) +
  labs(title = "Final 2-Year Validation: Soil Moisture at 60cm",
       subtitle = "MATLAB Baseline vs. Patched Octave Simulation (2019-2020)",
       y = "VWC (m³/m³)", x = "Time") +
  theme_minimal() + theme(legend.position = "bottom")

ggsave(file.path(plots_dir, "01_2year_SMC_timeseries.png"), p1, width = 14, height = 6, dpi=150)

### PLOT 2: Cumulative Evapotranspiration (Cumulative LE)
p2 <- df %>%
  select(timestamp, matlab_LE, octave_LE) %>%
  drop_na() %>%
  mutate(
    # Convert W/m2 to J/m2 per hour, then cumsum
    matlab_CumLE = cumsum(matlab_LE * 3600) / 1e6, # MJ/m2
    octave_CumLE = cumsum(octave_LE * 3600) / 1e6
  ) %>%
  pivot_longer(-timestamp, names_to = "Source", values_to = "CumLE") %>%
  mutate(Source = recode(Source, matlab_CumLE="MATLAB Baseline", octave_CumLE="Octave 2-Year Run")) %>%
  ggplot(aes(x = timestamp, y = CumLE, color = Source)) +
  geom_line(linewidth = 1.2) +
  scale_color_manual(values = c("MATLAB Baseline"="#2166AC", "Octave 2-Year Run"="#B2182B")) +
  labs(title = "Cumulative Latent Heat Matrix (Energy Balance Validation)",
       subtitle = "If the new Octave ebal.m guardrails work, these lines must perfectly overlap.",
       y = "Cumulative Latent Heat (MJ/m²)", x = "Time") +
  theme_minimal() + theme(legend.position = "bottom")

ggsave(file.path(plots_dir, "02_2year_CumulativeLE.png"), p2, width = 12, height = 6, dpi=150)

### PLOT 3: Monthly Aggregates for SMC
p3 <- df %>%
  mutate(month = floor_date(timestamp, "month")) %>%
  group_by(month) %>%
  summarise(
    Observations = mean(obs_SMC_60cm, na.rm=TRUE),
    MATLAB       = mean(matlab_SMC, na.rm=TRUE),
    Octave       = mean(octave_SMC, na.rm=TRUE)
  ) %>%
  pivot_longer(-month, names_to = "Source", values_to = "SMC") %>%
  ggplot(aes(x = month, y = SMC, color = Source)) +
  geom_line(linewidth = 1) + geom_point(size = 3) +
  scale_color_manual(values = c("Observations"="black", "MATLAB"="#2166AC", "Octave"="#B2182B")) +
  labs(title = "Monthly Mean Soil Moisture (2019-2020)", x = "Month", y = "SMC (m³/m³)") +
  theme_minimal() + theme(legend.position = "bottom")

ggsave(file.path(plots_dir, "03_2year_Monthly_SMC.png"), p3, width = 12, height = 5, dpi=150)

### PLOT 4: Equivalence Check Scatter Plot (MATLAB vs Octave)
p4 <- df %>%
  drop_na(matlab_SMC, octave_SMC) %>%
  ggplot(aes(x = matlab_SMC, y = octave_SMC)) +
  geom_point(alpha = 0.2, color = "#4393C3") +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed", linewidth = 1) +
  coord_equal(xlim=c(0.15,0.45), ylim=c(0.15,0.45)) +
  labs(title = "Mathematical Equivalence Check: MATLAB vs Octave SMC",
       subtitle = "Dots directly on the red line equal 100% engine parity.",
       x = "MATLAB SMC (m³/m³)", y = "Octave SMC (m³/m³)") +
  theme_minimal()

ggsave(file.path(plots_dir, "04_2year_Parity_Scatter.png"), p4, width = 8, height = 8, dpi=150)

# ============================================================
# STATISTICAL SUMMARY 
# ============================================================

cat("\n======================================================\n")
cat("      FINAL 2-YEAR ENGINEERING PARITY CHECK           \n")
cat("======================================================\n")

df_clean <- drop_na(df, matlab_SMC, octave_SMC)
rmse_equiv <- sqrt(mean((df_clean$matlab_SMC - df_clean$octave_SMC)^2))
bias_equiv <- mean(df_clean$octave_SMC - df_clean$matlab_SMC)
cor_equiv  <- cor(df_clean$matlab_SMC, df_clean$octave_SMC)

cat(sprintf("Matched Timesteps    : %d hours\n", nrow(df_clean)))
cat(sprintf("SMC Divergence (Bias): %+.5f m3/m3\n", bias_equiv))
cat(sprintf("SMC Match Error(RMSE): %.5f m3/m3\n", rmse_equiv))
cat(sprintf("SMC Correlation  (r) : %.5f\n\n", cor_equiv))

if (rmse_equiv < 0.01) {
  cat("✅ SUCCESS: The Octave patches held perfectly across 2 years!\n")
} else {
  cat("⚠️ WARNING: Divergence detected over the long term.\n")
}
cat("======================================================\n")
cat(sprintf("Plots saved successfully to:\n%s\n", plots_dir))
