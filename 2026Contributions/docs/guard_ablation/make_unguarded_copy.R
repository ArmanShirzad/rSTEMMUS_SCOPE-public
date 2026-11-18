# make_unguarded_copy.R — build the OLD (unguarded) model for the guard ablation.
#
# Copies the ten files in unguarded_src/ over the model source of a SEPARATE copy
# of this repository, so that copy runs the pre-hardening solver while this one
# keeps the guarded build. Nothing in the current repository is changed.
#
# Usage (from the root of this repository):
#   Rscript 2026Contributions/docs/guard_ablation/make_unguarded_copy.R <path-to-second-copy>
# e.g.
#   git clone https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public.git ../rSTEMMUS_SCOPE-unguarded
#   Rscript 2026Contributions/docs/guard_ablation/make_unguarded_copy.R ../rSTEMMUS_SCOPE-unguarded

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("give the path to a second copy of the repository")

from <- "2026Contributions/docs/guard_ablation/unguarded_src"
to <- file.path(args[1], "rSTEMMUS_SCOPE", "src")
if (!dir.exists(from)) stop("run this from the root of the repository (", from, " not found)")
if (!dir.exists(to)) stop("model source not found at ", to)
if (normalizePath(to) == normalizePath("rSTEMMUS_SCOPE/src"))
  stop("the target is this repository; use a separate copy so the guarded build stays intact")

files <- list.files(from, recursive = TRUE, all.files = TRUE)
stopifnot(length(files) == 10)
for (f in files) {
  stopifnot(file.exists(file.path(to, f)))       # every file replaces an existing one
  file.copy(file.path(from, f), file.path(to, f), overwrite = TRUE)
}
ok <- unname(tools::md5sum(file.path(from, files)) == tools::md5sum(file.path(to, files)))
stopifnot(all(ok))
cat(sprintf("Replaced %d files in %s with their unguarded versions:\n", length(files), to))
cat(paste0("  ", files, collapse = "\n"), "\n")
