# ============================================================
# validate_3d_zerorain.R
# 4-way comparison for Jan 1-3, 2019 (72 hours)
#   1. Observations (sensor at 60cm)
#   2. MATLAB baseline (Sim_Theta.csv, 2-year run)
#   3. Octave 6-month run (real precipitation)
#   4. Octave 3-day zero-rain experiment
# ============================================================

library(tidyverse)
library(lubridate)

# ============================================================
# PATHS
# ============================================================
project_root  <- getwd()                    # .../2026Contributions
repo_root     <- dirname(project_root)       # .../rSTEMMUS_SCOPE

obs_file      <- file.path(project_root, "EC_DWD_ROTH_clean.rds")
matlab_theta  <- file.path(project_root, "validation_plots/Sim_Theta.csv")
matlab_flux   <- file.path(project_root, "matlabfluxes.csv")
oct6mo_theta  <- file.path(repo_root, "rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_TempSMC_6mo_OCTAVE_2026Feb13_1041/Sim_Theta.csv")
oct6mo_flux   <- file.path(repo_root, "rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_TempSMC_6mo_OCTAVE_2026Feb13_1041/fluxes.csv")
oct3d_theta   <- file.path(repo_root, "rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_TempSMC_3d_Zerorain_OCTAVE_2026Feb24_1346/Sim_Theta.csv")
oct3d_flux    <- file.path(repo_root, "rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_TempSMC_3d_Zerorain_OCTAVE_2026Feb24_1346/fluxes.csv")

plots_dir <- file.path(project_root, "validation_plots_3d_zerorain")
if (!dir.exists(plots_dir)) dir.create(plots_dir, recursive = TRUE)

# Window: first 3 days
t_start <- as.POSIXct("2019-01-01 00:00:00", tz = "UTC")
t_end   <- as.POSIXct("2019-01-03 23:00:00", tz = "UTC")
n_hrs   <- 72   # 3 days × 24 hours

# ============================================================
# HELPER: extract SMC at ~60cm from Sim_Theta.csv
# ============================================================
extract_smc <- function(path, n = NULL) {
  raw    <- read.csv(path, header = FALSE)
  depths <- as.numeric(raw[1, ])
  idx    <- which.min(abs(depths - 60))
  vals   <- as.numeric(raw[-(1:3), idx])
  if (!is.null(n)) vals <- head(vals, n)
  vals
}

# ============================================================
# HELPER: extract LE (lEtot) from fluxes.csv
# ============================================================
extract_le <- function(path, n = NULL) {
  raw   <- read.csv(path, header = FALSE)
  names_row <- as.character(raw[1, ])
  idx   <- grep("lEtot|lE$|latentHeat", names_row, ignore.case = TRUE)[1]
  vals  <- as.numeric(raw[-(1:3), idx])
  if (!is.null(n)) vals <- head(vals, n)
  vals
}

# ============================================================
# LOAD OBSERVATIONS (first 72 hours)
# ============================================================
obs_full <- readRDS(obs_file)
obs_3d   <- obs_full %>%
  filter(timestamp >= t_start, timestamp <= t_end) %>%
  select(timestamp,
         obs_SMC_60cm  = SMC_60cm,
         obs_LE        = LE,
         prec_mm) %>%
  mutate(obs_SMC_60cm = obs_SMC_60cm / 100)

cat("Observations loaded:", nrow(obs_3d), "rows\n")

# ============================================================
# LOAD SMC 60cm — all 4 sources, trimmed to 72 rows
# ============================================================
ts_72 <- t_start + hours(0:(n_hrs - 1))

smc_df <- tibble(timestamp = ts_72) %>%
  mutate(
    matlab    = extract_smc(matlab_theta,  n = n_hrs),
    oct_6mo   = extract_smc(oct6mo_theta,  n = n_hrs),
    oct_0rain = extract_smc(oct3d_theta,   n = n_hrs)
  ) %>%
  left_join(obs_3d %>% select(timestamp, obs_SMC_60cm), by = "timestamp")

cat("\nSMC 60cm @ t=0 (Hour 0):\n")
cat("  MATLAB:         ", smc_df$matlab[1],    "\n")
cat("  Octave 6mo:     ", smc_df$oct_6mo[1],   "\n")
cat("  Octave 0-rain:  ", smc_df$oct_0rain[1], "\n")
cat("  Observed:       ", smc_df$obs_SMC_60cm[1], "\n")

