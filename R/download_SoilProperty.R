#' to download a folder with maps of required soil properties to run the ```get_SoilSroperties()```
#'
#' @description
#' `download_SoilProperty` download a folder nammed SoilProperty a the ```/input``` diretory.
#'
#' @details
#' This is a function to download required model inputs (see ReadME 1.4 Soil Properties).
#' **important** It is only needed once after install the package with ```initial_setup()```
#'
#' @param patch the path to the STEMMUS_SCOPE downloaded, example:```"D:/models/rSTEMMUS_SCOPE/"```.
#' @param doi the Zenodo doi of the SoilProperty folder (do not change)
#' @param timeout the file is 24 GB so you may need to increase it, default 1000
#' @return It return a message: SoilProperty folder download at ```"patch/input/"```.
#' @examples
#'
#' \dontrun{
#' download_SoilProperty(patch = "D:/model/rSTEMMUS_SCOPE/")
#'}
#'
#' @export
#'
download_SoilProperty <- function(patch = "D:/model/rSTEMMUS_SCOPE/",
                                  doi = "10.5281/zenodo.15488066",
                                  timeout = 1000

){

  # download a .zip file of the Zenodo repository
  zen4R::download_zenodo(doi,
                         path = paste0(patch, "input/"),
                         timeout = timeout,
                         files = list("SoilProperty.zip"))

  utils::unzip(paste0(patch, "input/","SoilProperty.zip"), exdir = paste0(patch, "input/"))

  file.remove(paste0(patch, "input/","SoilProperty.zip"))

  return(print(paste0("SoilProperty folder download at ", patch, "/input/", "and ready use get_SoilSroperties().")  ))

}
