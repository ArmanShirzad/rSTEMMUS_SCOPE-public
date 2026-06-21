## ═══════════════════════════════════════════════════════════════════════════
## final_3way_validation.R
## ═══════════════════════════════════════════════════════════════════════════
## PURPOSE: DEFINITIVE 3-way validation — New MATLAB vs New Octave
##          (both with DE-STG soil properties) vs Observations at 60cm.
## DATE: 2026-04-22
## ═══════════════════════════════════════════════════════════════════════════

library(tidyverse)
library(lubridate)

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("  DEFINITIVE 3-Way Validation: New MATLAB vs New Octave vs Obs\n")
cat("  Both engines: identical code + DE-STG soil properties\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# ── Depth structure ──────────────────────────────────────────────────────
depth_theta <- c(1,2,3,5,7,9,11,13,15,17,19,21,23,25,27.5,30,32.5,35,40,45,50,55,60,
                 70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,
                 245,260,280,300,320,340,360,380,400,420,440,460,480,500)
depth_layer <- c(1,1,1,2,2,2,2,2,2,2,2,2,2,2,2.5,2.5,2.5,2.5,5,5,5,5,5,
                 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,15,15,
                 20,20,20,20,20,20,20,20,20,20,20,20)

# ── 1. Observations ─────────────────────────────────────────────────────
steg_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
obs <- steg_df %>%
  filter(timestamp >= as.POSIXct("2019-01-01", tz="UTC"),
         timestamp <= as.POSIXct("2020-12-31 23:00", tz="UTC")) %>%
  mutate(obs_smc60 = SMC_60cm / 100) %>%
  select(timestamp, obs_smc60)

# ── 2. New MATLAB (with soil props) ─────────────────────────────────────
mat_dir <- trimws(readLines("2026Contributions/latest_2yr_soilprops_matlab_output_dir.txt"))
mat_path <- file.path(mat_dir, "Sim_Theta.csv")
new_mat <- read_csv(mat_path, skip=3, col_names=FALSE, show_col_types=FALSE)
names(new_mat) <- paste0("depth_", depth_theta, "_", depth_layer)
new_mat <- new_mat %>%
  mutate(timestamp = seq.POSIXt(from=as.POSIXct("2019-01-01 00:00:00", tz="UTC"),
                                by="hour", length.out=nrow(new_mat))) %>%
  select(timestamp, new_matlab_smc60 = depth_60_5)
cat(sprintf("New MATLAB: %d rows\n", nrow(new_mat)))

# ── 3. New Octave (with soil props) ─────────────────────────────────────
oct_dir <- trimws(readLines("2026Contributions/latest_2yr_soilprops_octave_output_dir.txt"))
oct_path <- file.path(oct_dir, "Sim_Theta.csv")
new_oct <- read_csv(oct_path, skip=3, col_names=FALSE, show_col_types=FALSE)
names(new_oct) <- paste0("depth_", depth_theta, "_", depth_layer)
new_oct <- new_oct %>%
  mutate(timestamp = seq.POSIXt(from=as.POSIXct("2019-01-01 00:00:00", tz="UTC"),
                                by="hour", length.out=nrow(new_oct))) %>%
  select(timestamp, new_octave_smc60 = depth_60_5)
cat(sprintf("New Octave: %d rows\n", nrow(new_oct)))

# ── 4. Also load old MATLAB baseline for reference ──────────────────────
old_mat <- read_csv("2026Contributions/validation_plots/Sim_Theta.csv", skip=3, col_names=FALSE, show_col_types=FALSE)
names(old_mat) <- paste0("depth_", depth_theta, "_", depth_layer)
old_mat <- old_mat %>%
  mutate(timestamp = seq.POSIXt(from=as.POSIXct("2019-01-01 00:00:00", tz="UTC"),
                                by="hour", length.out=nrow(old_mat))) %>%
  select(timestamp, old_matlab_smc60 = depth_60_5)

# ── 5. Merge ────────────────────────────────────────────────────────────
df <- obs %>%
  inner_join(new_mat, by="timestamp") %>%
  inner_join(new_oct, by="timestamp") %>%
  inner_join(old_mat, by="timestamp") %>%
  filter(!is.na(obs_smc60))
cat(sprintf("Merged: %d rows\n\n", nrow(df)))

# ── 6. Metrics ──────────────────────────────────────────────────────────
calc_metrics <- function(sim, obs, label) {
  valid <- complete.cases(sim, obs)
  sim <- sim[valid]; obs <- obs[valid]
  r <- cor(sim, obs)
  bias <- mean(sim - obs)
  rmse <- sqrt(mean((sim - obs)^2))
  alpha <- sd(sim) / sd(obs)
  beta <- mean(sim) / mean(obs)
  kge <- 1 - sqrt((r - 1)^2 + (alpha - 1)^2 + (beta - 1)^2)
  cat(sprintf("  %-35s  r=%.4f  KGE=%.4f  RMSE=%.4f  Bias=%+.4f\n", label, r, kge, rmse, bias))
  return(data.frame(label=label, r=r, KGE=kge, RMSE=rmse, Bias=bias))
}

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PERFORMANCE METRICS — SMC at 60cm depth\n")
cat("═══════════════════════════════════════════════════════════════════\n")
m1 <- calc_metrics(df$old_matlab_smc60, df$obs_smc60,  "Old MATLAB (reference, no code fixes)")
m2 <- calc_metrics(df$new_matlab_smc60, df$obs_smc60,  "New MATLAB (with soil props + fixes)")
m3 <- calc_metrics(df$new_octave_smc60, df$obs_smc60,  "New Octave (with soil props + fixes)")
m4 <- calc_metrics(df$new_matlab_smc60, df$new_octave_smc60, "New MATLAB vs New Octave (parity)")
m5 <- calc_metrics(df$new_matlab_smc60, df$old_matlab_smc60, "New vs Old MATLAB (fix impact)")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# ── 7. Plots ────────────────────────────────────────────────────────────
out_dir <- "2026Contributions/validation_plots/20260422_DEFINITIVE_3way"
dir.create(out_dir, showWarnings=FALSE, recursive=TRUE)

# Plot 1: 4-way time series
png(file.path(out_dir, "01_SMC_60cm_4way.png"), width=1600, height=700, res=120)
par(mar=c(4,4,3,1))
plot(df$timestamp, df$obs_smc60, type="l", col="black", lwd=2,
     ylim=c(0, max(c(df$obs_smc60, df$new_matlab_smc60, df$new_octave_smc60, df$old_matlab_smc60), na.rm=TRUE)*1.1),
     xlab="Date", ylab="SMC [m³/m³]",
     main="SMC at 60cm: Observations vs All Simulations (with soil properties)")
lines(df$timestamp, df$old_matlab_smc60, col="gray50", lwd=1, lty=2)
lines(df$timestamp, df$new_matlab_smc60, col="blue", lwd=1.5)
lines(df$timestamp, df$new_octave_smc60, col="red", lwd=1.2)
legend("topright",
       c(sprintf("Observations"),
         sprintf("Old MATLAB (r=%.3f)", m1$r),
         sprintf("New MATLAB (r=%.3f)", m2$r),
         sprintf("New Octave (r=%.3f)", m3$r)),
       col=c("black","gray50","blue","red"), lwd=c(2,1,1.5,1.2), lty=c(1,2,1,1), bty="n")
dev.off()

# Plot 2: Scatter New MATLAB vs Obs
png(file.path(out_dir, "02_scatter_newMATLAB_vs_obs.png"), width=600, height=600, res=120)
plot(df$obs_smc60, df$new_matlab_smc60, pch=20, cex=0.3, col=rgb(0,0,1,0.3),
     xlab="Observed SMC", ylab="New MATLAB SMC",
     main=sprintf("New MATLAB vs Obs (r=%.3f, KGE=%.3f)", m2$r, m2$KGE))
abline(0, 1, col="red", lwd=2)
dev.off()

# Plot 3: Scatter New Octave vs Obs
png(file.path(out_dir, "03_scatter_newOctave_vs_obs.png"), width=600, height=600, res=120)
plot(df$obs_smc60, df$new_octave_smc60, pch=20, cex=0.3, col=rgb(1,0,0,0.3),
     xlab="Observed SMC", ylab="New Octave SMC",
     main=sprintf("New Octave vs Obs (r=%.3f, KGE=%.3f)", m3$r, m3$KGE))
abline(0, 1, col="red", lwd=2)
dev.off()

# Plot 4: Engine parity scatter
png(file.path(out_dir, "04_engine_parity_scatter.png"), width=600, height=600, res=120)
plot(df$new_matlab_smc60, df$new_octave_smc60, pch=20, cex=0.3, col=rgb(0.5,0,0.5,0.3),
     xlab="New MATLAB SMC", ylab="New Octave SMC",
     main=sprintf("Engine Parity: MATLAB vs Octave (r=%.3f)", m4$r))
abline(0, 1, col="red", lwd=2)
dev.off()

# Plot 5: Monthly means
df_monthly <- df %>%
  mutate(month = floor_date(timestamp, "month")) %>%
  group_by(month) %>%
  summarise(obs = mean(obs_smc60, na.rm=TRUE),
            old_mat = mean(old_matlab_smc60, na.rm=TRUE),
            new_mat = mean(new_matlab_smc60, na.rm=TRUE),
            new_oct = mean(new_octave_smc60, na.rm=TRUE), .groups="drop")

png(file.path(out_dir, "05_monthly_mean_SMC.png"), width=1100, height=500, res=120)
par(mar=c(4,4,3,1))
plot(df_monthly$month, df_monthly$obs, type="b", pch=19, col="black", lwd=2,
     ylim=range(c(df_monthly$obs, df_monthly$new_mat, df_monthly$new_oct, df_monthly$old_mat), na.rm=TRUE),
     xlab="Month", ylab="Monthly Mean SMC [m³/m³]",
     main="Monthly Mean SMC at 60cm — All Simulations")
lines(df_monthly$month, df_monthly$old_mat, type="b", pch=1, col="gray50", lwd=1, lty=2)
lines(df_monthly$month, df_monthly$new_mat, type="b", pch=17, col="blue", lwd=1.5)
lines(df_monthly$month, df_monthly$new_oct, type="b", pch=15, col="red", lwd=1.5)
legend("topright", c("Observations","Old MATLAB","New MATLAB","New Octave"),
       col=c("black","gray50","blue","red"), pch=c(19,1,17,15), lwd=c(2,1,1.5,1.5), lty=c(1,2,1,1), bty="n")
dev.off()

# Save summary
metrics <- rbind(m1, m2, m3, m4, m5)
write.csv(metrics, file.path(out_dir, "06_metrics_summary.csv"), row.names=FALSE)

cat(sprintf("✓ All plots saved to %s/\n", out_dir))
