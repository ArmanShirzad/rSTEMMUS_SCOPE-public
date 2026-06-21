# ============================================================
# plot_validation.R
# Generic Post-Simulation Validation: Octave vs MATLAB vs Observations
# ============================================================
# Usage:
#   Rscript 2026Contributions/plot_validation.R \
#     --octave_dir <path> --obs_file <path> --matlab_theta <path> \
#     --start_time "2019-01-01" --end_time "2020-12-31" \
#     --site_label "DE-STG" --run_label "2yr_validation"
#
# Or source it with variables pre-set (for interactive use).
# ============================================================

library(tidyverse)
library(lubridate)
library(hydroGOF)

# ============================================================
# PARSE ARGUMENTS
# ============================================================
args <- commandArgs(trailingOnly = TRUE)

parse_arg <- function(flag, default = NULL) {
  idx <- which(args == flag)
  if (length(idx) > 0 && idx < length(args)) return(args[idx + 1])
  return(default)
}

project_root <- getwd()

# Required args (with fallback defaults for DE-STG)
octave_dir    <- parse_arg("--octave_dir")
obs_file      <- parse_arg("--obs_file",      file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds"))
matlab_theta  <- parse_arg("--matlab_theta",  file.path(project_root, "2026Contributions/validation_plots/Sim_Theta.csv"))
start_time    <- parse_arg("--start_time",    "2019-01-01")
end_time      <- parse_arg("--end_time",      "2020-12-31")
site_label    <- parse_arg("--site_label",    "DE-STG")
run_label     <- parse_arg("--run_label",     "validation")

# Auto-discover octave_dir from latest output dir file if not provided
if (is.null(octave_dir)) {
  latest_file <- Sys.glob(file.path(project_root, sprintf("2026Contributions/latest_*%s*_output_dir.txt", run_label)))
  if (length(latest_file) > 0) {
    octave_dir <- trimws(readLines(latest_file[1]))
    cat(sprintf("Auto-discovered Octave output: %s\n", octave_dir))
  } else {
    stop("No --octave_dir provided and no latest_*_output_dir.txt found. Provide the output directory path.")
  }
}

octave_theta <- file.path(octave_dir, "Sim_Theta.csv")
octave_flux  <- file.path(octave_dir, "fluxes.csv")

# Create output directory with date and run label
date_stamp <- format(Sys.Date(), "%Y%m%d")
output_dir <- file.path(project_root, sprintf("2026Contributions/validation_plots/%s_%s_%s", date_stamp, site_label, run_label))
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("============================================================\n")
cat("  Post-Simulation Validation\n")
cat(sprintf("  Site: %s | Run: %s\n", site_label, run_label))
cat(sprintf("  Period: %s to %s\n", start_time, end_time))
cat(sprintf("  Octave: %s\n", octave_dir))
cat(sprintf("  Output: %s\n", output_dir))
cat("============================================================\n\n")

# ============================================================
# HELPER: Extract SMC at target depth from Sim_Theta.csv
# ============================================================
extract_smc <- function(theta_file, target_depth = 60) {
  if (!file.exists(theta_file)) stop(paste("File not found:", theta_file))
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])
  idx <- which(depths == target_depth)
  if (length(idx) == 0) {
    idx <- which.min(abs(depths - target_depth))
    cat(sprintf("  Exact %dcm not found, using %.0fcm (col %d)\n", target_depth, depths[idx], idx))
  } else {
    idx <- idx[1]
  }
  as.numeric(raw[-(1:3), idx])
}

# ============================================================
# LOAD & ALIGN DATA
# ============================================================
cat("Loading data...\n")

# Observations
obs_raw <- readRDS(obs_file) %>%
  filter(timestamp >= as.POSIXct(start_time, tz="UTC"),
         timestamp <= as.POSIXct(paste0(end_time, " 23:59:59"), tz="UTC"))
obs_df <- obs_raw %>%
  select(timestamp, obs_SMC = SMC_60cm) %>%
  mutate(obs_SMC = obs_SMC / 100)
cat(sprintf("  Observations: %d rows\n", nrow(obs_df)))

# MATLAB baseline
matlab_smc <- extract_smc(matlab_theta, 60)
matlab_df <- tibble(
  timestamp = min(obs_raw$timestamp) + hours(0:(length(matlab_smc)-1)),
  mat_SMC = matlab_smc
) %>% filter(timestamp <= as.POSIXct(paste0(end_time, " 23:59:59"), tz="UTC"))
cat(sprintf("  MATLAB: %d timesteps\n", nrow(matlab_df)))

