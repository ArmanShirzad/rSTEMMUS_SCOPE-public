# ============================================================
# compare_fluxes.R
# Investigating the "Wet Bias": Is Octave under-computing ET?
# ============================================================

library(tidyverse)
library(lubridate)

# --- Files ---
octave_flux_file <- "rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_TempSMC_6mo_OCTAVE_2026Feb13_1041/fluxes.csv"
matlab_flux_file <- "2026Contributions/validation_plots/fluxes.csv" # Need to verify this path

# --- Load Octave Fluxes ---
# lEtot is usually column 7 (Latent Heat)
# Htot is usually column 8 (Sensible Heat)
# We need to check the header first
header <- read.csv(octave_flux_file, nrows = 1, header = FALSE)
cat("Flux Columns found:", paste(as.character(header), collapse=", "), "\n")

# Assuming standard order for now, but let's be safe
oct_flux <- read.csv(octave_flux_file, skip = 3, header = FALSE)
mat_flux <- read.csv(matlab_flux_file, skip = 3, header = FALSE)

# Sync lengths
n <- min(nrow(oct_flux), nrow(mat_flux))
cat("Comparing first", n, "hours...\n")

# Extract variables (standard SCOPE output order)
# Col 7: lEtot (Latent Heat)
# Col 8: Htot  (Sensible Heat)
# Col 4: Rnet  (Net Radiation)

comp <- tibble(
  hour = 1:n,
  oct_LE = as.numeric(oct_flux[1:n, 7]),
  mat_LE = as.numeric(mat_flux[1:n, 7]),
  oct_H  = as.numeric(oct_flux[1:n, 8]),
  mat_H  = as.numeric(mat_flux[1:n, 8])
) %>%
  mutate(diff_LE = oct_LE - mat_LE)

# Statistics
mean_diff_le <- mean(comp$diff_LE, na.rm = TRUE)
total_le_loss_pct <- (sum(comp$oct_LE) / sum(comp$mat_LE) - 1) * 100

cat("\n===== ENERGY FLUX ANALYSIS (Octave vs MATLAB) =====\n")
cat(sprintf("Mean LE Bias:        %+.2f W/m2\n", mean_diff_le))
cat(sprintf("Total ET Difference: %+.1f%%\n", total_le_loss_pct))

if (total_le_loss_pct < -5) {
  cat("🚨 EXPLANATION FOUND: Octave is computing significantly LESS ET than MATLAB.\n")
  cat("   This is why the soil stays wetter.\n")
} else {
  cat("✅ ET is similar. The bias might be in the drainage (Richards eq) logic.\n")
}

# --- Plotting the difference ---
p <- ggplot(comp, aes(x = hour, y = diff_LE)) +
  geom_line(color = "red", alpha = 0.5) +
  geom_smooth(method = "gam") +
  labs(title = "Latent Heat Bias (Octave - MATLAB)",
       subtitle = "Negative values mean Octave is under-estimating ET",
       x = "Hour", y = "Δ LE (W/m2)") +
  theme_minimal()

ggsave("2026Contributions/13Feb2026/flux_bias_analysis.png", p, width = 10, height = 5)
