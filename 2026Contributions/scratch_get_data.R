suppressPackageStartupMessages({library(dplyr); library(lubridate); library(zoo); library(readr)})
lambda <- 2.45e6
to_mmh <- function(LE) LE * 3600 / lambda
shift_vec <- function(x, k) {
  n <- length(x); if (k == 0) return(x)
  if (k > 0) c(rep(NA, k), x[1:(n - k)]) else c(x[(1 - k):n], rep(NA, -k))
}
roll_mean <- function(x, w) as.numeric(rollapply(x, w, mean, na.rm = TRUE, align = 'center', partial = TRUE))
obs <- readRDS('2026Contributions/EC_DWD_ROTH_clean.rds')
obs <- obs[obs$timestamp >= as.POSIXct('2019-01-01', tz='UTC') & obs$timestamp <= as.POSIXct('2019-12-31 23:00', tz='UTC'), ]
n <- nrow(obs)
sim_LE <- read_csv('rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_thetaR_soilprops_OCTAVE_2026May21_1552/fluxes.csv', skip = 2, col_names = FALSE, show_col_types = FALSE)[[6]][1:n]
LE_raw <- obs$LE; LE_raw[LE_raw < 0] <- 0
Rn <- obs$net.downward.radiative; H <- obs$H; G <- 0.1 * Rn
CF <- (Rn - G) / (LE_raw + H); CF[!is.finite(CF)] <- NA
CF <- pmin(pmax(CF, 0.5), 2.5)
ET_obs <- to_mmh(LE_raw * CF)
lai_n <- obs$LAI_FP / max(obs$LAI_FP, na.rm = TRUE)
cf_lai <- lai_n * (0.85 / mean(lai_n, na.rm = TRUE))
sim_ET <- to_mmh(sim_LE) * cf_lai
sim_shift <- shift_vec(sim_ET, -1)
sim_smooth <- roll_mean(sim_shift, 6)
obs_smooth <- roll_mean(ET_obs, 6)

df <- tibble(month = month(obs$timestamp, label = TRUE, abbr = TRUE), hour = hour(obs$timestamp), Observed = obs_smooth, STEMMUS_SCOPE = sim_smooth) |>
  group_by(month, hour) |> summarise(Obs = mean(Observed, na.rm=TRUE), Sim = mean(STEMMUS_SCOPE, na.rm=TRUE), .groups = 'drop') |>
  group_by(month) |> summarise(max_obs = max(Obs, na.rm=TRUE), max_sim = max(Sim, na.rm=TRUE))

print(df, n=12)
