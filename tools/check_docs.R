# ============================================================================
# Documentation check — run from the repository root:
#   Rscript tools/check_docs.R
#
#   1. Every ```r block in the Markdown docs must parse as R. This catches
#      copy-paste breakers such as an input_constants( call whose closing
#      parenthesis ended up inside a comment.
#   2. Every link into this repository (relative, or absolute to
#      github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/blob|tree/main/) must
#      point at a file or folder that is tracked here, so it cannot 404.
#
# Exits with status 1 if anything fails (used by .github/workflows/docs.yml).
# ============================================================================

repo_url <- "https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public"

md_files <- c(list.files(".", pattern = "\\.md$"),
              list.files("examples", pattern = "\\.md$", recursive = TRUE, full.names = TRUE),
              list.files("docs", pattern = "\\.md$", recursive = TRUE, full.names = TRUE))
md_files <- sub("^\\./", "", md_files)

failures <- character(0)
fail <- function(...) failures <<- c(failures, sprintf(...))

for (f in md_files) {
  x <- readLines(f, warn = FALSE, encoding = "UTF-8")

  # 1. R code blocks parse
  fences <- grep("^```", x)
  starts <- grep("^```[[:space:]]*[{]?[rR]([^[:alnum:]]|$)", x)
  for (s in starts) {
    e <- fences[fences > s][1]
    if (is.na(e)) { fail("%s:%d  unterminated code block", f, s); next }
    msg <- tryCatch({ parse(text = x[(s + 1):(e - 1)]); NULL },
                    error = function(err) conditionMessage(err))
    if (!is.null(msg)) fail("%s:%d  R block does not parse:\n    %s",
                            f, s, gsub("\n", "\n    ", msg))
  }

  # 2. links into this repository resolve to tracked paths
  for (i in seq_along(x)) {
    links <- regmatches(x[i], gregexpr("\\]\\(([^)[:space:]]+)\\)", x[i]))[[1]]
    links <- sub("^\\]\\((.*)\\)$", "\\1", links)
    for (l in links) {
      l <- sub("#.*$", "", l)
      if (startsWith(l, repo_url)) {
        path <- sub(paste0("^", repo_url, "/(blob|tree)/main/?"), "", l)
        if (identical(path, l)) next                    # repo root, issues, releases, ...
      } else if (!grepl("^[a-zA-Z][a-zA-Z0-9+.-]*:", l) && nzchar(l)) {
        path <- file.path(dirname(f), l)                 # relative link
      } else next
      path <- utils::URLdecode(sub("/$", "", path))
      if (nzchar(path) && !file.exists(path)) fail("%s:%d  link target missing: %s", f, i, l)
    }
  }
}

if (length(failures)) {
  cat("Documentation check FAILED:\n", paste0("  ", failures, collapse = "\n"), "\n", sep = "")
  quit(status = 1)
}
cat(sprintf("Documentation check passed (%d Markdown files).\n", length(md_files)))
