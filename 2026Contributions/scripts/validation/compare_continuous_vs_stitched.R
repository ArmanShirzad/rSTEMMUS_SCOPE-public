# Compare continuous 2yr Octave output vs stitched 2yr Octave output
# to determine if the divergence was caused by stitching or is inherent to the engine

cat("Loading continuous Sim_Theta.csv...\n")
continuous <- read.csv("rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_continuous_final_2026Apr11_1836/Sim_Theta.csv", header=FALSE)
cat("Loading stitched Sim_Theta.csv...\n")
stitched <- read.csv("2026Contributions/stitched_2yr_output/Sim_Theta.csv", header=FALSE)

depths_c <- as.numeric(continuous[1,])
depths_s <- as.numeric(stitched[1,])
idx_c <- which.min(abs(depths_c - 60))
idx_s <- which.min(abs(depths_s - 60))

smc_c <- as.numeric(continuous[-(1:3), idx_c])
smc_s <- as.numeric(stitched[-(1:3), idx_s])

cat(sprintf("Continuous: %d timesteps, 60cm col=%d (depth=%.0f)\n", length(smc_c), idx_c, depths_c[idx_c]))
cat(sprintf("Stitched:   %d timesteps, 60cm col=%d (depth=%.0f)\n", length(smc_s), idx_s, depths_s[idx_s]))

# Part 1 region (first 4345 ts — same code ran both)
n <- min(length(smc_c), length(smc_s), 4345)
diff_part1 <- smc_c[1:n] - smc_s[1:n]
cat(sprintf("\n--- Part 1 region (first %d ts) ---\n", n))
cat(sprintf("Max abs diff: %.6e\n", max(abs(diff_part1))))
cat(sprintf("Mean abs diff: %.6e\n", mean(abs(diff_part1))))

# Transition zone
cat(sprintf("\n--- Transition zone (ts 4340-4350) ---\n"))
cat("Continuous: "); cat(paste(round(smc_c[4340:4350], 6), collapse=", ")); cat("\n")
cat("Stitched:   "); cat(paste(round(smc_s[4340:4350], 6), collapse=", ")); cat("\n")
cat("Diff:       "); cat(paste(round(smc_c[4340:4350] - smc_s[4340:4350], 6), collapse=", ")); cat("\n")

# Part 2 region
nn <- min(length(smc_c), length(smc_s))
diff_part2 <- smc_c[4346:nn] - smc_s[4346:nn]
cat(sprintf("\n--- Part 2 region (ts 4346 to %d) ---\n", nn))
cat(sprintf("Max abs diff: %.6e\n", max(abs(diff_part2))))
cat(sprintf("Mean abs diff: %.6e\n", mean(abs(diff_part2))))
cat(sprintf("RMSE: %.6e\n", sqrt(mean(diff_part2^2))))

# Overall
cat(sprintf("\n--- Overall ---\n"))
cat(sprintf("Continuous mean SMC 60cm: %.6f\n", mean(smc_c)))
cat(sprintf("Stitched mean SMC 60cm:   %.6f\n", mean(smc_s)))
overall_rmse <- sqrt(mean((smc_c[1:nn] - smc_s[1:nn])^2))
cat(sprintf("Overall RMSE (continuous vs stitched): %.6e\n", overall_rmse))

# Now compare continuous Octave vs old MATLAB at specific intervals
cat("\n\n=== CONTINUOUS OCTAVE vs OLD MATLAB BASELINE ===\n")
matlab_raw <- read.csv("2026Contributions/validation_plots/Sim_Theta.csv", header=FALSE)
depths_m <- as.numeric(matlab_raw[1,])
idx_m <- which.min(abs(depths_m - 60))
smc_m <- as.numeric(matlab_raw[-(1:3), idx_m])
cat(sprintf("MATLAB: %d timesteps, 60cm col=%d (depth=%.0f)\n", length(smc_m), idx_m, depths_m[idx_m]))

nm <- min(length(smc_c), length(smc_m))

# First month
cat(sprintf("\n--- First month (ts 1-720) ---\n"))
d1 <- smc_c[1:720] - smc_m[1:720]
cat(sprintf("RMSE: %.6f, Mean diff: %.6f\n", sqrt(mean(d1^2)), mean(d1)))

# Month 6-7 (ts 4000-5000)
cat(sprintf("\n--- Months 6-7 (ts 4000-5000) ---\n"))
d2 <- smc_c[4000:5000] - smc_m[4000:5000]
cat(sprintf("RMSE: %.6f, Mean diff: %.6f\n", sqrt(mean(d2^2)), mean(d2)))

# Month 12 (ts 8000-8760)
cat(sprintf("\n--- Month 12 (ts 8000-8760) ---\n"))
d3 <- smc_c[8000:8760] - smc_m[8000:8760]
cat(sprintf("RMSE: %.6f, Mean diff: %.6f\n", sqrt(mean(d3^2)), mean(d3)))

# Year 2 (ts 13000-14000)
cat(sprintf("\n--- Year 2 mid (ts 13000-14000) ---\n"))
d4 <- smc_c[13000:14000] - smc_m[13000:14000]
cat(sprintf("RMSE: %.6f, Mean diff: %.6f\n", sqrt(mean(d4^2)), mean(d4)))

# Last month
cat(sprintf("\n--- Last month (ts %d-%d) ---\n", nm-720, nm))
d5 <- smc_c[(nm-720):nm] - smc_m[(nm-720):nm]
cat(sprintf("RMSE: %.6f, Mean diff: %.6f\n", sqrt(mean(d5^2)), mean(d5)))

cat(sprintf("\n--- Overall Octave vs MATLAB ---\n"))
cat(sprintf("Overall RMSE: %.6f\n", sqrt(mean((smc_c[1:nm] - smc_m[1:nm])^2))))
cat(sprintf("Overall bias (Oct-Mat): %.6f\n", mean(smc_c[1:nm] - smc_m[1:nm])))
cat(sprintf("Correlation: %.4f\n", cor(smc_c[1:nm], smc_m[1:nm])))

# Is the divergence growing over time?
cat(sprintf("\n--- Divergence trend over time ---\n"))
chunks <- seq(1, nm, by=2000)
for (i in 1:(length(chunks)-1)) {
  s <- chunks[i]; e <- min(chunks[i+1]-1, nm)
  d <- smc_c[s:e] - smc_m[s:e]
  cat(sprintf("ts %5d-%5d: RMSE=%.4f  bias=%.4f\n", s, e, sqrt(mean(d^2)), mean(d)))
}
