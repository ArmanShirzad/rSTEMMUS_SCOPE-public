#' to create a input folder with required files to run the model
#'
#' @description
#' `initial_setup` create the file structure with the MATLAB codes and inputs in a directory of choice.
#'
#' @details
#' This is a function to prepare the STEMMUS_SCOPE (Matlab) codes and required  model inputs.
#' **important** It is only needed once after install the package as initial setup
#'
#' @param patch the path to the STEMMUS_SCOPE downloaded, example:```"D:/models/rSTEMMUS_SCOPE/"```.
#' @return It return a message that shows the main path to run all the functions.
#' @examples
#'
#' \dontrun{
#' initial_setup(patch = "D:/model/rSTEMMUS_SCOPE/")
#'}
#'
#' @export
#'
initial_setup <- function(patch = "D:/model/rSTEMMUS_SCOPE/"

){

  if(dir.exists(patch) == FALSE) {

  dir.create(patch, recursive = TRUE)

    }

# download a .zip file of the repository
# from the "Clone or download - Download ZIP" button
# on the GitHub repository of interest
utils::download.file(url = "https://github.com/EcoExtreML/rSTEMMUS_SCOPE/archive/master.zip",
              destfile = paste0(patch, "master.zip"))
# unzip the .zip file
utils::unzip(paste0(patch, "master.zip"), exdir = patch)
unlink(paste0(patch, "master.zip"), recursive = TRUE)

files_rSTEMMUS_SCOPE <- list.files(paste0(patch, "rSTEMMUS_SCOPE-master/rSTEMMUS_SCOPE/"),
                                   full.names = TRUE, recursive = TRUE)

filesstrings::file.move(files_rSTEMMUS_SCOPE, patch)

# delete a directory -- must add recursive = TRUE
unlink(paste0(patch, "rSTEMMUS_SCOPE-master"), recursive = TRUE)

utils::unzip(paste0(patch, "src.zip"), exdir = patch)
unlink(paste0(patch, "src.zip"), recursive = TRUE)

dir.create(paste0(patch, "output"))
utils::unzip(paste0(patch, "AR-SLu_2024-01-25-0911.zip"),
             exdir = paste0(patch, "output"))
unlink(paste0(patch, "AR-SLu_2024-01-25-0911.zip"), recursive = TRUE)

# Extract the .7z file
archive::archive_extract(paste0(patch, "input.7z"),
                         dir = patch)
unlink(paste0(patch, "input.7z"), recursive = TRUE)

archive::archive_extract(paste0(patch, "runs.7z"),
                         dir = patch)
unlink(paste0(patch, "runs.7z") , recursive = TRUE)

return(print(paste0("The STEMMUS_SCOPE is set at ", patch, " and ready to start.")  ))

}
