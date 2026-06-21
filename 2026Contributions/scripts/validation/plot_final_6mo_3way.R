# ============================================================
# plot_final_6mo_3way.R
# 3-Way SMC Comparison: Observations vs MATLAB vs Octave (Final 6mo)
# DE-STG Steglitz | Jan–Jun 2019
# ============================================================
# Created: 2026-04-08
# Purpose: Single 3-way timeseries plot (like 01_3way_SMC_60cm_timeseries.png)
#          using the FINAL fixed Octave 6-month run (Mar 13 2026).
#          Includes KGE metrics for both MATLAB vs Obs and Octave vs Obs.
# ============================================================

library(tidyverse)
library(lubridate)
library(hydroGOF)

# ============================================================
# PATHS
# ============================================================

project_root <- "/Users/armanmacair/repos/Stemmus-Scope/rSTEMMUS_SCOPE"

obs_file <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")

matlab_theta_file <- file.path(project_root,
  "2026Contributions/validation_plots/Sim_Theta.csv")

octave_theta_file <- file.path(project_root,
  "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_Test_FIXED_Final_6mo_OCTAVE_2026Mar13_1846/Sim_Theta.csv")

output_dir <- file.path(project_root,
  "2026Contributions/validation_plots/20260408_Final6mo_3way")

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("=== 3-WAY FINAL 6-MONTH COMPARISON ===\n")
cat("Obs:    ", obs_file, "\n")
cat("MATLAB: ", matlab_theta_file, "\n")
cat("Octave: ", octave_theta_file, "\n")
cat("Output: ", output_dir, "\n\n")

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
  } else {
    idx_60cm <- idx_60cm[1]
  }
  smc_values <- as.numeric(raw[-(1:3), idx_60cm])
  cat(sprintf("  %s: %d timesteps, range: [%.4f, %.4f]\n",
              label, length(smc_values), min(smc_values, na.rm=TRUE), max(smc_values, na.rm=TRUE)))
  return(smc_values)
}

# ============================================================
# LOAD DATA
# ============================================================

cat("Loading observations...\n")
obs_raw <- readRDS(obs_file)
obs_df <- obs_raw %>%
  filter(timestamp >= as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
         timestamp <= as.POSIXct("2019-06-30 23:00:00", tz = "UTC")) %>%
  select(timestamp, obs_SMC = SMC_60cm) %>%
  mutate(obs_SMC = obs_SMC / 100)
cat(sprintf("  Observations: %d timesteps\n\n", nrow(obs_df)))

cat("Loading MATLAB...\n")
matlab_smc <- extract_smc_60cm(matlab_theta_file, "MATLAB")
matlab_start <- min(obs_raw$timestamp, na.rm = TRUE)
matlab_df <- tibble(
  timestamp = matlab_start + hours(0:(length(matlab_smc) - 1)),
  matlab_SMC = matlab_smc
) %>%
  filter(timestamp >= as.POSIXct("2019-01-01 00:00:00", tz = "UTC"),
         timestamp <= as.POSIXct("2019-06-30 23:00:00", tz = "UTC"))
cat(sprintf("  MATLAB (filtered): %d timesteps\n\n", nrow(matlab_df)))

cat("Loading Octave (Final 6mo)...\n")
octave_smc <- extract_smc_60cm(octave_theta_file, "Octave Final")
octave_df <- tibble(
  timestamp = as.POSIXct("2019-01-01 00:00:00", tz = "UTC") + hours(0:(length(octave_smc) - 1)),
  octave_SMC = octave_smc
)
cat(sprintf("  Octave (full): %d timesteps\n\n", nrow(octave_df)))

# ============================================================
# MERGE & METRICS
# ============================================================

combined <- obs_df %>%
  left_join(matlab_df, by = "timestamp") %>%
  left_join(octave_df, by = "timestamp")

valid <- combined %>% filter(!is.na(obs_SMC), !is.na(matlab_SMC), !is.na(octave_SMC))
cat(sprintf("Merged valid rows: %d\n\n", nrow(valid)))

# KGE — hydroGOF uses KGE(sim, obs)
kge_matlab  <- KGE(valid$matlab_SMC,  valid$obs_SMC,  out.type = "full")
kge_octave  <- KGE(valid$octave_SMC,  valid$obs_SMC,  out.type = "full")