cat("\nSMC 60cm @ t=72 (Hour 72):\n")
cat("  MATLAB:         ", tail(smc_df$matlab, 1),    "\n")
cat("  Octave 6mo:     ", tail(smc_df$oct_6mo, 1),   "\n")
cat("  Octave 0-rain:  ", tail(smc_df$oct_0rain, 1), "\n")
cat("  Observed:       ", tail(smc_df$obs_SMC_60cm, 1), "\n")

# Total change over 3 days
cat("\nSMC change over 72h (end - start):\n")
cat("  MATLAB:         ", tail(smc_df$matlab, 1)    - smc_df$matlab[1],    "\n")
cat("  Octave 6mo:     ", tail(smc_df$oct_6mo, 1)   - smc_df$oct_6mo[1],   "\n")
cat("  Octave 0-rain:  ", tail(smc_df$oct_0rain, 1) - smc_df$oct_0rain[1], "\n")

# ============================================================
# LOAD LE — MATLAB (matlabfluxes.csv) + Octave runs
# matlabfluxes.csv: row 1 = col names, row 2 = units, row 3+ = data
# ============================================================
matlab_flux_raw <- read.csv(matlab_flux, header = FALSE)
matlab_col_names <- as.character(matlab_flux_raw[1, ])
le_col_idx <- grep("lEtot", matlab_col_names, ignore.case = TRUE)[1]
matlab_le_vals <- as.numeric(matlab_flux_raw[-(1:2), le_col_idx])  # skip name+units rows

# Pad helper: always return exactly n values, fill with NA if short
pad_to <- function(x, n) { length(x) <- n; x }

le_df <- tibble(
  timestamp = ts_72,
  matlab    = pad_to(head(matlab_le_vals, n_hrs), n_hrs),
  oct_6mo   = pad_to(extract_le(oct6mo_flux,  n = n_hrs), n_hrs),
  oct_0rain = pad_to(extract_le(oct3d_flux,   n = n_hrs), n_hrs)
) %>%
  left_join(obs_3d %>% select(timestamp, obs_LE), by = "timestamp")

cat("\nMean LE over 72h (W/m²):\n")
cat("  MATLAB:         ", round(mean(le_df$matlab,    na.rm=TRUE), 2), "\n")
cat("  Octave 6mo:     ", round(mean(le_df$oct_6mo,   na.rm=TRUE), 2), "\n")
cat("  Octave 0-rain:  ", round(mean(le_df$oct_0rain, na.rm=TRUE), 2), "\n")

