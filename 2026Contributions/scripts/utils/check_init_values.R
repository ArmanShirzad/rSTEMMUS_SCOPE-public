obs <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
init <- obs[1,]

cat("=== Observation Initial Values (t=0, Jan 1 2019) ===\n")
cat(sprintf("SMC_5cm:   %.2f%%  -> /100 = %.4f m3/m3\n", init$SMC_5cm, init$SMC_5cm/100))
cat(sprintf("SMC_10cm:  %.2f%%  -> /100 = %.4f m3/m3\n", init$SMC_10cm, init$SMC_10cm/100))
cat(sprintf("SMC_20cm:  %.2f%%  -> /100 = %.4f m3/m3\n", init$SMC_20cm, init$SMC_20cm/100))
cat(sprintf("SMC_30cm:  %.2f%%  -> /100 = %.4f m3/m3\n", init$SMC_30cm, init$SMC_30cm/100))
cat(sprintf("SMC_60cm:  %.2f%%  -> /100 = %.4f m3/m3\n", init$SMC_60cm, init$SMC_60cm/100))

cat("\n=== What roadmapSeglitz.R passes to input_constants() ===\n")
cat(sprintf("swvl1 = SMC_10cm/100 = %.2f/100 = %.4f\n", init$SMC_10cm, init$SMC_10cm/100))
cat(sprintf("swvl2 = SMC_20cm/100 = %.2f/100 = %.4f\n", init$SMC_20cm, init$SMC_20cm/100))
cat(sprintf("swvl3 = SMC_30cm/100 = %.2f/100 = %.4f\n", init$SMC_30cm, init$SMC_30cm/100))
cat(sprintf("swvl4 = SMC_60cm/100 = %.2f/100 = %.4f\n", init$SMC_60cm, init$SMC_60cm/100))

cat("\n=== Layer mapping in input_constants.R ===\n")
cat(sprintf("InitX0 (shallowest) = swvl1 = %.4f\n", init$SMC_10cm/100))
cat(sprintf("InitX1              = swvl1 = %.4f\n", init$SMC_10cm/100))
cat(sprintf("InitX2              = swvl2 = %.4f\n", init$SMC_20cm/100))
cat(sprintf("InitX3              = swvl3 = %.4f\n", init$SMC_30cm/100))
cat(sprintf("InitX4              = swvl4 = %.4f\n", init$SMC_60cm/100))
cat(sprintf("InitX5              = swvl4 = %.4f\n", init$SMC_60cm/100))
cat(sprintf("InitX6              = swvl4 = %.4f\n", init$SMC_60cm/100))
cat(sprintf("BtmX   (deepest)    = swvl4 = %.4f\n", init$SMC_60cm/100))

cat("\n=== Temperature mapping (input_constants.R subtracts 273.15) ===\n")
cat(sprintf("roadmapSeglitz passes skt=%.2f, stl1=%.2f, stl2=%.2f, stl3=%.2f, stl4=%.2f\n",
            init$soil_temp10cm, init$soil_temp10cm, init$soil_temp20cm, init$soil_temp30cm, init$soil_temp50cm))
cat(sprintf("input_constants.R does: skt - 273.15 = %.2f - 273.15 = %.2f\n",
            init$soil_temp10cm, init$soil_temp10cm - 273.15))
cat("\n⚠️ If temperatures are already in Celsius (6.3C), then subtracting 273.15 gives -266.85C!\n")
cat("⚠️ The function expects Kelvin but roadmapSeglitz gives Celsius!\n")
