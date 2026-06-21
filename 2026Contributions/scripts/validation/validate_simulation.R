## ═══════════════════════════════════════════════════════════════════════════
## validate_simulation.R — Standard Site & Machine Agnostic Validation
## ═══════════════════════════════════════════════════════════════════════════
##
## USAGE:
##   Rscript validate_simulation.R <sim_output_dir> <obs_rds_file> [depth_cm]
##
## EXAMPLES:
##   Rscript validate_simulation.R rSTEMMUS_SCOPE/output/DE-STG_..._OCTAVE_2026Apr20 2026Contributions/EC_DWD_ROTH_clean.rds 60
##   Rscript validate_simulation.R rSTEMMUS_SCOPE/output/DE-STG_..._MATLAB_2026Apr22 2026Contributions/EC_DWD_ROTH_clean.rds 60
##
## WHAT IT DOES:
##   1. Reads Sim_Theta.csv from the simulation output directory
##   2. Reads the observation .rds file
##   3. Computes r, KGE, RMSE, Bias at the specified depth
##   4. Generates 5 standard validation plots + metrics CSV
##   5. Saves everything into a validation/ subfolder inside the sim output dir
##
## REQUIREMENTS:
##   - tidyverse, lubridate
##   - Observation .rds must have: timestamp (POSIXct), SMC_{depth}cm (numeric, %)
##   - Sim_Theta.csv must follow standard STEMMUS-SCOPE 54-column depth format
##
## ═══════════════════════════════════════════════════════════════════════════

# ── Parse arguments ─────────────────────────────────────────────────────
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  cat("Usage: Rscript validate_simulation.R <sim_output_dir> <obs_rds_file> [depth_cm]\n")
  cat("\n")
  cat("  sim_output_dir : Path to STEMMUS-SCOPE output directory (must contain Sim_Theta.csv)\n")
  cat("  obs_rds_file   : Path to observation .rds file (must have timestamp + SMC_{depth}cm columns)\n")
  cat("  depth_cm       : Target depth in cm (default: 60)\n")
  quit(status = 1)
}

sim_dir      <- normalizePath(args[1], mustWork = TRUE)
obs_file     <- normalizePath(args[2], mustWork = TRUE)
target_depth <- if (length(args) >= 3) as.numeric(args[3]) else 60

cat("\n")
cat("================================================================\n")
cat("  STEMMUS-SCOPE Simulation Validation\n")
cat("================================================================\n")
cat(sprintf("  Simulation dir : %s\n", sim_dir))
cat(sprintf("  Observations   : %s\n", obs_file))
cat(sprintf("  Target depth   : %d cm\n", target_depth))
cat(sprintf("  Timestamp      : %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat("================================================================\n\n")

# ── Load libraries ──────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
})

# ── Define STEMMUS-SCOPE depth structure (54 layers) ────────────────────
depth_theta <- c(1,2,3,5,7,9,11,13,15,17,19,21,23,25,27.5,30,32.5,35,40,45,50,55,60,
                 70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,
                 245,260,280,300,320,340,360,380,400,420,440,460,480,500)
depth_layer <- c(1,1,1,2,2,2,2,2,2,2,2,2,2,2,2.5,2.5,2.5,2.5,5,5,5,5,5,
                 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,15,15,
                 20,20,20,20,20,20,20,20,20,20,20,20)

col_names <- paste0("depth_", depth_theta, "_", depth_layer)

# ── Find the correct column for target depth ────────────────────────────
depth_idx <- which(depth_theta == target_depth)
if (length(depth_idx) == 0) {
  cat(sprintf("ERROR: Depth %d cm not found in STEMMUS-SCOPE depth grid.\n", target_depth))
  cat(sprintf("Available depths: %s\n", paste(depth_theta, collapse=", ")))
  quit(status = 1)
}
depth_idx <- depth_idx[1]
sim_col_name <- col_names[depth_idx]
cat(sprintf("  Using column %d ('%s') for %d cm depth\n", depth_idx, sim_col_name, target_depth))

# ── Load simulation output ──────────────────────────────────────────────
sim_path <- file.path(sim_dir, "Sim_Theta.csv")
if (!file.exists(sim_path)) {
  cat(sprintf("ERROR: Sim_Theta.csv not found at: %s\n", sim_path))
  quit(status = 1)
}

sim_df <- read_csv(sim_path, skip = 3, col_names = FALSE, show_col_types = FALSE)
names(sim_df) <- col_names
n_ts <- nrow(sim_df)
cat(sprintf("  Loaded %d simulation timesteps\n", n_ts))

# ── Determine simulation start time ────────────────────────────────────
start_time <- as.POSIXct("2019-01-01 00:00:00", tz = "UTC")