# ============================================================
# PLOT 1: 4-Way SMC 60cm Time Series
# ============================================================
p1 <- smc_df %>%
  pivot_longer(cols = c(obs_SMC_60cm, matlab, oct_6mo, oct_0rain),
               names_to = "source", values_to = "SMC") %>%
  mutate(source = recode(source,
    obs_SMC_60cm = "Observed (Sensor)",
    matlab       = "MATLAB (baseline)",
    oct_6mo      = "Octave (real rain, 6mo)",
    oct_0rain    = "Octave (ZERO rain, 3d)"
  )) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source, linetype = source)) +
  geom_line(linewidth = 1.1) +
  scale_color_manual(values = c(
    "Observed (Sensor)"        = "black",
    "MATLAB (baseline)"        = "#2166AC",
    "Octave (real rain, 6mo)"  = "#4DAC26",
    "Octave (ZERO rain, 3d)"   = "#D6604D"
  )) +
  scale_linetype_manual(values = c(
    "Observed (Sensor)"        = "dashed",
    "MATLAB (baseline)"        = "solid",
    "Octave (real rain, 6mo)"  = "solid",
    "Octave (ZERO rain, 3d)"   = "solid"
  )) +
  coord_cartesian(ylim = c(0.05, 0.45)) +
  labs(
    title    = "Soil Moisture at 60cm — Jan 1–3, 2019 (Zero Rain Experiment)",
    subtitle = "KEY: If Octave (red) stays wet with ZERO rain, Problem is drainage / bottom boundary — not input rain",
    x = "Time", y = "SMC (m³/m³)", color = "", linetype = ""
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"))

ggsave(file.path(plots_dir, "01_smc_4way_zerorain.png"), p1, width = 12, height = 6, dpi = 150)
cat("\nSaved: 01_smc_4way_zerorain.png\n")

# ============================================================
# PLOT 2: LE 3-Way Time Series (MATLAB vs Octave 6mo vs Octave 0-rain)
# ============================================================
p2 <- le_df %>%
  pivot_longer(cols = c(matlab, oct_6mo, oct_0rain),
               names_to = "source", values_to = "LE") %>%
  mutate(source = recode(source,
    matlab    = "MATLAB (baseline)",
    oct_6mo   = "Octave (real rain, 6mo)",
    oct_0rain = "Octave (ZERO rain, 3d)"
  )) %>%
  ggplot(aes(x = timestamp, y = LE, color = source)) +
  geom_line(linewidth = 1.1) +
  scale_color_manual(values = c(
    "MATLAB (baseline)"        = "#2166AC",
    "Octave (real rain, 6mo)"  = "#4DAC26",
    "Octave (ZERO rain, 3d)"   = "#D6604D"
  )) +
  labs(
    title    = "Latent Heat (ET) — Jan 1–3, 2019 (Zero Rain Experiment)",
    subtitle = "Octave 0-rain ≈ Octave real-rain? → ET bug is independent of precipitation input",
    x = "Time", y = "Latent Heat (W/m²)", color = ""
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"))

ggsave(file.path(plots_dir, "02_le_3way_zerorain.png"), p2, width = 12, height = 6, dpi = 150)
cat("Saved: 02_le_3way_zerorain.png\n")

# ============================================================
# PLOT 3: SMC Change Over Time (delta from initial value)
# ============================================================
p3 <- smc_df %>%
  mutate(
    matlab_delta    = matlab    - matlab[1],
    oct_6mo_delta   = oct_6mo   - oct_6mo[1],
    oct_0rain_delta = oct_0rain - oct_0rain[1]
  ) %>%
  pivot_longer(cols = c(matlab_delta, oct_6mo_delta, oct_0rain_delta),
               names_to = "source", values_to = "delta_SMC") %>%
  mutate(source = recode(source,
    matlab_delta    = "MATLAB (baseline)",
    oct_6mo_delta   = "Octave (real rain)",
    oct_0rain_delta = "Octave (ZERO rain)"
  )) %>%
  ggplot(aes(x = timestamp, y = delta_SMC, color = source)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 1.1) +
  scale_color_manual(values = c(
    "MATLAB (baseline)"  = "#2166AC",
    "Octave (real rain)" = "#4DAC26",
    "Octave (ZERO rain)" = "#D6604D"
  )) +
  labs(
    title    = "SMC Change From Initial Value at 60cm — Jan 1–3, 2019",
    subtitle = "Negative = drying (drainage working). Positive = wetting. MATLAB should stay ~flat.",
    x = "Time", y = "ΔSMC from t=0 (m³/m³)", color = ""
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"))

ggsave(file.path(plots_dir, "03_smc_delta_zerorain.png"), p3, width = 12, height = 6, dpi = 150)
cat("Saved: 03_smc_delta_zerorain.png\n")

cat("\n========== ZERO RAIN EXPERIMENT VERDICT ==========\n")
cat("If Octave 0-rain SMC still RISES: drainage/bottom boundary is blocked.\n")
cat("If Octave 0-rain SMC DROPS or stays flat: issue was precipitation handling.\n")
oct_change <- tail(smc_df$oct_0rain, 1) - smc_df$oct_0rain[1]
mat_change <- tail(smc_df$matlab, 1) - smc_df$matlab[1]
cat(sprintf("Octave 0-rain total SMC change: %+.4f m3/m3\n", oct_change))
cat(sprintf("MATLAB baseline total change:   %+.4f m3/m3\n", mat_change))
if (oct_change > 0.01) {
  cat("=> VERDICT: Octave soil is WETTING with zero rain. DRAINAGE IS BROKEN.\n")
} else if (oct_change < -0.001) {
  cat("=> VERDICT: Octave soil is DRAINING. The input rain was the problem.\n")
} else {
  cat("=> VERDICT: SMC approximately stable. Marginal drainage.\n")
}
cat("===================================================\n")
cat("\nAll plots saved to:", plots_dir, "\n")
