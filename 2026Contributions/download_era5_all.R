## ═══════════════════════════════════════════════════════════════════════════
## download_era5_all.R — Download all 4 soil temp layers for 2019-2020
## ═══════════════════════════════════════════════════════════════════════════
## Downloads 1 variable × 3 months at a time to stay within CDS limits.
## Output: 2026Contributions/era5/ folder with individual .nc files
## ═══════════════════════════════════════════════════════════════════════════

library(ecmwfr)

# CDS API key. Set the CDSAPI_KEY environment variable before running:
#   Sys.setenv(CDSAPI_KEY = "your-key-from-cds.climate.copernicus.eu")
# or in ~/.Renviron:  CDSAPI_KEY=your-key
cds_key <- Sys.getenv("CDSAPI_KEY", unset = NA)
if (is.na(cds_key) || nchar(cds_key) == 0) {
  stop("CDS API key not found. Get one at https://cds.climate.copernicus.eu",
       "/api-how-to and set the CDSAPI_KEY environment variable.")
}
wf_set_key(key = cds_key)

out_dir <- "2026Contributions/era5"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

variables <- c(
  "soil_temperature_level_1",
  "soil_temperature_level_2",
  "soil_temperature_level_3",
  "soil_temperature_level_4"
)

var_short <- c("stl1", "stl2", "stl3", "stl4")

years <- c("2019", "2020")

# 3-month chunks (matching the reference approach)
quarter_months <- list(
  Q1 = c("01", "02", "03"),
  Q2 = c("04", "05", "06"),
  Q3 = c("07", "08", "09"),
  Q4 = c("10", "11", "12")
)

days_all <- sprintf("%02d", 1:31)
times_all <- sprintf("%02d:00", 0:23)
area_box <- c(52.56, 13.28, 52.46, 13.38)

total <- length(variables) * length(years) * length(quarter_months)
counter <- 0

for (vi in seq_along(variables)) {
  for (yr in years) {
    for (qi in seq_along(quarter_months)) {
      counter <- counter + 1
      qname <- names(quarter_months)[qi]
      months <- quarter_months[[qi]]
      filename <- sprintf("era5land_%s_%s_%s.nc", var_short[vi], yr, qname)
      filepath <- file.path(out_dir, filename)

      # Skip if already downloaded
      if (file.exists(filepath) && file.size(filepath) > 1000) {
        cat(sprintf("[%d/%d] SKIP (already exists): %s\n", counter, total, filename))
        next
      }

      cat(sprintf("[%d/%d] Downloading: %s ...\n", counter, total, filename))

      request <- list(
        dataset_short_name = "reanalysis-era5-land",
        product_type = "reanalysis",
        variable = variables[vi],
        year = yr,
        month = months,
        day = days_all,
        time = times_all,
        area = area_box,
        data_format = "netcdf",
        download_format = "unarchived",
        target = filename
      )

      tryCatch({
        wf_request(request = request, transfer = TRUE, path = out_dir)
        cat(sprintf("[%d/%d] SUCCESS: %s\n", counter, total, filename))
      }, error = function(e) {
        cat(sprintf("[%d/%d] FAILED: %s — %s\n", counter, total, filename, e$message))
      })

      Sys.sleep(5)  # brief pause between requests
    }
  }
}

cat("\n═══════════════════════════════════════════════════\n")
cat("All downloads completed! Check era5/ folder.\n")
cat(sprintf("Files: %s\n", paste(list.files(out_dir), collapse = ", ")))
cat("═══════════════════════════════════════════════════\n")
