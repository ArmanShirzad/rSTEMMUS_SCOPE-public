## Verify the TUCC obs file has everything needed to run a 2yr STEMMUS-SCOPE
## simulation in the same way we ran ROTH. Compare schema + value ranges
## against the ROTH file directly.

suppressPackageStartupMessages({
  library(lubridate); library(dplyr)
})

tucc_path <- "2026Contributions/EC_Berlin_TUCC_adj.rds"
roth_path <- "2026Contributions/EC_DWD_ROTH_clean.rds"

stopifnot(file.exists(tucc_path), file.exists(roth_path))

tucc <- readRDS(tucc_path)
roth <- readRDS(roth_path)

cat("===== File comparison =====\n")
cat(sprintf("TUCC: %d rows x %d cols\n", nrow(tucc), ncol(tucc)))
cat(sprintf("ROTH: %d rows x %d cols\n", nrow(roth), ncol(roth)))

# Time coverage
cat("\n--- Time coverage ---\n")
ts_tucc <- range(tucc$timestamp, na.rm = TRUE)
ts_roth <- range(roth$timestamp, na.rm = TRUE)
cat(sprintf("TUCC: %s  to  %s\n", ts_tucc[1], ts_tucc[2]))
cat(sprintf("ROTH: %s  to  %s\n", ts_roth[1], ts_roth[2]))
cat(sprintf("TUCC unique years: %s\n", paste(sort(unique(year(tucc$timestamp))), collapse = ", ")))

# Required columns for input pipeline (per standardRoadmapLocation.R / scripts/runs/run_2yr_final_*.R)
required <- c("timestamp",
              "Rin", "Rli", "p", "Ta", "RH", "ea", "ws",
              "prec_mm_EC", "LAI_FP", "co2_flux",
              "soil_temp10cm", "soil_temp20cm", "soil_temp30cm", "soil_temp50cm",
              "SMC_10cm", "SMC_20cm", "SMC_30cm", "SMC_60cm")

missing_tucc <- setdiff(required, names(tucc))
present_tucc <- intersect(required, names(tucc))
cat("\n--- Required column presence (TUCC) ---\n")
cat(sprintf("Present (%d/%d):  %s\n", length(present_tucc), length(required),
            paste(present_tucc, collapse = ", ")))
if (length(missing_tucc)) {
  cat(sprintf("MISSING (%d):  %s\n", length(missing_tucc), paste(missing_tucc, collapse = ", ")))
} else {
  cat("MISSING: none\n")
}

# Validation columns
validation_cols <- c("LE", "LE.filled", "LE_clean", "ET", "ET_filled",
                     "H", "veg_fraction", "impervious_fraction", "qc_LE")
present_val <- intersect(validation_cols, names(tucc))
cat("\n--- Validation columns present in TUCC ---\n")
cat(paste(present_val, collapse = ", "), "\n")
miss_val <- setdiff(validation_cols, names(tucc))
if (length(miss_val)) cat("Missing validation cols: ", paste(miss_val, collapse = ", "), "\n")

# Value ranges and NA fractions on required input columns
cat("\n--- TUCC required-column summary (range, NA%) ---\n")
for (c in present_tucc) {
  v <- tucc[[c]]
  if (is.numeric(v)) {
    cat(sprintf("  %-15s  min=%9.3f  mean=%9.3f  max=%9.3f  NA=%5.1f%%\n",
                c, min(v, na.rm = TRUE), mean(v, na.rm = TRUE),
                max(v, na.rm = TRUE), 100 * sum(is.na(v)) / length(v)))
  } else if (inherits(v, "POSIXct")) {
    cat(sprintf("  %-15s  %s to %s\n", c, min(v, na.rm = TRUE), max(v, na.rm = TRUE)))
  }
}

# All extra columns TUCC has (not in required/validation)
extras <- setdiff(names(tucc), c(required, validation_cols))
cat(sprintf("\nTUCC has %d additional columns not in our required/validation list.\n", length(extras)))
cat("First 20 extras: ", paste(head(extras, 20), collapse = ", "), "\n")

# Sanity check: 2yr window 2019-01-01 to 2020-12-31 inclusive
need_n <- 17544
in_window <- sum(tucc$timestamp >= as.POSIXct("2019-01-01", tz = "UTC") &
                 tucc$timestamp <= as.POSIXct("2020-12-31 23:00", tz = "UTC"))
cat(sprintf("\n--- 2-year (2019-2020) window coverage in TUCC ---\n"))
cat(sprintf("Hourly rows in window: %d (need %d)\n", in_window, need_n))
cat(sprintf("Coverage: %.1f%%\n", 100 * in_window / need_n))
