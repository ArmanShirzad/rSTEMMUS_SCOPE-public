## ═══════════════════════════════════════════════════════════════════════════
## compare_octave_soilprops_vs_oldmatlab.R
## ═══════════════════════════════════════════════════════════════════════════
## PURPOSE: Compare NEW Octave (with soil properties) vs OLD MATLAB baseline
##          (the reference r=0.88 run) vs Observations at 60cm depth.
## DATE: 2026-04-22
## ═══════════════════════════════════════════════════════════════════════════

library(tidyverse)
library(lubridate)

cat("\n══════════════════════════════════════════════════════════════════\n")
cat("  3-Way Comparison: New Octave (Soil Props) vs Old MATLAB vs Obs\n")
cat("══════════════════════════════════════════════════════════════════\n\n")

# ── Depth structure (same as the reference script) ─────────────────────────────
depth_theta <- c(1,2,3,5,7,9,11,13,15,17,19,21,23,25,27.5,30,32.5,35,40,45,50,55,60,
                 70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,
                 245,260,280,300,320,340,360,380,400,420,440,460,480,500)
depth_layer <- c(1,1,1,2,2,2,2,2,2,2,2,2,2,2,2.5,2.5,2.5,2.5,5,5,5,5,5,
                 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,15,15,
                 20,20,20,20,20,20,20,20,20,20,20,20)

# ── 1. Load Observations ────────────────────────────────────────────────
steg_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
obs <- steg_df %>%
  filter(timestamp >= as.POSIXct("2019-01-01", tz="UTC"),
         timestamp <= as.POSIXct("2020-12-31 23:00", tz="UTC")) %>%
  mutate(obs_smc60 = SMC_60cm / 100) %>%
  select(timestamp, obs_smc60)
cat(sprintf("Observations: %d rows\n", nrow(obs)))

# ── 2. Load OLD MATLAB baseline (the reference r=0.88 run) ────────────────────
old_mat_path <- "2026Contributions/validation_plots/Sim_Theta.csv"
old_mat <- read_csv(old_mat_path, skip=3, col_names=FALSE, show_col_types=FALSE)
names(old_mat) <- paste0("depth_", depth_theta, "_", depth_layer)
old_mat <- old_mat %>%
  mutate(timestamp = seq.POSIXt(from=as.POSIXct("2019-01-01 00:00:00", tz="UTC"),
                                by="hour", length.out=nrow(old_mat))) %>%
  select(timestamp, old_matlab_smc60 = depth_60_5)
cat(sprintf("Old MATLAB baseline: %d rows\n", nrow(old_mat)))

# ── 3. Load NEW Octave (with soil properties) ───────────────────────────
oct_dir <- trimws(readLines("2026Contributions/latest_2yr_soilprops_octave_output_dir.txt"))
oct_path <- file.path(oct_dir, "Sim_Theta.csv")
new_oct <- read_csv(oct_path, skip=3, col_names=FALSE, show_col_types=FALSE)
names(new_oct) <- paste0("depth_", depth_theta, "_", depth_layer)
new_oct <- new_oct %>%
  mutate(timestamp = seq.POSIXt(from=as.POSIXct("2019-01-01 00:00:00", tz="UTC"),
                                by="hour", length.out=nrow(new_oct))) %>%
  select(timestamp, new_octave_smc60 = depth_60_5)
cat(sprintf("New Octave (soil props): %d rows\n", nrow(new_oct)))

# ── 4. Merge ────────────────────────────────────────────────────────────
df <- obs %>%
  inner_join(old_mat, by="timestamp") %>%
  inner_join(new_oct, by="timestamp") %>%
  filter(!is.na(obs_smc60), !is.na(old_matlab_smc60), !is.na(new_octave_smc60))
cat(sprintf("Merged: %d rows\n\n", nrow(df)))

# ── 5. Metrics ──────────────────────────────────────────────────────────
calc_metrics <- function(sim, obs, label) {
  r <- cor(sim, obs, use="complete.obs")
  bias <- mean(sim - obs, na.rm=TRUE)
  rmse <- sqrt(mean((sim - obs)^2, na.rm=TRUE))
  # KGE
  r_val <- cor(sim, obs, use="complete.obs")
  alpha <- sd(sim, na.rm=TRUE) / sd(obs, na.rm=TRUE)
  beta <- mean(sim, na.rm=TRUE) / mean(obs, na.rm=TRUE)
  kge <- 1 - sqrt((r_val - 1)^2 + (alpha - 1)^2 + (beta - 1)^2)
  cat(sprintf("  %-30s  r=%.4f  KGE=%.4f  RMSE=%.4f  Bias=%.4f\n", label, r, kge, rmse, bias))
  return(data.frame(label=label, r=r, KGE=kge, RMSE=rmse, Bias=bias))
}

cat("═══════════════════════════════════════════════════════════════\n")
cat("  PERFORMANCE METRICS (SMC at 60cm vs Observations)\n")
cat("═══════════════════════════════════════════════════════════════\n")
m1 <- calc_metrics(df$old_matlab_smc60, df$obs_smc60, "Old MATLAB (reference baseline)")
m2 <- calc_metrics(df$new_octave_smc60, df$obs_smc60, "New Octave (with soil props)")
m3 <- calc_metrics(df$new_octave_smc60, df$old_matlab_smc60, "Octave vs Old MATLAB (parity)")
cat("═══════════════════════════════════════════════════════════════\n\n")

