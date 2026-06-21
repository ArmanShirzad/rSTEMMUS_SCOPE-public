library(tidyverse)

# Stitch Part 1 + Part 2 CSVs into a single 2-year dataset
# Part 1: DE-STG_DE-STG_Test_FIXED_Final_2yr_OCTAVE_2026Apr07_1524  (rows 1–4345)
# Part 2: run after run_2year_part2.R completes

part1_dir <- "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_Test_FIXED_Final_2yr_OCTAVE_2026Apr07_1524"
part2_dir_file <- "2026Contributions/latest_2yr_part2_output_dir.txt"

if (!file.exists(part2_dir_file)) stop("Run run_2year_part2.R first, then stitch.")
part2_dir <- trimws(readLines(part2_dir_file))
cat(sprintf("Part 1: %s\n", part1_dir))
cat(sprintf("Part 2: %s\n", part2_dir))

out_dir <- "2026Contributions/stitched_2yr_output"
dir.create(out_dir, showWarnings = FALSE)

stitch_csv <- function(fname, skip_header_rows = 3) {
  f1 <- file.path(part1_dir, fname)
  f2 <- file.path(part2_dir, fname)
  if (!file.exists(f1)) { cat(sprintf("  SKIP (Part1 missing): %s\n", fname)); return(invisible(NULL)) }
  if (!file.exists(f2)) { cat(sprintf("  SKIP (Part2 missing): %s\n", fname)); return(invisible(NULL)) }

  headers <- readLines(f1, n = skip_header_rows)
  d1 <- read.csv(f1, skip=skip_header_rows, header=FALSE, stringsAsFactors=FALSE)
  d2 <- read.csv(f2, skip=skip_header_rows, header=FALSE, stringsAsFactors=FALSE)
  cat(sprintf("  %s: Part1=%d rows, Part2=%d rows → total=%d\n",
              fname, nrow(d1), nrow(d2), nrow(d1)+nrow(d2)))

  out_file <- file.path(out_dir, fname)
  writeLines(headers, out_file)
  combined <- bind_rows(d1, d2)
  write.table(combined, out_file, append=TRUE, sep=",", row.names=FALSE, col.names=FALSE, quote=FALSE)
  invisible(out_file)
}

stitch_csv("fluxes.csv",    skip_header_rows = 2)
stitch_csv("Sim_Theta.csv", skip_header_rows = 3)
stitch_csv("Sim_Temp.csv",  skip_header_rows = 3)

cat(sprintf("\nStitched output saved to: %s/\n", out_dir))
cat(sprintf("Part 1 rows: 4345  |  Part 2 rows: see above\n"))
cat(sprintf("Expected total for full 2-year run: ~17520 rows\n"))
