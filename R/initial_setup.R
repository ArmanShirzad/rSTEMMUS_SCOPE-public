#' to create a input folder with required files to run the model
#'
#' @description
#' `initial_setup` create the file structure with the MATLAB codes and inputs in a directory of choice.
#'
#' @details
#' This is a function to prepare the STEMMUS_SCOPE (Matlab) codes and required  model inputs.
#' **important** It is only needed once after install the package as initial setup
#'
#' When `patch` already holds the model tree of a cloned repository (`src/` plus
#' `input.7z`), nothing is downloaded: only `input.7z` and `runs.7z` are
#' extracted. An existing `src/` is never overwritten and the archives are kept,
#' because `src.zip` is an older snapshot of the model code and unpacking it
#' over `src/` would silently revert the Octave/MATLAB fixes.
#'
#' @param patch the path to the STEMMUS_SCOPE downloaded, example:```"D:/models/rSTEMMUS_SCOPE/"```.
#' @param source_url zip archive of the repository to take the model tree from when
#'   `patch` does not hold one yet. Defaults to this fork, which carries the fixed `src/`.
#' @return It return a message that shows the main path to run all the functions.
#' @examples
#'
#' \dontrun{
#' initial_setup(patch = "D:/model/rSTEMMUS_SCOPE/")
#'}
#'
#' @export
#'
initial_setup <- function(patch = "D:/model/rSTEMMUS_SCOPE/",
                          source_url = "https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/archive/refs/heads/main.zip"

){

  if(dir.exists(patch) == FALSE) {

  dir.create(patch, recursive = TRUE)

    }

in_clone <- dir.exists(paste0(patch, "src/")) && file.exists(paste0(patch, "input.7z"))

if (!in_clone) {
# download a .zip file of the repository and copy its rSTEMMUS_SCOPE/ folder
# (src/, input.7z, runs.7z, ...) into patch, keeping the folder structure
tmp_dir <- tempfile("rSTEMMUS_SCOPE_")
dir.create(tmp_dir)
utils::download.file(url = source_url,
              destfile = file.path(tmp_dir, "repo.zip"), mode = "wb")
utils::unzip(file.path(tmp_dir, "repo.zip"), exdir = tmp_dir)

model_tree <- list.files(tmp_dir, pattern = "^rSTEMMUS_SCOPE$", include.dirs = TRUE,
                         recursive = TRUE, full.names = TRUE)
model_tree <- model_tree[dir.exists(model_tree)][1]
if (is.na(model_tree)) {
  stop("No rSTEMMUS_SCOPE/ folder found in ", source_url)
}

file.copy(list.files(model_tree, full.names = TRUE), patch,
          recursive = TRUE, overwrite = FALSE)

unlink(tmp_dir, recursive = TRUE)
}

# src.zip is only a fallback for a tree without src/
if (!dir.exists(paste0(patch, "src/")) && file.exists(paste0(patch, "src.zip"))) {
  utils::unzip(paste0(patch, "src.zip"), exdir = patch)
}

dir.create(paste0(patch, "output"), showWarnings = FALSE)
if (file.exists(paste0(patch, "AR-SLu_2024-01-25-0911.zip"))) {
  utils::unzip(paste0(patch, "AR-SLu_2024-01-25-0911.zip"),
               exdir = paste0(patch, "output"))
}

# Extract the .7z files (kept afterwards: they are tracked in the repository)
if (!dir.exists(paste0(patch, "input/"))) {
  archive::archive_extract(paste0(patch, "input.7z"),
                           dir = patch)
}

if (!dir.exists(paste0(patch, "runs/"))) {
  archive::archive_extract(paste0(patch, "runs.7z"),
                           dir = patch)
}

return(print(paste0("The STEMMUS_SCOPE is set at ", patch, " and ready to start.")  ))

}
