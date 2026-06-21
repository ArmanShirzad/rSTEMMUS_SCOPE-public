#' Verify that the local machine has everything required to run STEMMUS_SCOPE
#'
#' Returns a tidy data frame summarising R version, R packages, model
#' source/input directories, and available execution engines (Octave,
#' MATLAB, MCR binary). The `ok` column is the at-a-glance pass/fail.
#'
#' @param patch  Path to the rSTEMMUS_SCOPE root (the directory that
#'   contains `src/`, `input/`, `runs/`, `output/`). Defaults to
#'   `getwd()/rSTEMMUS_SCOPE/`.
#' @param verbose  If TRUE, prints a formatted summary in addition to
#'   returning the data frame. Default TRUE.
#'
#' @return A `data.frame` with one row per check: `component`, `ok`,
#'   `detail`, `fix_if_missing`.
#'
#' @examples
#' \dontrun{
#'   verify_install()
#' }
#' @export
verify_install <- function(patch = paste0(getwd(), "/rSTEMMUS_SCOPE/"),
                           verbose = TRUE) {

  rows <- list()
  add <- function(key, component, ok, detail, fix) {
    rows[[key]] <<- data.frame(
      component      = component,
      ok             = ok,
      detail         = as.character(detail),
      fix_if_missing = if (isTRUE(ok)) "" else as.character(fix),
      stringsAsFactors = FALSE
    )
  }

  # R version
  add("R", "R >= 4.1",
      getRversion() >= "4.1.0",
      as.character(getRversion()),
      "Install R 4.1+ from https://cran.r-project.org")

  # CRAN packages
  cran_pkgs <- c("tidyverse", "lubridate", "jsonlite", "devtools", "parallel")
  for (p in cran_pkgs) {
    have <- requireNamespace(p, quietly = TRUE)
    add(paste0("pkg_", p),
        paste0("R package: ", p),
        have,
        if (have) as.character(utils::packageVersion(p)) else "missing",
        sprintf("install.packages('%s')", p))
  }

  # BioC package
  have_rhdf5 <- requireNamespace("rhdf5", quietly = TRUE)
  add("rhdf5", "BioC package: rhdf5",
      have_rhdf5,
      if (have_rhdf5) as.character(utils::packageVersion("rhdf5")) else "missing",
      "install.packages('BiocManager'); BiocManager::install('rhdf5')")

  # src/ and input/
  src_dir   <- paste0(patch, "src/")
  input_dir <- paste0(patch, "input/")
  add("src",   "rSTEMMUS_SCOPE/src/",   dir.exists(src_dir),   src_dir,
      "Run initial_setup() or extract src.zip")
  add("input", "rSTEMMUS_SCOPE/input/", dir.exists(input_dir), input_dir,
      "Run initial_setup() or extract input.7z")

  # Octave
  octave_exe <- NULL
  if (.Platform$OS.type == "windows") {
    cand <- tryCatch(
      list.files("C:/Program Files/GNU Octave", pattern = "octave-cli\\.exe$",
                 recursive = TRUE, full.names = TRUE),
      error = function(e) character(0))
    if (length(cand)) octave_exe <- cand[1]
    if (is.null(octave_exe)) {
      w <- suppressWarnings(system("where octave-cli", intern = TRUE))
      if (length(w) && nchar(w[1])) octave_exe <- w[1]
    }
  } else {
    w <- suppressWarnings(system("which octave-cli 2>/dev/null || which octave 2>/dev/null",
                                 intern = TRUE))
    if (length(w) && nchar(w[1])) octave_exe <- w[1]
  }
  add("octave", "GNU Octave (engine option)",
      !is.null(octave_exe),
      if (!is.null(octave_exe)) octave_exe else "not on PATH",
      "Win: 'scoop install octave' or download from octave.org; Mac: 'brew install octave'; Linux: 'apt install octave'")

  # MATLAB
  matlab_exe <- NULL
  if (.Platform$OS.type == "windows") {
    wp <- c(list.files("C:/Program Files/MATLAB", pattern = "^R", full.names = TRUE))
    if (length(wp)) matlab_exe <- paste0(wp[length(wp)], "/bin/matlab.exe")
    if (!is.null(matlab_exe) && !file.exists(matlab_exe)) matlab_exe <- NULL
  } else {
    mac_apps <- tryCatch(
      list.files("/Applications", pattern = "^MATLAB_R", full.names = TRUE),
      error = function(e) character(0))
    if (length(mac_apps)) matlab_exe <- paste0(mac_apps[length(mac_apps)], "/bin/matlab")
    if (is.null(matlab_exe) || !file.exists(matlab_exe)) {
      linux_dirs <- tryCatch(
        list.files("/usr/local/MATLAB", pattern = "^R", full.names = TRUE),
        error = function(e) character(0))
      if (length(linux_dirs)) matlab_exe <- paste0(linux_dirs[length(linux_dirs)], "/bin/matlab")
    }
    if (!is.null(matlab_exe) && !file.exists(matlab_exe)) matlab_exe <- NULL
  }
  add("matlab", "MATLAB (engine option)",
      !is.null(matlab_exe),
      if (!is.null(matlab_exe)) matlab_exe else "not detected",
      "Commercial install from mathworks.com (license required)")

  # MCR binary
  mcr_candidates <- c(
    paste0(patch, "src/STEMMUS_SCOPE_exe/STEMMUS_SCOPE_exe.exe"),
    paste0(patch, "src/STEMMUS_SCOPE_exe/run_STEMMUS_SCOPE_exe.sh"),
    paste0(patch, "bin/STEMMUS_SCOPE_exe.exe"),
    paste0(patch, "bin/run_STEMMUS_SCOPE_exe.sh"),
    Sys.getenv("STEMMUS_SCOPE_EXE", unset = "")
  )
  mcr_bin <- mcr_candidates[file.exists(mcr_candidates) & nchar(mcr_candidates) > 0]
  add("mcr", "MCR binary (engine option, license-free)",
      length(mcr_bin) > 0,
      if (length(mcr_bin)) mcr_bin[1] else "not found",
      "Download STEMMUS_SCOPE_exe from project Release page, or compile via src/compile_stemmus_scope.m")

  out <- do.call(rbind, rows)
  rownames(out) <- NULL

  if (verbose) {
    cat("\n=== rSTEMMUS_SCOPE install check ===\n")
    for (i in seq_len(nrow(out))) {
      mark <- if (out$ok[i]) "OK " else "MISS"
      cat(sprintf("  [%s] %-44s %s\n", mark, out$component[i], out$detail[i]))
      if (!out$ok[i]) cat(sprintf("        fix: %s\n", out$fix_if_missing[i]))
    }
    engines_ok <- out$ok[out$component %in% c(
      "GNU Octave (engine option)",
      "MATLAB (engine option)",
      "MCR binary (engine option, license-free)")]
    cat("\n")
    if (!any(engines_ok)) {
      cat("WARNING: no execution engine detected. Install at least one of Octave / MATLAB / MCR.\n")
    } else if (sum(engines_ok) == 1) {
      cat("Note: 1 engine available — that is enough to run simulations.\n")
    } else {
      cat(sprintf("Note: %d engines available — you can choose any via exe_method.\n", sum(engines_ok)))
    }
  }

  invisible(out)
}