bias_matlab <- mean(valid$matlab_SMC  - valid$obs_SMC,  na.rm = TRUE)
bias_octave <- mean(valid$octave_SMC  - valid$obs_SMC,  na.rm = TRUE)
rmse_matlab <- sqrt(mean((valid$matlab_SMC  - valid$obs_SMC)^2,  na.rm = TRUE))
rmse_octave <- sqrt(mean((valid$octave_SMC  - valid$obs_SMC)^2,  na.rm = TRUE))

cat("=== MATLAB vs Observations ===\n")
cat(sprintf("  KGE:  %.3f\n", kge_matlab$KGE.value))
cat(sprintf("  r:    %.3f\n", kge_matlab$KGE.elements["r"]))
cat(sprintf("  Beta: %.3f\n", kge_matlab$KGE.elements["Beta"]))
cat(sprintf("  Bias: %+.4f m³/m³\n", bias_matlab))
cat(sprintf("  RMSE: %.4f m³/m³\n\n", rmse_matlab))

cat("=== Octave (Final) vs Observations ===\n")
cat(sprintf("  KGE:  %.3f\n", kge_octave$KGE.value))
cat(sprintf("  r:    %.3f\n", kge_octave$KGE.elements["r"]))
cat(sprintf("  Beta: %.3f\n", kge_octave$KGE.elements["Beta"]))
cat(sprintf("  Bias: %+.4f m³/m³\n", bias_octave))
cat(sprintf("  RMSE: %.4f m³/m³\n\n", rmse_octave))

# ============================================================
# BUILD ANNOTATION TEXT (top-right inset)
# ============================================================

annotation_text <- paste0(
  "MATLAB vs Obs\n",
  sprintf("  Alpha   : %.3f\n",  kge_matlab$KGE.elements["Alpha"]),
  sprintf("  Beta    : %.3f\n",  kge_matlab$KGE.elements["Beta"]),
  sprintf("  KGE     : %.3f\n\n", kge_matlab$KGE.value),
  "Octave vs Obs\n",
  sprintf("  Alpha   : %.3f\n",  kge_octave$KGE.elements["Alpha"]),
  sprintf("  Beta    : %.3f\n",  kge_octave$KGE.elements["Beta"]),
  sprintf("  KGE     : %.3f",    kge_octave$KGE.value)
)

# ============================================================
# PLOT
# ============================================================

plot_df <- combined %>%
  select(timestamp, obs_SMC, matlab_SMC, octave_SMC) %>%
  pivot_longer(cols = c(obs_SMC, matlab_SMC, octave_SMC),
               names_to = "source", values_to = "SMC") %>%
  mutate(source = recode(source,
    obs_SMC    = "Observations",
    matlab_SMC = "MATLAB",
    octave_SMC = "Octave (Final Fix)"
  ))

p <- ggplot(plot_df, aes(x = timestamp, y = SMC, color = source, linewidth = source)) +
  geom_line(alpha = 0.88) +
  scale_color_manual(values = c(
    "Observations"      = "black",
    "MATLAB"            = "#2166AC",
    "Octave (Final Fix)"= "#B2182B"
  )) +
  scale_linewidth_manual(values = c(
    "Observations"      = 1.0,
    "MATLAB"            = 0.9,
    "Octave (Final Fix)"= 0.9
  ), guide = "none") +
  annotate("label",
           x = as.POSIXct("2019-04-01", tz = "UTC"),
           y = 0.415,
           label = annotation_text,
           hjust = 0, vjust = 1,
           size = 3.2, family = "mono",
           fill = "white", color = "gray20",
           label.padding = unit(0.4, "lines"),
           label.r = unit(0.15, "lines")) +
  coord_cartesian(ylim = c(0.05, 0.45)) +
  labs(
    title    = "Soil Moisture at 60 cm — 3-Way Comparison",
    subtitle = "DE-STG Steglitz | Jan–Jun 2019 | Octave Final Fix (Mar 13 2026)",
    x        = "Date",
    y        = expression(paste("Volumetric Water Content (m"^3, " m"^-3, ")")),
    color    = "Source"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position      = "bottom",
    plot.title           = element_text(face = "bold", size = 15),
    plot.subtitle        = element_text(size = 11, color = "gray40"),
    panel.grid.minor     = element_blank(),
    legend.title         = element_blank()
  )

out_file <- file.path(output_dir, "01_3way_SMC_60cm_timeseries_Final6mo.png")
ggsave(out_file, p, width = 14, height = 6, dpi = 150)
cat("Saved:", out_file, "\n")