meta_path <- file.path(sim_dir, "run_metadata.json")
if (file.exists(meta_path)) {
  tryCatch({
    meta <- jsonlite::fromJSON(meta_path)
    if (!is.null(meta$start_time)) {
      start_time <- as.POSIXct(meta$start_time, tz = "UTC")
      cat(sprintf("  Start time from metadata: %s\n", start_time))
    }
  }, error = function(e) {
    cat("  No metadata parsed, using default start: 2019-01-01\n")
  })
} else {
  cat("  No run_metadata.json, using default start: 2019-01-01\n")
}

sim_df <- sim_df %>%
  mutate(timestamp = seq.POSIXt(from = start_time, by = "hour", length.out = n_ts))

# ── Load observations ──────────────────────────────────────────────────
obs_df <- readRDS(obs_file)

obs_col <- paste0("SMC_", target_depth, "cm")
if (!obs_col %in% names(obs_df)) {
  cat(sprintf("ERROR: Column '%s' not found in observations.\n", obs_col))
  cat(sprintf("Available SMC columns: %s\n",
              paste(grep("SMC", names(obs_df), value = TRUE), collapse = ", ")))
  quit(status = 1)
}

obs_df <- obs_df %>%
  filter(!is.na(timestamp)) %>%
  mutate(timestamp = as.POSIXct(timestamp, tz = "UTC"),
         obs_smc = .data[[obs_col]] / 100) %>%
  select(timestamp, obs_smc)
cat(sprintf("  Loaded %d observation timesteps (column: %s)\n", nrow(obs_df), obs_col))

# ── Merge ──────────────────────────────────────────────────────────────
df <- inner_join(obs_df,
  sim_df %>% select(timestamp, sim_smc = all_of(sim_col_name)),
  by = "timestamp") %>%
  filter(!is.na(obs_smc), !is.na(sim_smc))
cat(sprintf("  Merged: %d matched timesteps\n\n", nrow(df)))

if (nrow(df) < 24) {
  cat("ERROR: Fewer than 24 matched timesteps. Check time alignment.\n")
  quit(status = 1)
}

# ── Compute metrics ────────────────────────────────────────────────────
sim <- df$sim_smc; obs <- df$obs_smc
n <- length(sim)
r_val <- cor(sim, obs)
bias_val <- mean(sim - obs)
rmse_val <- sqrt(mean((sim - obs)^2))
mae_val <- mean(abs(sim - obs))
alpha_val <- sd(sim) / sd(obs)
beta_val <- mean(sim) / mean(obs)
kge_val <- 1 - sqrt((r_val - 1)^2 + (alpha_val - 1)^2 + (beta_val - 1)^2)
nse_val <- 1 - sum((sim - obs)^2) / sum((obs - mean(obs))^2)

cat("================================================================\n")
cat(sprintf("  PERFORMANCE METRICS - SMC at %d cm depth\n", target_depth))
cat("================================================================\n")
cat(sprintf("  n (matched hours) : %d\n", n))
cat(sprintf("  r (correlation)   : %.4f\n", r_val))
cat(sprintf("  r2                : %.4f\n", r_val^2))
cat(sprintf("  KGE               : %.4f\n", kge_val))
cat(sprintf("    alpha           : %.4f\n", alpha_val))
cat(sprintf("    beta            : %.4f\n", beta_val))
cat(sprintf("  NSE               : %.4f\n", nse_val))
cat(sprintf("  RMSE              : %.4f\n", rmse_val))
cat(sprintf("  MAE               : %.4f\n", mae_val))
cat(sprintf("  Bias              : %+.4f\n", bias_val))
cat("================================================================\n\n")

# ── Create output directory ────────────────────────────────────────────
out_dir <- file.path(sim_dir, "validation")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ── Plot 1: Time series ───────────────────────────────────────────────
png(file.path(out_dir, "01_timeseries.png"), width = 1400, height = 600, res = 120)
par(mar = c(4, 4, 3, 1))
plot(df$timestamp, df$obs_smc, type = "l", col = "black", lwd = 1.5,
     ylim = range(c(df$obs_smc, df$sim_smc), na.rm = TRUE),
     xlab = "Date", ylab = "SMC [m3/m3]",
     main = sprintf("SMC at %dcm: Obs vs Sim (r=%.3f, KGE=%.3f)", target_depth, r_val, kge_val))
lines(df$timestamp, df$sim_smc, col = "blue", lwd = 1.2)
legend("topright", c("Observed", "Simulated"),
       col = c("black", "blue"), lwd = c(1.5, 1.2), bty = "n")
dev.off()

# ── Plot 2: Scatter ───────────────────────────────────────────────────
png(file.path(out_dir, "02_scatter.png"), width = 600, height = 600, res = 120)
plot(df$obs_smc, df$sim_smc, pch = 20, cex = 0.3, col = rgb(0, 0, 1, 0.3),
     xlab = "Observed SMC", ylab = "Simulated SMC", asp = 1,
     main = sprintf("r=%.3f, KGE=%.3f, RMSE=%.4f", r_val, kge_val, rmse_val))
