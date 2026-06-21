#' Validate a site weather observation .rds file before launching a simulation
#'
#' STEMMUS_SCOPE expects forcing data in a specific column schema and unit
#' convention. Mistakes in either are silent failures — a run produces
#' Sim_Theta.csv with nonsense values. This function inspects an .rds and
#' returns a tidy table flagging schema or unit issues.
#'
#' @param path  Path to the .rds file containing a data frame of site
#'   observations. Must have one row per timestep.
#' @param verbose  If TRUE, print a one-line-per-check summary in addition
#'   to returning the data frame. Default TRUE.
#'
#' @return A `data.frame` with columns `check`, `ok`, `detail`.
#'
#' @details
#' Required columns (case sensitive):
#'   timestamp, Rin, Rli, p, Ta, RH, ea, ws, prec_mm_EC, LAI_FP, co2_flux,
#'   soil_temp10cm, soil_temp20cm, soil_temp30cm, soil_temp50cm,
#'   SMC_10cm, SMC_20cm, SMC_30cm, SMC_60cm
#'
#' Expected unit ranges (rough sanity bounds, not strict physics):
#'   Ta in [-50, 60] degC, RH in [0, 100] %, ws >= 0 m/s,
#'   SMC_* in [0, 100] (percent, divided by 100 inside input_constants),
#'   soil_temp_* in [-50, 60] degC (converted to Kelvin inside input_constants).
#'
#' @examples
#' \dontrun{
#'   validate_weather_rds("2026Contributions/EC_DWD_ROTH_clean.rds")
#' }
#' @export
validate_weather_rds <- function(path, verbose = TRUE) {

  rows <- list()
  add <- function(check, ok, detail) {
    rows[[length(rows) + 1L]] <<- data.frame(
      check  = check,
      ok     = ok,
      detail = as.character(detail),
      stringsAsFactors = FALSE
    )
  }

  if (!file.exists(path)) {
    add("file exists", FALSE, paste("not found:", path))
    out <- do.call(rbind, rows); rownames(out) <- NULL
    if (verbose) print(out)
    return(invisible(out))
  }
  add("file exists", TRUE, path)

  df <- tryCatch(readRDS(path), error = function(e) NULL)
  if (is.null(df)) {
    add("readRDS succeeds", FALSE, "file is not a valid .rds")
    out <- do.call(rbind, rows); rownames(out) <- NULL
    if (verbose) print(out)
    return(invisible(out))
  }
  add("readRDS succeeds", TRUE, sprintf("%d rows x %d cols", nrow(df), ncol(df)))

  required <- c("timestamp", "Rin", "Rli", "p", "Ta", "RH", "ea", "ws",
                "prec_mm_EC", "LAI_FP", "co2_flux",
                "soil_temp10cm", "soil_temp20cm", "soil_temp30cm", "soil_temp50cm",
                "SMC_10cm", "SMC_20cm", "SMC_30cm", "SMC_60cm")
  missing_cols <- setdiff(required, names(df))
  add(sprintf("required columns (%d)", length(required)),
      length(missing_cols) == 0,
      if (length(missing_cols)) sprintf("missing: %s", paste(missing_cols, collapse = ", "))
      else "all present")

  if ("timestamp" %in% names(df)) {
    add("timestamp is POSIXct", inherits(df$timestamp, "POSIXct"),
        class(df$timestamp)[1])
  }

  rng_check <- function(col, lo, hi, label) {
    if (!col %in% names(df)) return(invisible())
    v <- df[[col]]
    add(sprintf("%s in [%g, %g]", label, lo, hi),
        all(v >= lo & v <= hi, na.rm = TRUE),
        sprintf("min=%.2f max=%.2f", min(v, na.rm = TRUE), max(v, na.rm = TRUE)))
  }
  rng_check("Ta",  -50, 60,  "Ta (degC)")
  rng_check("RH",   0,  100, "RH (%)")
  rng_check("ws",   0,  100, "ws (m/s)")
  rng_check("Rin", -10, 1500, "Rin (W/m2)")
  rng_check("p",   500, 1200, "p (hPa)")

  # SMC unit detection: expecting percent (0-100), not fraction
  for (col in grep("^SMC_", names(df), value = TRUE)) {
    v <- df[[col]]
    rng <- range(v, na.rm = TRUE)
    looks_percent <- rng[2] > 1.5
    add(sprintf("%s in percent units (0-100)", col),
        looks_percent && rng[2] <= 100 && rng[1] >= 0,
        sprintf("range %.2f - %.2f %s", rng[1], rng[2],
                if (!looks_percent) "(looks like fraction — multiply by 100?)" else ""))
  }

  # soil_temp_*: expecting Celsius (will be converted to Kelvin in roadmap)
  for (col in grep("^soil_temp", names(df), value = TRUE)) {
    v <- df[[col]]
    rng <- range(v, na.rm = TRUE)
    looks_celsius <- rng[1] > -50 && rng[2] < 60
    add(sprintf("%s looks like Celsius", col),
        looks_celsius,
        sprintf("range %.2f - %.2f %s", rng[1], rng[2],
                if (!looks_celsius) "(if Kelvin, drop the +273.15 conversion in roadmap Section 4)" else ""))
  }

  # NA fractions on critical columns
  for (col in c("Rin", "Ta", "RH", "SMC_60cm")) {
    if (col %in% names(df)) {
      na_frac <- sum(is.na(df[[col]])) / nrow(df)
      add(sprintf("%s NA fraction < 10%%", col),
          na_frac < 0.10,
          sprintf("%.1f%% NA", 100 * na_frac))
    }
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL

  if (verbose) {
    cat("\n=== weather .rds validation ===\n")
    for (i in seq_len(nrow(out))) {
      mark <- if (out$ok[i]) "OK  " else "FAIL"
      cat(sprintf("  [%s] %-40s %s\n", mark, out$check[i], out$detail[i]))
    }
    n_fail <- sum(!out$ok)
    if (n_fail == 0) cat("\nAll checks pass — safe to launch simulation.\n")
    else cat(sprintf("\n%d check%s failed — fix before launching.\n", n_fail, if (n_fail==1) "" else "s"))
  }

  invisible(out)
}
