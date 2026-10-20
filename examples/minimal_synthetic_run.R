# ============================================================================
# Minimal synthetic smoke test for rSTEMMUS_SCOPE
# ============================================================================
#
# Runs the four steps of run_steps.md (new_run, input_constants,
# input_timeseries, run_inMATLAB) on one day of synthetic hourly forcing, so
# an installation can be checked end to end without any site observations.
#
# USAGE (from the repository root, after bootstrap.R):
#   Rscript examples/minimal_synthetic_run.R            # GNU Octave (free)
#   Rscript examples/minimal_synthetic_run.R matlab     # or "mcr"
# or from R / RStudio:
#   source("examples/minimal_synthetic_run.R")          # GNU Octave
#   Sys.setenv(STEMMUS_ENGINE = "matlab"); source("examples/minimal_synthetic_run.R")
#
# The forcing is idealised (clear-sky diurnal cycle, no rain), so the output
# is checked for being finite and physically plausible, not for skill.
#
# The synthetic forcing is also written to
#   rSTEMMUS_SCOPE/runs/SYN-01_synthetic_forcing.rds
# in the column schema of validate_weather_rds(), so it can be used to try
# 2026Contributions/scripts/runs/standardRoadmapLocation2.R as well.
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
execution_engine <- if (length(args)) args[1] else Sys.getenv("STEMMUS_ENGINE", "octave")

suppressMessages(devtools::load_all("."))
suppressPackageStartupMessages(library(lubridate))

patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
stopifnot("Run this from the repository root after `Rscript bootstrap.R`" =
            dir.exists(paste0(patch_path, "src/")) &&
            dir.exists(paste0(patch_path, "input/")))

site_name <- "SYN-01"
run_name  <- paste0("smoke_", toupper(execution_engine))


# ---- 1. Synthetic forcing: one summer day, hourly -------------------------

timestamp <- seq(as.POSIXct("2019-07-01 00:00", tz = "UTC"),
                 as.POSIXct("2019-07-01 23:00", tz = "UTC"), by = "hour")
hr  <- hour(timestamp)
day <- pmax(0, sin(pi * (hr - 5) / 14))          # daylight 05-19 UTC

Ta  <- 18 + 7 * sin(pi * (hr - 9) / 12)          # degC, min ~11, max ~25
RH  <- 75 - 25 * sin(pi * (hr - 9) / 12)         # %
es  <- 6.1078 * exp(17.27 * Ta / (Ta + 237.3))   # hPa
ea  <- es * RH / 100                             # hPa

forcing <- data.frame(
  timestamp     = timestamp,
  Rin           = 800 * day,                     # W m-2
  Rli           = 320 + 2 * (Ta - 18),           # W m-2
  p             = 1013,                          # hPa
  Ta            = Ta,
  RH            = RH,
  ea            = ea,
  ws            = 2.5,                           # m s-1
  prec_mm_EC    = 0,                             # mm per step
  LAI_FP        = 2.0,                           # m2 m-2
  co2_flux      = 0,                             # not used by the model
  soil_temp10cm = 17, soil_temp20cm = 16,        # degC
  soil_temp30cm = 15, soil_temp50cm = 14,
  SMC_10cm = 25, SMC_20cm = 26,                  # percent
  SMC_30cm = 27, SMC_60cm = 28
)

forcing_file <- paste0(patch_path, "runs/", site_name, "_synthetic_forcing.rds")
saveRDS(forcing, forcing_file)
v <- validate_weather_rds(forcing_file, verbose = TRUE)
stopifnot("synthetic forcing failed validate_weather_rds()" = all(v$ok))


# ---- 2. The four run_steps.md calls ---------------------------------------

n <- nrow(forcing)

new_run(patch       = patch_path,
        StartTime   = "2019-07-01T00:00",
        EndTime     = "2019-07-01T23:00",
        site_name   = site_name,
        run_name    = run_name,
        output_name = format(Sys.time(), "%Y%b%d_%H%M"))

