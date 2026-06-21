## 4-way SMC@60cm metrics — adds the post-thetaR Octave run as a 4th row.
## Replaces the pre-thetaR Octave Apr 20 baseline in the May 21 table.

suppressPackageStartupMessages({
  library(readr)
})

depth_theta <- c(1,2,3,5,7,9,11,13,15,17,19,21,23,25,27.5,30,32.5,35,40,45,50,55,60,
                 70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,
                 245,260,280,300,320,340,360,380,400,420,440,460,480,500)
col_60cm <- which(depth_theta == 60)

obs_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
obs_df <- obs_df[obs_df$timestamp >= as.POSIXct("2019-01-01", tz="UTC") &
                 obs_df$timestamp <= as.POSIXct("2020-12-31 23:00", tz="UTC"), ]
obs_60 <- obs_df$SMC_60cm / 100

paths <- list(
  MATLAB      = "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_final_soilprops_MATLAB_2026Apr22_1927/Sim_Theta.csv",
  MCR         = "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_final_soilprops_MCR_2026May15_1602/Sim_Theta.csv",
  Octave_pre  = "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_final_soilprops_OCTAVE_2026Apr20_1646/Sim_Theta.csv",
  Octave_post = "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_thetaR_soilprops_OCTAVE_2026May21_1552/Sim_Theta.csv"
)

sims <- lapply(paths, function(p) {
  if (!file.exists(p)) return(NULL)
  read_csv(p, skip = 3, col_names = FALSE, show_col_types = FALSE)[[col_60cm]]
})
for (nm in names(sims)) {
  cat(sprintf("%-12s rows: %s\n", nm, if (is.null(sims[[nm]])) "MISSING" else length(sims[[nm]])))
}
cat(sprintf("Obs          rows: %d\n\n", length(obs_60)))

n <- min(c(length(obs_60), sapply(sims, function(x) if (is.null(x)) Inf else length(x))))
obs_60 <- obs_60[seq_len(n)]
sims <- lapply(sims, function(x) if (is.null(x)) NULL else x[seq_len(n)])

# Detect remaining dry-collapse counts (theta_r guard sanity check)
for (nm in c("Octave_pre", "Octave_post")) {
  s <- sims[[nm]]
  if (!is.null(s)) {
    zero_steps <- sum(s == 0, na.rm = TRUE)
    near_zero  <- sum(s < 0.02, na.rm = TRUE)
    cat(sprintf("%-12s SMC=0 steps: %d, SMC<0.02 steps: %d\n", nm, zero_steps, near_zero))
  }
}
cat("\n")

metric <- function(sim, obs, label) {
  ok <- is.finite(sim) & is.finite(obs)
  s <- sim[ok]; o <- obs[ok]
  if (length(s) < 10) return(data.frame(label=label, n=length(s), r=NA, KGE=NA, RMSE=NA, Bias=NA))
  r <- cor(s, o)
  bias <- mean(s - o)
  rmse <- sqrt(mean((s - o)^2))
  alpha <- sd(s) / sd(o)
  beta  <- mean(s) / mean(o)
  kge <- 1 - sqrt((r - 1)^2 + (alpha - 1)^2 + (beta - 1)^2)
  data.frame(label=label, n=length(s), r=r, KGE=kge, RMSE=rmse, Bias=bias)
}

cat("---------- SMC @ 60cm vs Observations ----------\n")
results <- list()
for (nm in names(sims)) {
  if (is.null(sims[[nm]])) next
  results[[nm]] <- metric(sims[[nm]], obs_60, paste0(nm, " vs Obs"))
  with(results[[nm]], cat(sprintf("  %-20s  r=%.4f  KGE=%.4f  RMSE=%.4f  Bias=%+.4f\n",
                                  label, r, KGE, RMSE, Bias)))
}

cat("\n---------- Engine-to-engine parity ----------\n")
pairs <- list(c("Octave_post","MATLAB"), c("Octave_post","MCR"),
              c("Octave_post","Octave_pre"))
for (p in pairs) {
  a <- sims[[p[1]]]; b <- sims[[p[2]]]
  if (is.null(a) || is.null(b)) next
  m <- metric(a, b, sprintf("%s vs %s", p[1], p[2]))
  results[[paste(p, collapse="_")]] <- m
  with(m, cat(sprintf("  %-30s  r=%.4f  KGE=%.4f  RMSE=%.4f  Bias=%+.4f\n",
                      label, r, KGE, RMSE, Bias)))
}

out_csv <- "2026Contributions/validation_plots/20260522_octave_thetaR/metrics.csv"
dir.create(dirname(out_csv), showWarnings=FALSE, recursive=TRUE)
write.csv(do.call(rbind, results), out_csv, row.names=FALSE)
cat(sprintf("\nWrote %s\n", out_csv))
