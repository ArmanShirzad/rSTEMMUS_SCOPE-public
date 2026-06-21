## 4-way Latent Heat (LE = ET energy flux) validation at DE-STG
##   Sim:  fluxes.csv column "lEtot" in W/m²
##   Obs:  EC_DWD_ROTH_clean.rds  $ LE.filled  (gap-filled eddy-cov LE in W/m²)
##
## Same 2yr Jan 2019 – Dec 2020 window, four engine builds, hourly rows.

suppressPackageStartupMessages({
  library(readr)
  library(lubridate)
})

# ---- Load observations ----
obs_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
obs_df <- obs_df[obs_df$timestamp >= as.POSIXct("2019-01-01 00:00", tz="UTC") &
                 obs_df$timestamp <= as.POSIXct("2020-12-31 23:00", tz="UTC"), ]
obs_le <- obs_df$LE.filled            # W/m², gap-filled EC observation
obs_le_clean <- obs_df$LE_clean       # W/m², quality-screened (more NAs)
ts <- obs_df$timestamp
cat(sprintf("Obs rows: %d, LE.filled non-NA: %d, LE_clean non-NA: %d\n",
            length(obs_le), sum(!is.na(obs_le)), sum(!is.na(obs_le_clean))))

# ---- Load simulations (lEtot column from fluxes.csv) ----
paths <- list(
  MATLAB      = "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_final_soilprops_MATLAB_2026Apr22_1927/fluxes.csv",
  MCR         = "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_final_soilprops_MCR_2026May15_1602/fluxes.csv",
  Octave_pre  = "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_final_soilprops_OCTAVE_2026Apr20_1646/fluxes.csv",
  Octave_post = "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_thetaR_soilprops_OCTAVE_2026May21_1552/fluxes.csv"
)

# fluxes.csv has 2 header rows (names, units), data row 3+. col 6 = lEtot.
load_le <- function(p) {
  if (!file.exists(p)) return(NULL)
  d <- read_csv(p, skip = 2, col_names = FALSE, show_col_types = FALSE)
  d[[6]]   # lEtot
}
sims <- lapply(paths, load_le)
for (nm in names(sims))
  cat(sprintf("%-12s sim rows: %s\n", nm, if (is.null(sims[[nm]])) "MISSING" else length(sims[[nm]])))

# Trim to common length
n <- min(c(length(obs_le), sapply(sims, function(x) if (is.null(x)) Inf else length(x))))
obs_le <- obs_le[seq_len(n)]
obs_le_clean <- obs_le_clean[seq_len(n)]
ts <- ts[seq_len(n)]
sims <- lapply(sims, function(x) if (is.null(x)) NULL else x[seq_len(n)])

# ---- Metrics ----
metric <- function(sim, obs, label) {
  ok <- is.finite(sim) & is.finite(obs)
  s <- sim[ok]; o <- obs[ok]
  if (length(s) < 10) return(data.frame(label=label, n=length(s), r=NA, KGE=NA, RMSE=NA, Bias=NA, MAE=NA))
  r <- cor(s, o)
  bias <- mean(s - o)
  rmse <- sqrt(mean((s - o)^2))
  mae <- mean(abs(s - o))
  alpha <- sd(s) / sd(o)
  beta  <- mean(s) / mean(o)
  kge <- 1 - sqrt((r - 1)^2 + (alpha - 1)^2 + (beta - 1)^2)
  data.frame(label=label, n=length(s), r=r, KGE=kge, RMSE=rmse, Bias=bias, MAE=mae)
}

cat("\n---------- LE vs LE.filled (gap-filled obs, n=17544) ----------\n")
results <- list()
for (nm in names(sims)) {
  if (is.null(sims[[nm]])) next
  results[[nm]] <- metric(sims[[nm]], obs_le, paste0(nm, " vs LE.filled"))
  with(results[[nm]], cat(sprintf("  %-26s n=%5d  r=%.4f  KGE=%.4f  RMSE=%5.1f  Bias=%+6.2f  MAE=%5.2f\n",
                                  label, n, r, KGE, RMSE, Bias, MAE)))
}

cat("\n---------- LE vs LE_clean (quality-screened obs, fewer rows) ----------\n")
for (nm in names(sims)) {
  if (is.null(sims[[nm]])) next
  m <- metric(sims[[nm]], obs_le_clean, paste0(nm, " vs LE_clean"))
  results[[paste0(nm, "_clean")]] <- m
  with(m, cat(sprintf("  %-26s n=%5d  r=%.4f  KGE=%.4f  RMSE=%5.1f  Bias=%+6.2f\n",
                      label, n, r, KGE, RMSE, Bias)))
}