# Octave
octave_smc <- extract_smc(octave_theta, 60)
octave_df <- tibble(
  timestamp = as.POSIXct(start_time, tz="UTC") + hours(0:(length(octave_smc)-1)),
  oct_SMC = octave_smc
)
cat(sprintf("  Octave: %d timesteps\n", nrow(octave_df)))

# Merge
combined <- obs_df %>%
  left_join(matlab_df, by = "timestamp") %>%
  left_join(octave_df, by = "timestamp") %>%
  filter(!is.na(obs_SMC), !is.na(mat_SMC), !is.na(oct_SMC))
cat(sprintf("  Aligned: %d matching timesteps\n\n", nrow(combined)))

# ============================================================
# METRICS
# ============================================================
kge_matlab <- KGE(combined$mat_SMC, combined$obs_SMC, out.type = "full")
kge_octave <- KGE(combined$oct_SMC, combined$obs_SMC, out.type = "full")

rmse_mat <- sqrt(mean((combined$mat_SMC - combined$obs_SMC)^2))
rmse_oct <- sqrt(mean((combined$oct_SMC - combined$obs_SMC)^2))
rmse_equiv <- sqrt(mean((combined$mat_SMC - combined$oct_SMC)^2))
bias_mat <- mean(combined$mat_SMC - combined$obs_SMC)
bias_oct <- mean(combined$oct_SMC - combined$obs_SMC)
r_mat <- cor(combined$mat_SMC, combined$obs_SMC)
r_oct <- cor(combined$oct_SMC, combined$obs_SMC)
r_equiv <- cor(combined$mat_SMC, combined$oct_SMC)

kge_annotation <- paste0(
  "MATLAB vs Obs\n",
  sprintf("  KGE  : %.3f\n", kge_matlab$KGE.value),
  sprintf("  Alpha: %.3f\n", kge_matlab$KGE.elements["Alpha"]),
  sprintf("  Beta : %.3f\n\n", kge_matlab$KGE.elements["Beta"]),
  "Octave vs Obs\n",
  sprintf("  KGE  : %.3f\n", kge_octave$KGE.value),
  sprintf("  Alpha: %.3f\n", kge_octave$KGE.elements["Alpha"]),
  sprintf("  Beta : %.3f", kge_octave$KGE.elements["Beta"])
)

# ============================================================
# PLOT 1: Absolute SMC Time Series (3-way)
# ============================================================
cat("Generating plots...\n")

p1 <- combined %>%
  pivot_longer(cols = c(obs_SMC, mat_SMC, oct_SMC), names_to = "source", values_to = "SMC") %>%
  mutate(source = recode(source, obs_SMC="Observations", mat_SMC="MATLAB", oct_SMC="Octave")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source, linewidth = source)) +
  geom_line(alpha = 0.88) +
  scale_color_manual(values = c("Observations"="black", "MATLAB"="#2166AC", "Octave"="#B2182B")) +
  scale_linewidth_manual(values = c("Observations"=1.0, "MATLAB"=0.8, "Octave"=0.8), guide="none") +
  annotate("label", x = as.POSIXct(start_time, tz="UTC") + as.numeric(difftime(
    as.POSIXct(end_time, tz="UTC"), as.POSIXct(start_time, tz="UTC"), units="secs")) * 0.65,
    y = 0.43, label = kge_annotation,
    hjust = 0, vjust = 1, size = 3.2, family = "mono", fill = "white", color = "gray20") +
  coord_cartesian(ylim = c(0.05, 0.45)) +
  labs(title = sprintf("Soil Moisture at 60cm: %s", site_label),
       subtitle = sprintf("%s to %s | 3-Way Comparison", start_time, end_time),
       x = "Date", y = expression(paste("VWC (m"^3, " m"^-3, ")")), color = "Source") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "01_Absolute_SMC_60cm.png"), p1, width = 14, height = 6, dpi = 150)

# ============================================================
# PLOT 2: Dynamics Parity Proof (Normalized)
# ============================================================
combined_norm <- combined %>%
  mutate(oct_norm = oct_SMC - oct_SMC[1], mat_norm = mat_SMC - mat_SMC[1])

p2 <- combined_norm %>%
  select(timestamp, oct_norm, mat_norm) %>%
  pivot_longer(cols = c(oct_norm, mat_norm)) %>%
  ggplot(aes(x = timestamp, y = value, color = name)) +
  geom_line(linewidth = 1, alpha = 0.9) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("mat_norm"="#2166AC", "oct_norm"="#B2182B"),
                     labels = c("MATLAB", "Octave")) +
  labs(title = sprintf("Dynamic Parity: MATLAB vs Octave (%s)", site_label),
       subtitle = "SMC relative to t=0 (removes initialization offset)",
       y = expression(paste(Delta, " SMC (m"^3, " m"^-3, ")")), x = "Date", color = "Model") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "02_Dynamics_Parity_Proof.png"), p2, width = 14, height = 6, dpi = 150)

