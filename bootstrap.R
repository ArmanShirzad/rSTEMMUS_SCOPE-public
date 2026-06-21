# ============================================================================
# rSTEMMUS_SCOPE bootstrap — single-command setup for a fresh researcher.
# ============================================================================
#
# USAGE:
#   1. git clone https://github.com/EcoExtreML/rSTEMMUS_SCOPE
#   2. cd rSTEMMUS_SCOPE
#   3. Rscript bootstrap.R
#
# What this does (in order):
#   - Asserts R version >= 4.1
#   - Installs missing CRAN packages (tidyverse, lubridate, devtools,
#     jsonlite, parallel, BiocManager)
#   - Installs BioC package rhdf5
#   - Loads the rSTEMMUS_SCOPE package code from the current directory
#   - Calls initial_setup() if src/ or input/ is missing (downloads model
#     source + input templates from the upstream release; a few hundred MB)
#   - Runs verify_install() to report engine availability
#   - Prints PASS / PARTIAL / FAIL with the exact next step
#
# After this completes successfully, copy
# 2026Contributions/scripts/runs/standardRoadmapLocation2.R, edit Section 2
# with your site config, and run it.
# ============================================================================

if (getRversion() < "4.1.0") {
  stop(sprintf("R >= 4.1 required. Found: %s\nInstall from https://cran.r-project.org",
               getRversion()))
}
cat(sprintf("R %s — OK\n", getRversion()))

# 1. CRAN packages — `archive` is required for initial_setup() to extract
#    input.7z / runs.7z; without it the unpacking silently fails and
#    new_run() later crashes with "more 'from' files than 'to' files".
cran_pkgs <- c("tidyverse", "lubridate", "devtools", "jsonlite",
               "parallel", "BiocManager", "archive", "filesstrings")
missing_cran <- cran_pkgs[!vapply(cran_pkgs,
                                  requireNamespace,
                                  logical(1),
                                  quietly = TRUE)]
if (length(missing_cran)) {
  cat(sprintf("Installing CRAN packages: %s\n",
              paste(missing_cran, collapse = ", ")))
  install.packages(missing_cran, repos = "https://cloud.r-project.org")
} else {
  cat("CRAN packages — OK\n")
}

# 2. BioC package rhdf5
if (!requireNamespace("rhdf5", quietly = TRUE)) {
  cat("Installing BioC package rhdf5 ...\n")
  BiocManager::install("rhdf5", update = FALSE, ask = FALSE)
} else {
  cat("rhdf5 — OK\n")
}

# 3. Load the package code (does not install into the user library; just
#    makes new_run(), input_constants(), run_inMATLAB(), initial_setup(),
#    verify_install(), validate_weather_rds() available for this session).
suppressMessages(devtools::load_all("."))
cat("rSTEMMUS_SCOPE package loaded\n")

# 4. initial_setup if model files are missing
patch_path <- paste0(getwd(), "/rSTEMMUS_SCOPE/")
need_setup <- !dir.exists(paste0(patch_path, "src/")) ||
              !dir.exists(paste0(patch_path, "input/"))
if (need_setup) {
  cat("\nsrc/ or input/ missing — running initial_setup() to download\n")
  cat("model source and input templates (a few hundred MB) ...\n\n")
  initial_setup(patch = patch_path)
} else {
  cat("Model files present — skipping initial_setup()\n")
}

# 4a. Re-extract input.7z / runs.7z next to themselves if they're still
#     present in patch_path and their target dirs look incomplete. This
#     handles the silent-extraction-failure mode where initial_setup ran
#     before the 'archive' package was installed: the .7z files sit there
#     but input/ / runs/ are empty or missing.
ensure_extracted <- function(archive_name, target_subdir,
                             minimum_subdirs = character(0)) {
  archive_path <- paste0(patch_path, archive_name)
  target_path  <- paste0(patch_path, target_subdir)
  if (!file.exists(archive_path)) return(invisible())
  needs_extract <- !dir.exists(target_path) ||
                   (length(minimum_subdirs) > 0 &&
                    !all(dir.exists(paste0(target_path, "/", minimum_subdirs))))
  if (!needs_extract) return(invisible())
  cat(sprintf("Re-extracting %s into %s (target was incomplete) ...\n",
              archive_name, patch_path))
  ok <- tryCatch({
    archive::archive_extract(archive_path, dir = patch_path)
    TRUE
  }, error = function(e) {
    cat(sprintf("  FAILED: %s\n", e$message))
    cat("  Most common cause: the 'archive' R package was not installed\n")
    cat("  the first time initial_setup() ran. It is now in cran_pkgs above.\n")
    FALSE
  })
  if (ok) cat(sprintf("  OK — re-extracted %s.\n", archive_name))
}
ensure_extracted("input.7z", "input",
                 minimum_subdirs = c("directional", "fluspect_parameters",
                                     "leafangles", "radiationdata", "soil_spectrum"))
