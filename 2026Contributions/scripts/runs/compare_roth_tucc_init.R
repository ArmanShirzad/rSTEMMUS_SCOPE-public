## Compare ROTH vs TUCC initial conditions
roth <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
tucc <- readRDS("2026Contributions/EC_DWD_TUCC_clean.rds")

cat("=== ROTH initial condition (row 1) ===\n")
r1 <- roth[1,]
cat("  soil_temp10cm =", r1$soil_temp10cm, "\n")
cat("  soil_temp20cm =", r1$soil_temp20cm, "\n")
cat("  soil_temp30cm =", r1$soil_temp30cm, "\n")
cat("  soil_temp50cm =", r1$soil_temp50cm, "\n")
cat("  SMC_10cm =", r1$SMC_10cm, "\n")
cat("  SMC_20cm =", r1$SMC_20cm, "\n")
cat("  SMC_30cm =", r1$SMC_30cm, "\n")
cat("  SMC_60cm =", r1$SMC_60cm, "\n")
cat("  Ta =", r1$Ta, "\n")

cat("\n=== TUCC initial condition (row 1) ===\n")
t1 <- tucc[1,]
cat("  Ta =", t1$Ta, "\n")
cat("  SMC20 =", t1$SMC20, "\n")
cat("  SMC40 =", t1$SMC40, "\n")
cat("  SMC60 =", t1$SMC60, "\n")
cat("  NOTE: soil_temp columns are MISSING\n")
cat("  NOTE: SMC columns have different naming and units\n")

cat("\n=== SMC unit comparison ===\n")
cat("  ROTH SMC_10cm first row:", r1$SMC_10cm, " (this is divided by 100 before use)\n")
cat("  TUCC SMC20 first row:", t1$SMC20, "\n")
cat("  TUCC SMC20 range:", range(tucc$SMC20), "\n")
cat("  If TUCC SMC20 is in percent => /100 gives volumetric fraction\n")
cat("  If TUCC SMC20 is already volumetric (0-1) => just use directly\n")

cat("\n=== SITE INFO ===\n")
cat("  ROTH/Steglitz: lat=52.456, lon=13.323, elev=50m\n")
cat("  TUCC: lat=52.455, lon=13.297 (TU Berlin campus), elev=36m\n")
