#' to download Global Canopy Height 10m raster cropped to the area of interest
#'
#' @description
#' `get_CanopyHeight` write an .tif raster image with 10m pixel for the area of interest.
#'
#' @details
#' This is a function to download from the Global Canopy Height (GCH) product a 10m raster,
#' and cropped to the area of interest.
#'
#' @param patch the patch to save/write the file
#' @param site_name name of the site,
#' @param N_S_degree latitude of the point of interest,
#' @param W_E_degree Longitude of the point of interest,
#' @return an .tif raster image with 10m pixel for the area of interest in the chosen patch
#' @family get input parameters
#'
#' @examples
#'
#' \dontrun{
#' # run to get Canopy height hc
#' library(curl)
#' loc_csv <- data.frame("Latitude" = round(sf::st_coordinates(locations$geometry)[,2],2),
#'                       "Longitude" = round(sf::st_coordinates(locations$geometry)[,1],2))
#'
#' for all location
#' get_GCH(site_name = "Selke",
#'        N_S_degree = loc_csv$Latitude[1],
#'        W_E_degree = loc_csv$Longitude[1],
#'        patch = "D:/model/STEMMUS_SCOPE/input/input_for_input/Forcing_Globals/")
#'
#' Global Canopy Height 2020
#' canopy_height <- terra::rast("D:/model/STEMMUS_SCOPE/input/input_for_input/GCH/GCH_tile_Selke.tif")
#' canopy_height <- terra::crop(canopy_height, selke_square_ext)
#'
#' hc_points <- data.frame(terra::extract(canopy_height, locations))
#' names(hc_points) <- c("Name", "VH")
#' }
#'
#' @export
get_CanopyHeight <- function(
    site_name = NA,
    N_S_degree = NA,
    W_E_degree = NA,
    patch = NA
){
  degree_N_S <- seq(0, 180, 3)[which(data.table::between(round(N_S_degree), seq(0, 177, 3), seq(3, 180, 3)))]
  degree_W_E <- seq(0, 180, 3)[which(data.table::between(round(W_E_degree), seq(0, 177, 3), seq(3, 180, 3)))]

  degree_N_S <- ifelse(as.numeric(degree_N_S) < 10, paste0("0", degree_N_S), degree_N_S)

  degree_W_E <- ifelse(as.numeric(degree_W_E) < 10, paste0("00", degree_W_E),  paste0("0",degree_W_E))

  url <- ifelse(W_E_degree < 0,
                paste0("https://libdrive.ethz.ch/index.php/s/cO8or7iOe5dT2Rt/download?path=%2F3deg_cogs&files", "=", "ETH_GlobalCanopyHeight_10m_2020_",
                       "N", degree_N_S, "W", "003","_Map.tif"),
                paste0("https://libdrive.ethz.ch/index.php/s/cO8or7iOe5dT2Rt/download?path=%2F3deg_cogs&files", "=", "ETH_GlobalCanopyHeight_10m_2020_",
                       "N", degree_N_S, "E", degree_W_E,"_Map.tif"))

  utils::download.file(url,
                       destfile = paste0(patch, "GCH_tile_", site_name, ".tif"),
                       method="curl")
  print(url)

}
