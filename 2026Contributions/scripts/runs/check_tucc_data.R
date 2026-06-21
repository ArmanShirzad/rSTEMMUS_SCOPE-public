## Quick check: does EC_DWD_TUCC_clean.rds have everything we need?
df <- readRDS("2026Contributions/EC_DWD_TUCC_clean.rds")

cat("=== TUCC DATA COMPLETENESS CHECK ===\n")
cat("Rows:", nrow(df), "  Cols:", ncol(df), "\n")
cat("Time:", as.character(min(df$timestamp)), "to", as.character(max(df$timestamp)), "\n\n")

# -- Met forcing --
cat("--- Met forcing ---\n")
met <- c("Rin","Rli","RH","ws","Ta","p","ea")
for (v in met) {
  ok <- v %in% names(df)
  if (ok) {
    nn <- sum(!is.na(df[[v]]))
    cat(sprintf("  [OK]  %-8s  non-NA=%5d / %d  (%.1f%%)\n", v, nn, nrow(df), 100*nn/nrow(df)))
  } else cat(sprintf("  [!!]  %-8s  MISSING\n", v))
}

# -- Precip --
cat("\n--- Precipitation ---\n")
for (v in c("prec_mm_EC","prec_mm")) {
  ok <- v %in% names(df)
  if (ok) {
    nn <- sum(!is.na(df[[v]]))
    cat(sprintf("  [OK]  %-15s  non-NA=%5d\n", v, nn))
  } else cat(sprintf("  [!!]  %-15s  MISSING\n", v))
}

# -- LAI --
cat("\n--- LAI ---\n")
for (v in c("LAI_FP","LAI_point","LAI_extent","LAI_buffer")) {
  ok <- v %in% names(df)
  if (ok) {
    nn <- sum(!is.na(df[[v]]))
    cat(sprintf("  [OK]  %-15s  non-NA=%5d  range=[%.3f, %.3f]\n", v, nn,
                min(df[[v]], na.rm=TRUE), max(df[[v]], na.rm=TRUE)))
  } else cat(sprintf("  [!!]  %-15s  MISSING\n", v))
}

# -- Soil temperature --
cat("\n--- Soil Temperature ---\n")
for (v in c("soil_temp10cm","soil_temp20cm","soil_temp30cm","soil_temp50cm")) {
  ok <- v %in% names(df)
  if (ok) {
    nn <- sum(!is.na(df[[v]]))
    cat(sprintf("  [OK]  %-20s  non-NA=%5d  range=[%.2f, %.2f]\n", v, nn,
                min(df[[v]], na.rm=TRUE), max(df[[v]], na.rm=TRUE)))
  } else cat(sprintf("  [!!]  %-20s  MISSING\n", v))
}

# -- Soil moisture --
cat("\n--- Soil Moisture ---\n")
for (v in c("SMC_10cm","SMC_20cm","SMC_30cm","SMC_60cm","SMC20","SMC40","SMC60")) {
  ok <- v %in% names(df)
  if (ok) {
    nn <- sum(!is.na(df[[v]]))
    cat(sprintf("  [OK]  %-15s  non-NA=%5d  range=[%.3f, %.3f]\n", v, nn,
                min(df[[v]], na.rm=TRUE), max(df[[v]], na.rm=TRUE)))
  } else cat(sprintf("  [!!]  %-15s  MISSING\n", v))
}

# -- Veg fractions --
cat("\n--- Vegetation / Urban fractions ---\n")
for (v in c("veg_fraction","impervious_fraction","veg_height","hc_1m")) {
  ok <- v %in% names(df)
  if (ok) {
    nn <- sum(!is.na(df[[v]]))
    cat(sprintf("  [OK]  %-25s  non-NA=%5d  range=[%.3f, %.3f]\n", v, nn,
                min(df[[v]], na.rm=TRUE), max(df[[v]], na.rm=TRUE)))
  } else cat(sprintf("  [!!]  %-25s  MISSING\n", v))
}

# -- Validation vars --
cat("\n--- Validation (ET / LE) ---\n")
for (v in c("LE","H","qc_LE","ET","LE_clean","LE.filled","ET_filled","ET_clean")) {
  ok <- v %in% names(df)
  if (ok) {
    nn <- sum(!is.na(df[[v]]))
    cat(sprintf("  [OK]  %-15s  non-NA=%5d\n", v, nn))
  } else cat(sprintf("  [!!]  %-15s  MISSING\n", v))
}

# -- Initial condition row --
cat("\n--- Initial condition (row 1) ---\n")
r1 <- df[1,]
for (v in c("Ta","p","RH","ea","Rin","Rli","ws","prec_mm_EC","LAI_FP")) {
  if (v %in% names(df)) cat(sprintf("  %-12s = %s\n", v, as.character(r1[[v]])))
}

cat("\n=== VERDICT ===\n")
needed <- c("Rin","Rli","RH","ws","Ta","p","ea","prec_mm_EC","LAI_FP")
all_present <- all(needed %in% names(df))
cat("All forcing columns present:", all_present, "\n")

soil_t <- c("soil_temp10cm","soil_temp20cm","soil_temp30cm","soil_temp50cm")
smc    <- c("SMC_10cm","SMC_20cm","SMC_30cm","SMC_60cm")
cat("Soil temp columns present:", all(soil_t %in% names(df)), "\n")
cat("SMC columns present (ROTH naming):", all(smc %in% names(df)), "\n")
cat("SMC columns present (TUCC naming SMC20/40/60):", all(c("SMC20","SMC40","SMC60") %in% names(df)), "\n")
cat("veg_fraction present:", "veg_fraction" %in% names(df), "\n")