abline(0, 1, col = "red", lwd = 2)
abline(lm(sim_smc ~ obs_smc, data = df), col = "blue", lwd = 1, lty = 2)
legend("topleft", c("1:1 line", "Linear fit"),
       col = c("red", "blue"), lwd = c(2, 1), lty = c(1, 2), bty = "n")
dev.off()

# ── Plot 3: Monthly means ────────────────────────────────────────────
df_monthly <- df %>%
  mutate(month = floor_date(timestamp, "month")) %>%
  group_by(month) %>%
  summarise(obs = mean(obs_smc, na.rm = TRUE),
            sim = mean(sim_smc, na.rm = TRUE), .groups = "drop")

png(file.path(out_dir, "03_monthly_mean.png"), width = 1000, height = 500, res = 120)
par(mar = c(4, 4, 3, 1))
yl <- range(c(df_monthly$obs, df_monthly$sim), na.rm = TRUE)
plot(df_monthly$month, df_monthly$obs, type = "b", pch = 19, col = "black", lwd = 2,
     ylim = yl, xlab = "Month", ylab = "Monthly Mean SMC",
     main = sprintf("Monthly Mean SMC at %dcm", target_depth))
lines(df_monthly$month, df_monthly$sim, type = "b", pch = 17, col = "blue", lwd = 1.5)
legend("topright", c("Observed", "Simulated"),
       col = c("black", "blue"), pch = c(19, 17), lwd = c(2, 1.5), bty = "n")
dev.off()

# ── Plot 4: Residuals ────────────────────────────────────────────────
png(file.path(out_dir, "04_residuals.png"), width = 1400, height = 500, res = 120)
par(mar = c(4, 4, 3, 1))
resid <- df$sim_smc - df$obs_smc
plot(df$timestamp, resid, type = "l", col = "steelblue", lwd = 0.5,
     xlab = "Date", ylab = "Residual [m3/m3]",
     main = sprintf("Residuals at %dcm | Mean Bias=%+.4f", target_depth, bias_val))
abline(h = 0, col = "red", lwd = 1.5)
abline(h = bias_val, col = "orange", lwd = 1, lty = 2)
dev.off()

# ── Plot 5: Error histogram ─────────────────────────────────────────
png(file.path(out_dir, "05_error_histogram.png"), width = 700, height = 500, res = 120)
hist(resid, breaks = 80, col = "steelblue", border = "white",
     xlab = "Error [m3/m3]",
     main = sprintf("Error Distribution (n=%d, bias=%+.4f)", n, bias_val))
abline(v = 0, col = "red", lwd = 2)
abline(v = bias_val, col = "orange", lwd = 2, lty = 2)
dev.off()

# ── Save metrics CSV ─────────────────────────────────────────────────
metrics_df <- data.frame(
  metric = c("n","r","r2","KGE","NSE","RMSE","MAE","Bias","alpha","beta",
             "sim_mean","obs_mean","sim_sd","obs_sd"),
  value = round(c(n, r_val, r_val^2, kge_val, nse_val, rmse_val, mae_val, bias_val,
            alpha_val, beta_val, mean(sim), mean(obs), sd(sim), sd(obs)), 6)
)
write.csv(metrics_df, file.path(out_dir, "06_metrics.csv"), row.names = FALSE)

# ── Save summary text ────────────────────────────────────────────────
summary_lines <- c(
  "STEMMUS-SCOPE Validation Summary",
  "================================",
  sprintf("Simulation : %s", basename(sim_dir)),
  sprintf("Observations : %s", basename(obs_file)),
  sprintf("Depth : %d cm", target_depth),
  sprintf("Matched hours : %d", n),
  sprintf("Generated : %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "METRICS",
  sprintf("  r     = %.4f", r_val),
  sprintf("  r2    = %.4f", r_val^2),
  sprintf("  KGE   = %.4f", kge_val),
  sprintf("  NSE   = %.4f", nse_val),
  sprintf("  RMSE  = %.4f m3/m3", rmse_val),
  sprintf("  MAE   = %.4f m3/m3", mae_val),
  sprintf("  Bias  = %+.4f m3/m3", bias_val)
)
writeLines(summary_lines, file.path(out_dir, "00_summary.txt"))

# ── Done ─────────────────────────────────────────────────────────────
cat(sprintf("Validation outputs saved to: %s/\n", out_dir))
cat("  00_summary.txt\n  01_timeseries.png\n  02_scatter.png\n")
cat("  03_monthly_mean.png\n  04_residuals.png\n  05_error_histogram.png\n")
cat("  06_metrics.csv\n\n")
cat(sprintf("RESULT: r=%.4f | KGE=%.4f | RMSE=%.4f | Bias=%+.4f\n",
            r_val, kge_val, rmse_val, bias_val))