# ── 6. Generate Plots ──────────────────────────────────────────────────
out_dir <- "2026Contributions/validation_plots/20260422_octave_soilprops_vs_oldmatlab"
dir.create(out_dir, showWarnings=FALSE, recursive=TRUE)

# Plot 1: Time series
png(file.path(out_dir, "01_SMC_60cm_3way_timeseries.png"), width=1400, height=600, res=120)
par(mar=c(4,4,3,1))
plot(df$timestamp, df$obs_smc60, type="l", col="black", lwd=1.5,
     ylim=range(c(df$obs_smc60, df$old_matlab_smc60, df$new_octave_smc60), na.rm=TRUE),
     xlab="Date", ylab="SMC [m³/m³]",
     main="SMC at 60cm: Obs vs Old MATLAB vs New Octave (with soil props)")
lines(df$timestamp, df$old_matlab_smc60, col="blue", lwd=1.2)
lines(df$timestamp, df$new_octave_smc60, col="red", lwd=1.2)
legend("topright", c("Observations", 
                      sprintf("Old MATLAB (r=%.3f)", m1$r),
                      sprintf("New Octave (r=%.3f)", m2$r)), 
       col=c("black","blue","red"), lwd=c(1.5,1.2,1.2), bty="n")
dev.off()

# Plot 2: Scatter - Old MATLAB vs Obs
png(file.path(out_dir, "02_scatter_oldMATLAB_vs_obs.png"), width=600, height=600, res=120)
plot(df$obs_smc60, df$old_matlab_smc60, pch=20, cex=0.3, col=rgb(0,0,1,0.3),
     xlab="Observed SMC", ylab="Simulated SMC (Old MATLAB)",
     main=sprintf("Old MATLAB vs Obs (r=%.3f, KGE=%.3f)", m1$r, m1$KGE))
abline(0, 1, col="red", lwd=2)
abline(lm(old_matlab_smc60 ~ obs_smc60, data=df), col="blue", lwd=1, lty=2)
dev.off()

# Plot 3: Scatter - New Octave vs Obs
png(file.path(out_dir, "03_scatter_newOctave_vs_obs.png"), width=600, height=600, res=120)
plot(df$obs_smc60, df$new_octave_smc60, pch=20, cex=0.3, col=rgb(1,0,0,0.3),
     xlab="Observed SMC", ylab="Simulated SMC (New Octave)",
     main=sprintf("New Octave vs Obs (r=%.3f, KGE=%.3f)", m2$r, m2$KGE))
abline(0, 1, col="red", lwd=2)
abline(lm(new_octave_smc60 ~ obs_smc60, data=df), col="blue", lwd=1, lty=2)
dev.off()

# Plot 4: Scatter - Octave vs Old MATLAB
png(file.path(out_dir, "04_scatter_octave_vs_oldmatlab.png"), width=600, height=600, res=120)
plot(df$old_matlab_smc60, df$new_octave_smc60, pch=20, cex=0.3, col=rgb(0.5,0,0.5,0.3),
     xlab="Old MATLAB SMC", ylab="New Octave SMC",
     main=sprintf("Engine Parity (r=%.3f, KGE=%.3f)", m3$r, m3$KGE))
abline(0, 1, col="red", lwd=2)
dev.off()

# Plot 5: Monthly mean comparison
df_monthly <- df %>%
  mutate(month = floor_date(timestamp, "month")) %>%
  group_by(month) %>%
  summarise(obs = mean(obs_smc60, na.rm=TRUE),
            old_matlab = mean(old_matlab_smc60, na.rm=TRUE),
            new_octave = mean(new_octave_smc60, na.rm=TRUE), .groups="drop")

png(file.path(out_dir, "05_monthly_mean_SMC.png"), width=1000, height=500, res=120)
par(mar=c(4,4,3,1))
plot(df_monthly$month, df_monthly$obs, type="b", pch=19, col="black", lwd=2,
     ylim=range(c(df_monthly$obs, df_monthly$old_matlab, df_monthly$new_octave), na.rm=TRUE),
     xlab="Month", ylab="Monthly Mean SMC [m³/m³]",
     main="Monthly Mean SMC at 60cm")
lines(df_monthly$month, df_monthly$old_matlab, type="b", pch=17, col="blue", lwd=1.5)
lines(df_monthly$month, df_monthly$new_octave, type="b", pch=15, col="red", lwd=1.5)
legend("topright", c("Observations", "Old MATLAB", "New Octave"),
       col=c("black","blue","red"), pch=c(19,17,15), lwd=c(2,1.5,1.5), bty="n")
dev.off()

# Save metrics
metrics_out <- rbind(m1, m2, m3)
write.csv(metrics_out, file.path(out_dir, "06_metrics_summary.csv"), row.names=FALSE)

cat(sprintf("✓ Plots saved to %s/\n", out_dir))
cat("  01_SMC_60cm_3way_timeseries.png\n")
cat("  02_scatter_oldMATLAB_vs_obs.png\n")
cat("  03_scatter_newOctave_vs_obs.png\n")
cat("  04_scatter_octave_vs_oldmatlab.png\n")
cat("  05_monthly_mean_SMC.png\n")
cat("  06_metrics_summary.csv\n")