# input_constants() takes soil temperature in Kelvin and soil water as a
# volumetric fraction (the README "unit traps").
input_constants(patch         = patch_path,
                site_name     = site_name,
                run_name      = run_name,
                LAT           = 52.46,
                LON           = 13.32,
                elevation     = 50,
                IGBP_veg_long = "Grassland",         # see info_IGBP_classes()
                hc            = 0.5,
                n_timestamps  = n,
                timestep_min  = 60,
                initial_soil_temperature = data.frame(
                  skt  = forcing$soil_temp10cm[1] + 273.15,
                  stl1 = forcing$soil_temp10cm[1] + 273.15,
                  stl2 = forcing$soil_temp20cm[1] + 273.15,
                  stl3 = forcing$soil_temp30cm[1] + 273.15,
                  stl4 = forcing$soil_temp50cm[1] + 273.15),
                initial_volumetric_soil_water = data.frame(
                  swvl1 = forcing$SMC_10cm[1] / 100,
                  swvl2 = forcing$SMC_20cm[1] / 100,
                  swvl3 = forcing$SMC_30cm[1] / 100,
                  swvl4 = forcing$SMC_60cm[1] / 100),
                startDOY = yday(timestamp[1]),
                endDOY   = yday(timestamp[n]),
                timezn   = 1)

input_timeseries(patch     = patch_path,
                 site_name = site_name,
                 run_name  = run_name,
                 t_file    = yday(timestamp) + hr / 24,
                 year_file = year(timestamp),
                 Rin_file  = forcing$Rin,
                 Rli_file  = forcing$Rli,
                 p_file    = forcing$p,
                 Ta_file   = forcing$Ta,
                 RH_file   = forcing$RH,
                 ea_file   = forcing$ea,
                 VPD_file  = es - ea,
                 u_file    = forcing$ws,
                 rain_file = forcing$prec_mm_EC / 36000,   # mm per hour -> cm s-1
                 LAI_file  = forcing$LAI_FP,
                 CO2_file  = rep(415, n))

t0 <- Sys.time()
run_inMATLAB(patch      = patch_path,
             site_name  = site_name,
             run_name   = run_name,
             exe_method = execution_engine)
wall <- as.numeric(difftime(Sys.time(), t0, units = "mins"))


# ---- 3. Check the output --------------------------------------------------

out_dirs <- list.dirs(paste0(patch_path, "output"), recursive = FALSE)
out_dirs <- out_dirs[startsWith(basename(out_dirs), paste0(site_name, "_", run_name, "_"))]
out_dir  <- out_dirs[which.max(file.mtime(out_dirs))]

theta_file  <- file.path(out_dir, "Sim_Theta.csv")
fluxes_file <- file.path(out_dir, "fluxes.csv")
if (!file.exists(theta_file) || !file.exists(fluxes_file)) {
  stop("No model output in ", out_dir, "\nSee ",
       paste0(patch_path, "runs/", site_name, "_", run_name, "/engine_stderr.log"))
}

theta  <- as.matrix(utils::read.csv(theta_file, header = FALSE, skip = 3))
fl_hdr <- utils::read.csv(fluxes_file, header = FALSE, nrows = 1)
fluxes <- utils::read.csv(fluxes_file, header = FALSE, skip = 2,
                          col.names = trimws(unlist(fl_hdr)), check.names = FALSE)

# The two ratio columns (per absorbed PAR) are 0/0 = NaN at night by design.
ratio_cols <- grepl("/", names(fluxes))
et_mm      <- sum(fluxes$lEtot) * 3600 / 2.45e6     # latent heat -> mm per day

checks <- c(
  "one Sim_Theta row per timestep" = nrow(theta) == n,
  "Sim_Theta finite"               = all(is.finite(theta)),
  "Sim_Theta within (0, 0.6]"      = all(theta > 0 & theta <= 0.6),
  "fluxes finite"                  = all(is.finite(as.matrix(fluxes[, !ratio_cols]))),
  "daytime net radiation > 0"      = max(fluxes$Rntot) > 0,
  "daily ET within (0, 10] mm"     = et_mm > 0 && et_mm <= 10
)

cat(sprintf("\n=== smoke test: %s on %s, %d steps, %.1f min ===\n",
            run_name, execution_engine, n, wall))
cat(sprintf("  output: %s\n", out_dir))
for (k in names(checks)) cat(sprintf("  [%s] %s\n", if (checks[[k]]) "OK  " else "FAIL", k))
cat(sprintf("  SMC 15 cm: %.3f -> %.3f m3/m3 | daily ET: %.2f mm\n",
            theta[1, 9], theta[n, 9], et_mm))
if (!all(checks)) stop("Smoke test FAILED")
cat("Smoke test PASSED\n")