# ============================================================
# PLOT 3: Monthly Mean SMC
# ============================================================
monthly <- combined %>%
  mutate(month = floor_date(timestamp, "month")) %>%
  group_by(month) %>%
  summarise(Observations = mean(obs_SMC, na.rm=TRUE),
            MATLAB = mean(mat_SMC, na.rm=TRUE),
            Octave = mean(oct_SMC, na.rm=TRUE), .groups="drop")

p3 <- monthly %>%
  pivot_longer(cols = c(Observations, MATLAB, Octave), names_to = "source", values_to = "SMC") %>%
  ggplot(aes(x = month, y = SMC, color = source, group = source)) +
  geom_line(linewidth = 1.5) + geom_point(size = 3) +
  scale_x_datetime(date_labels = "%b %Y") +
  scale_color_manual(values = c("Observations"="black", "MATLAB"="#2166AC", "Octave"="#B2182B")) +
  labs(title = sprintf("Monthly Mean SMC at 60cm (%s)", site_label),
       x = "Month", y = expression(paste("Mean VWC (m"^3, " m"^-3, ")")), color = "Source") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "03_Monthly_Mean_SMC.png"), p3, width = 12, height = 6, dpi = 150)

# ============================================================
# PLOT 4: MATLAB vs Octave Scatter (1:1)
# ============================================================
p4 <- combined %>%
  ggplot(aes(x = mat_SMC, y = oct_SMC)) +
  geom_point(alpha = 0.3, color = "#4393C3", size = 1.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red", linewidth = 1) +
  geom_smooth(method = "lm", color = "#D6604D", se = TRUE, alpha = 0.2) +
  annotate("label", x = min(combined$mat_SMC) + 0.01, y = max(combined$oct_SMC) - 0.01,
           label = sprintf("RMSE: %.4f\nr: %.3f", rmse_equiv, r_equiv),
           hjust = 0, vjust = 1, size = 4, family = "mono", fill = "white") +
  labs(title = sprintf("MATLAB vs Octave: SMC 60cm (%s)", site_label),
       subtitle = "1:1 line = perfect engine equivalence",
       x = expression(paste("MATLAB VWC (m"^3, " m"^-3, ")")),
       y = expression(paste("Octave VWC (m"^3, " m"^-3, ")"))) +
  coord_equal() +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "04_Scatter_MATLAB_vs_Octave.png"), p4, width = 8, height = 8, dpi = 150)

# ============================================================
# SUMMARY STATISTICS FILE
# ============================================================
summary_text <- sprintf(
"============================================================
 Validation Summary: %s | %s
 Period: %s to %s
 Aligned timesteps: %d
============================================================

MATLAB vs Observations:
  RMSE : %.4f m3/m3
  Bias : %.4f m3/m3
  r    : %.3f
  KGE  : %.3f (Alpha=%.3f, Beta=%.3f)

Octave vs Observations:
  RMSE : %.4f m3/m3
  Bias : %.4f m3/m3
  r    : %.3f
  KGE  : %.3f (Alpha=%.3f, Beta=%.3f)

Engine Equivalence (MATLAB vs Octave):
  RMSE : %.4f m3/m3
  r    : %.3f

Octave output: %s
",
  site_label, run_label, start_time, end_time, nrow(combined),
  rmse_mat, bias_mat, r_mat, kge_matlab$KGE.value,
  kge_matlab$KGE.elements["Alpha"], kge_matlab$KGE.elements["Beta"],
  rmse_oct, bias_oct, r_oct, kge_octave$KGE.value,
  kge_octave$KGE.elements["Alpha"], kge_octave$KGE.elements["Beta"],
  rmse_equiv, r_equiv, octave_dir
)

writeLines(summary_text, file.path(output_dir, "05_Summary_Statistics.txt"))
cat(summary_text)

cat(sprintf("\nAll plots saved to:\n  -> %s\n", output_dir))
cat("Files:\n")
cat("  01_Absolute_SMC_60cm.png\n")
cat("  02_Dynamics_Parity_Proof.png\n")
cat("  03_Monthly_Mean_SMC.png\n")
cat("  04_Scatter_MATLAB_vs_Octave.png\n")
cat("  05_Summary_Statistics.txt\n")