out_dir <- "2026Contributions/validation_plots/20260522_et_4way"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
write.csv(do.call(rbind, results), file.path(out_dir, "metrics.csv"), row.names = FALSE)

# ---- Plots ----
plot_pair <- function(sim, obs, sim_label, obs_label, fname, lim = c(-50, 250)) {
  png(file.path(out_dir, fname), width = 1600, height = 700, res = 120)
  par(mar = c(4, 4, 3, 1))
  ok <- is.finite(sim) & is.finite(obs)
  m <- metric(sim, obs, "")
  plot(ts[ok], obs[ok], type = "l", col = "black", lwd = 0.6,
       ylim = lim, xlab = "", ylab = "LE [W/m²]",
       main = sprintf("%s vs %s — r=%.3f, KGE=%.3f, RMSE=%.1f W/m², bias=%+.1f",
                      sim_label, obs_label, m$r, m$KGE, m$RMSE, m$Bias))
  lines(ts[ok], sim[ok], col = "red", lwd = 0.5)
  legend("topright", c(obs_label, sim_label), col = c("black", "red"),
         lwd = c(0.6, 0.5), bty = "n")
  dev.off()
}

# 1-4: time series per engine vs LE.filled
plot_pair(sims$MATLAB,      obs_le, "MATLAB",        "LE.filled", "01_le_matlab_vs_obs.png")
plot_pair(sims$MCR,         obs_le, "MCR",           "LE.filled", "02_le_mcr_vs_obs.png")
plot_pair(sims$Octave_pre,  obs_le, "Octave pre-θr", "LE.filled", "03_le_octave_pre_vs_obs.png")
plot_pair(sims$Octave_post, obs_le, "Octave post-θr","LE.filled", "04_le_octave_post_vs_obs.png")

# 5: Monthly mean
months <- floor_date(ts, "month")
monthly_obs <- tapply(obs_le, months, mean, na.rm = TRUE)
monthly_sim_post <- tapply(sims$Octave_post, months, mean, na.rm = TRUE)
monthly_sim_mat  <- tapply(sims$MATLAB,      months, mean, na.rm = TRUE)
monthly_sim_mcr  <- tapply(sims$MCR,         months, mean, na.rm = TRUE)
mo <- as.POSIXct(names(monthly_obs), tz = "UTC")
png(file.path(out_dir, "05_le_monthly_4way.png"), width = 1300, height = 600, res = 120)
par(mar = c(4, 4, 3, 1))
plot(mo, monthly_obs, type = "b", pch = 19, col = "black", lwd = 2,
     ylim = range(c(monthly_obs, monthly_sim_post, monthly_sim_mat, monthly_sim_mcr), na.rm = TRUE),
     xlab = "Month", ylab = "Monthly mean LE [W/m²]",
     main = "Monthly mean LE — DE-STG 2019-2020")
lines(mo, monthly_sim_mat,  type = "b", pch = 17, col = "blue",  lwd = 1.5)
lines(mo, monthly_sim_mcr,  type = "b", pch = 15, col = "purple", lwd = 1.5)
lines(mo, monthly_sim_post, type = "b", pch = 18, col = "red",   lwd = 1.5)
legend("topright", c("Obs (LE.filled)", "MATLAB", "MCR", "Octave post-θr"),
       col = c("black","blue","purple","red"), pch = c(19,17,15,18), bty = "n")
dev.off()

# 6: scatter post-thetaR vs obs
png(file.path(out_dir, "06_scatter_octave_post_vs_obs.png"), width = 700, height = 700, res = 120)
ok <- is.finite(sims$Octave_post) & is.finite(obs_le)
m <- metric(sims$Octave_post, obs_le, "")
plot(obs_le[ok], sims$Octave_post[ok], pch = 20, cex = 0.3, col = rgb(1,0,0,0.2),
     xlim = c(-50, 300), ylim = c(-50, 300),
     xlab = "Observed LE.filled [W/m²]", ylab = "Sim lEtot [W/m²]",
     main = sprintf("Octave post-θr vs Obs (r=%.3f, KGE=%.3f)", m$r, m$KGE))
abline(0, 1, col = "black", lwd = 2)
dev.off()

cat(sprintf("\n%d plots + metrics.csv -> %s/\n", 6, out_dir))
