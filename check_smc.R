obs <- readRDS('2026Contributions/EC_DWD_ROTH_clean.rds')
smc_cols <- grep('SMC', colnames(obs), value=TRUE)
cat('SMC columns available:\n')
print(smc_cols)
cat('\n\nData availability (% non-NA):\n')
for(col in smc_cols) {
  n_valid <- sum(!is.na(obs[[col]]))
  pct_valid <- round(100 * n_valid / nrow(obs), 1)
  cat(sprintf('%-15s: %5d valid values (%.1f%%)\n', col, n_valid, pct_valid))
}