ensure_extracted("runs.7z", "runs")

# 4b. Post-setup layout repair.
#  (i) Ensure runs/ exists. initial_setup() extracts runs.7z via
#      archive::archive_extract(); if that silently failed (e.g. archive
#      pkg wasn't installed when initial_setup first ran), runs/ never
#      gets created and new_run()'s dir.create("runs/SITE_RUN") fails
#      with reason "No such file or directory" — leading to the
#      downstream "more 'from' files than 'to' files" crash.
runs_dir <- paste0(patch_path, "runs/")
if (!dir.exists(runs_dir)) {
  dir.create(runs_dir, recursive = TRUE)
  cat("Layout repair: created empty runs/ directory.\n")
}

# (ii) new_run() expects 7 template files under input/input_files/ but the
#      upstream archive sometimes places them directly under input/ —
#      auto-fix by locating each file and copying it into input/input_files/
#      if missing there.
needed <- c("input_data.xlsx", "soil_init.mat", "forcing_globals.mat",
            "soil_parameters.mat", "getSoilConstants.m",
            "define_constants.m", "getModelSettings.m")
target_dir <- paste0(patch_path, "input/input_files/")
if (!dir.exists(target_dir)) dir.create(target_dir, recursive = TRUE)
n_repaired <- 0L; n_missing <- 0L
for (f in needed) {
  if (file.exists(paste0(target_dir, f))) next
  hits <- list.files(paste0(patch_path, "input/"),
                     pattern = paste0("^", f, "$"),
                     recursive = TRUE, full.names = TRUE)
  if (length(hits) == 0 && f == "input_data.xlsx") {
    hits <- list.files(paste0(patch_path, "input/"),
                       pattern = "^input_data\\.xls$",
                       recursive = TRUE, full.names = TRUE)
  }
  if (length(hits)) {
    file.copy(hits[1], paste0(target_dir, f))
    n_repaired <- n_repaired + 1L
  } else {
    n_missing <- n_missing + 1L
  }
}
if (n_repaired > 0L) {
  cat(sprintf("Layout repair: copied %d files into input/input_files/\n", n_repaired))
}
if (n_missing > 0L) {
  cat(sprintf("WARN: %d required input files not found anywhere under input/\n", n_missing))
  cat("     Likely cause: initial_setup() failed to extract input.7z\n")
  cat("     Fix: install.packages('archive'); then re-source this bootstrap script.\n")
}

# 5. Verify install
status <- verify_install(patch = patch_path, verbose = TRUE)

# 6. Final report
required_ok <- status$ok[status$component %in%
                         c("R >= 4.1",
                           "R package: tidyverse",
                           "R package: lubridate",
                           "R package: jsonlite",
                           "R package: devtools",
                           "BioC package: rhdf5",
                           "rSTEMMUS_SCOPE/src/",
                           "rSTEMMUS_SCOPE/input/")]
engines_ok <- status$ok[status$component %in%
                        c("GNU Octave (engine option)",
                          "MATLAB (engine option)",
                          "MCR binary (engine option, license-free)")]

cat("\n========================================\n")
if (all(required_ok) && any(engines_ok)) {
  cat("PASS — ready to run simulations.\n\n")
  cat("Next step:\n")
  cat("  file.copy('2026Contributions/scripts/runs/standardRoadmapLocation2.R',\n")
  cat("            'roadmap_MySite.R')\n")
  cat("  # then edit Section 2 with your site config and run:\n")
  cat("  Rscript roadmap_MySite.R\n")
} else if (all(required_ok) && !any(engines_ok)) {
  cat("PARTIAL — package + R deps OK but no execution engine installed.\n")
  cat("Install at least one of: Octave (free), MATLAB (license), or the MCR binary.\n")
} else {
  cat("FAIL — missing required components (see 'MISS' rows above).\n")
}
cat("========================================\n")
