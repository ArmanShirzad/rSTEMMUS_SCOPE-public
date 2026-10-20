## Multi-variable physical-consistency check across engines and code states.
## Answers Yijian Zeng (2026-10-11): check not only soil moisture, but also soil
## temperature, surface temperature, transpiration, evaporation, sensible heat,
## GPP and NEE. No new simulations: all variables are in the archived outputs.

OUT <- "2026Contributions/docs/multivar_consistency"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
R <- "rSTEMMUS_SCOPE/output"

runs <- list(
  MATLAB = file.path(R, "DE-STG_DE-STG_2yr_final_soilprops_MATLAB_2026Apr22_1927"),
  MCR    = file.path(R, "DE-STG_DE-STG_2yr_final_soilprops_MCR_2026May15_1602"),
  Octave = file.path(R, "DE-STG_DE-STG_2yr_thetaR_soilprops_OCTAVE_2026Aug16_1930"),  # canonical post-theta_r
  OctOLD = file.path(R, "DE-STG_GUARDAB_OLD_2yr_OCTAVE")                              # guards reverted
)

## Profile files carry 3 header rows whose first field is numeric, so the skip
## must be hard-coded rather than sniffed.
PROFILE <- c("Sim_Theta.csv", "Sim_Temp.csv", "Sim_hh.csv")
read_col <- function(dir, file, col) {
  p <- file.path(dir, file); if (!file.exists(p)) return(NULL)
  sk <- if (file %in% PROFILE) 3L else 2L
  d <- read.csv(p, skip = sk, header = FALSE)
  if (col > ncol(d)) return(NULL)
  suppressWarnings(as.numeric(d[[col]]))
}
depth_col <- function(dir, file, target) {
  p <- file.path(dir, file); if (!file.exists(p)) return(NA_integer_)
  dep <- suppressWarnings(as.numeric(strsplit(readLines(p, n = 1), ",")[[1]]))
  which.min(abs(dep - target))
}
getvar <- function(dir, v) {
  if (!is.null(v$depth)) {
    cc <- depth_col(dir, v$file, v$depth); if (is.na(cc)) return(NULL)
    read_col(dir, v$file, cc)
  } else read_col(dir, v$file, v$col)
}

fx <- function(col) list(file = "fluxes.csv", col = col)
vars <- list(
  `Net radiation Rn`        = fx(5),   `Latent heat LE`         = fx(6),
  `Sensible heat H`         = fx(7),   `Canopy latent heat lEc`  = fx(9),
  `Canopy sensible heat Hc` = fx(10),  `Assimilation A`          = fx(11),
  `Soil latent heat lEs`    = fx(13),  `Soil sensible heat Hs`   = fx(14),
  `Ground heat flux G`      = fx(15),  `Transpiration`           = fx(24),
  `Soil evaporation`        = fx(25),  `Total ET`                = fx(26),
  `GPP`                     = fx(27),  `NEE`                     = fx(28),
  `Canopy temperature`      = list(file = "surftemp.csv",  col = 7),
  `Soil surface temperature`= list(file = "surftemp.csv",  col = 8),
  `Outgoing longwave`       = list(file = "radiation.csv", col = 7)
)
for (d in c(5, 20, 60, 100)) {
  vars[[sprintf("Soil temperature %d cm", d)]] <- list(file = "Sim_Temp.csv",  depth = d)
  vars[[sprintf("Soil moisture %d cm",    d)]] <- list(file = "Sim_Theta.csv", depth = d)
}

pair <- function(a, b) {
  n <- min(length(a), length(b)); a <- a[seq_len(n)]; b <- b[seq_len(n)]
  ok <- is.finite(a) & is.finite(b); x <- a[ok]; y <- b[ok]
  if (length(x) < 100 || sd(x) == 0 || sd(y) == 0)
    return(c(n = length(x), r = NA, RMSE = NA, bias = NA))
  c(n = length(x), r = cor(x, y), RMSE = sqrt(mean((x - y)^2)), bias = mean(x - y))
}

cat("\n=== PART A - ENGINE-TO-ENGINE CONSISTENCY (no observations) ===\n")
A <- do.call(rbind, lapply(names(vars), function(nm) {
  v <- vars[[nm]]
  m <- getvar(runs$MATLAB, v); k <- getvar(runs$MCR, v); o <- getvar(runs$Octave, v)
  if (is.null(m) || is.null(o) || is.null(k)) return(NULL)
  rbind(data.frame(variable = nm, pairing = "MCR vs MATLAB",    t(pair(k, m))),
        data.frame(variable = nm, pairing = "Octave vs MATLAB", t(pair(o, m))),
        data.frame(variable = nm, pairing = "Octave vs MCR",    t(pair(o, k))))
}))
write.csv(A, file.path(OUT, "engine_consistency_by_variable.csv"), row.names = FALSE)
pa <- data.frame(variable = unique(A$variable))
for (pr in unique(A$pairing))
  pa[[pr]] <- round(A$r[A$pairing == pr][match(pa$variable, A$variable[A$pairing == pr])], 3)
print(pa, row.names = FALSE)

cat("\n=== PART B - GUARD ABLATION, OCTAVE (guards off vs guards on) ===\n")
B <- do.call(rbind, lapply(names(vars), function(nm) {
  v <- vars[[nm]]
  o <- getvar(runs$Octave, v); od <- getvar(runs$OctOLD, v)
  if (is.null(o) || is.null(od)) return(NULL)
  data.frame(variable = nm, t(pair(od, o)))
}))
B <- B[order(B$r), ]
write.csv(B, file.path(OUT, "guard_ablation_by_variable_octave.csv"), row.names = FALSE)
print(data.frame(variable = B$variable, r = round(B$r, 3),
                 RMSE = signif(B$RMSE, 3), bias = signif(B$bias, 3)), row.names = FALSE)
cat("\nwritten to", OUT, "\n")
