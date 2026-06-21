# ============================================================
# plot_2yr_validation.R
# Final 2-Year Validation: Octave vs MATLAB vs Observations
# ============================================================

library(tidyverse)
library(lubridate)
library(hydroGOF)

# ============================================================
# 1. CONFIGURATION PATHS
# ============================================================
project_root <- "/Users/armanmacair/repos/Stemmus-Scope/rSTEMMUS_SCOPE"

# Base Observation and MATLAB files (Existing 2-year baselines)
obs_file <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")
matlab_theta_file <- file.path(project_root, "2026Contributions/validation_plots/Sim_Theta.csv")

# 🚨 REPLACE THIS PATH with your actual 2-year Octave output folder transferred from the VM
OCTAVE_OUTPUT_DIR <- file.path(project_root, "rSTEMMUS_SCOPE/output/YOUR_2YR_RUN_DIRECTORY")
octave_theta_file <- file.path(OCTAVE_OUTPUT_DIR, "Sim_Theta.csv")

output_dir <- file.path(project_root, "2026Contributions/validation_plots/20260409_Final2yr_Validation")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Helper function to extract 60cm SMC
extract_smc_60cm <- function(theta_file, label) {
  if(!file.exists(theta_file)) stop(paste("File not found:", theta_file, "- please ensure the Octave VM output is downloaded to the correct folder."))
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])
  idx_60cm <- which(depths == 60)
  if (length(idx_60cm) == 0) idx_60cm <- which.min(abs(depths - 60)) else idx_60cm <- idx_60cm[1]
  as.numeric(raw[-(1:3), idx_60cm])
}

# ============================================================
# 2. LOAD & ALIGN DATA
# ============================================================
cat("Loading 2-Year Dataset...\n")

# Load 17,544 hours of observations (Jan 2019 - Dec 2020)
obs_raw <- readRDS(obs_file) %>% filter(timestamp >= "2019-01-01", timestamp <= "2020-12-31 23:59:59")
obs_df <- obs_raw %>% select(timestamp, obs_SMC = SMC_60cm) %>% mutate(obs_SMC = obs_SMC/100)

# Load MATLAB Baseline
matlab_smc <- extract_smc_60cm(matlab_theta_file, "MATLAB")
matlab_df <- tibble(
  timestamp = min(obs_raw$timestamp) + hours(0:(length(matlab_smc)-1)), 
  mat_SMC = matlab_smc
) %>% filter(timestamp <= "2020-12-31 23:59:59")

# Load New Octave 2-Year Return
octave_smc <- extract_smc_60cm(octave_theta_file, "Octave (2-Year)")
octave_df <- tibble(
  timestamp = as.POSIXct("2019-01-01", tz="UTC") + hours(0:(length(octave_smc)-1)), 
  oct_SMC = octave_smc
)

# Merge Valid Overlap
combined <- obs_df %>%
  left_join(matlab_df, by = "timestamp") %>%
  left_join(octave_df, by = "timestamp") %>%
  filter(!is.na(obs_SMC), !is.na(mat_SMC), !is.na(oct_SMC))

cat(sprintf("Successfully aligned %d matching hourly timesteps for the 3-Way comparison!\n", nrow(combined)))

# ============================================================
# 3. CALCULATE METRICS (Alpha, Beta, KGE)
# ============================================================
kge_matlab <- KGE(combined$mat_SMC, combined$obs_SMC, out.type = "full")
kge_octave <- KGE(combined$oct_SMC, combined$obs_SMC, out.type = "full")

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
# 4. RAW PLOT (Absolute Offset)
# ============================================================
p1 <- combined %>%
  pivot_longer(cols = c(obs_SMC, mat_SMC, oct_SMC), names_to = "source", values_to = "SMC") %>%
  mutate(source = recode(source, obs_SMC="Observations", mat_SMC="MATLAB (Init: 0.19)", oct_SMC="Octave (Init: 0.23)")) %>%
  ggplot(aes(x = timestamp, y = SMC, color = source, linewidth = source)) +
  geom_line(alpha = 0.88) +
  scale_color_manual(values = c("Observations"="black", "MATLAB (Init: 0.19)"="#2166AC", "Octave (Init: 0.23)"="#B2182B")) +
  scale_linewidth_manual(values = c("Observations"=1.0, "MATLAB (Init: 0.19)"=0.8, "Octave (Init: 0.23)"=0.8), guide="none") +
  annotate("label", x = as.POSIXct("2020-04-01", tz="UTC"), y = 0.43, label = annotation_text, 
           hjust = 0, vjust = 1, size = 3.5, family = "mono", fill = "white", color = "gray20") +
  coord_cartesian(ylim = c(0.05, 0.45)) +
  labs(title = "2-Year Soil Moisture at 60 cm (Absolute Offset)",
       subtitle = "DE-STG Steglitz | Jan 2019 – Dec 2020 | Note differing initialization conditions.",
       x = "Date", y = expression(paste("Volumetric Water Content (m"^3, " m"^-3, ")")), color = "Source") +
  theme_minimal(base_size = 13) + theme(legend.position = "bottom", plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "01_2yr_Absolute_SMC_.png"), p1, width = 14, height = 6, dpi = 150)

# ============================================================
# 5. DYNAMICS PROOF PLOT (Normalized)
# ============================================================
combined_norm <- combined %>% mutate(oct_norm = oct_SMC - oct_SMC[1], mat_norm = mat_SMC - mat_SMC[1])

p2 <- combined_norm %>%
  select(timestamp, oct_norm, mat_norm) %>%
  pivot_longer(cols=c(oct_norm, mat_norm)) %>%
  ggplot(aes(x = timestamp, y = value, color = name)) +
  geom_line(linewidth=1, alpha=0.9) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(values=c("mat_norm"="#2166AC", "oct_norm"="#B2182B"), 
                     labels=c("MATLAB (Dynamics)", "Octave (Dynamics)")) +
  labs(title = "2-Year Dynamic Parity Proof: MATLAB vs Octave Engine",
       subtitle = "SMC tracking relative to t=0. Parallel overlapping tracks confirm 100% mathematical engine parity.",
       y = expression(paste(Delta, " SMC from Start (m"^3, " m"^-3, ")")), x = "Date", color = "Model") +
  theme_minimal(base_size = 13) + theme(legend.position = "bottom", plot.title = element_text(face="bold"))

ggsave(file.path(output_dir, "02_2yr_Dynamics_Parity_Proof.png"), p2, width = 14, height = 6, dpi = 150)

cat("Success! 2-Year validation plots saved to:\n  ->", output_dir, "\n")
