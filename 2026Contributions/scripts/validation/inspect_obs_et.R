d <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
cat("nrow:", nrow(d), "\n\n")
cat("All columns (sorted):\n")
print(sort(names(d)))

cat("\nGrep for ET / LE / latent / sensible / evap / trans / Rn / G heat columns:\n")
pat <- "ET|LE|^H$|^H_|latent|sens|evap|trans|Hflux|lEtot|Rn|G_flux|^G$|EC$"
print(grep(pat, names(d), ignore.case=TRUE, value=TRUE))

cat("\nSummary of likely energy-flux candidates:\n")
candidates <- grep("LE|^H$|H_|ET|Evap|^Rn|Hflux|^G_|^G$", names(d), value=TRUE)
for (c in candidates) {
  v <- d[[c]]
  if (is.numeric(v)) {
    cat(sprintf("  %-20s n_nonNA=%6d min=%8.2f mean=%8.2f max=%8.2f units?\n",
                c, sum(!is.na(v)), min(v,na.rm=T), mean(v,na.rm=T), max(v,na.rm=T)))
  }
}
