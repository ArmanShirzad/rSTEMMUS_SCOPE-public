#' to extract soil properties for point locations (Lat/Lon or sf multipoint object)
#'
#' @description
#' `get_SoilProperties` returns all soil properties required to run the model.
#'
#' @details
#' This is a function to prepare the soil properties to run the set_static_inputs function by
#' extracting soil properties from raster ```../input/SoilProperty/``` folder using
#' coordinates ```+proj=longlat +datum=WGS8```.
#' **important** the folder ```../inputs_for_input/SoilProperty/``` with the global data files need to be downloaded.
#'
#' @param patch the patch to the raster files, default ```"D:/model/rSTEMMUS_SCOPE/input/SoilProperty/"```,
#' @param lat,lon the latitude and longitude of the point of interest,
#' @param sf_points alternatively a multipoint sf object
#' @return returns list with all soil properties required
#' @family get input parameters
#'
#' @examples
#' \dontrun{
#' Soil_property_loc1 <- get_SoilProperties(patch = "D:/model/rSTEMMUS_SCOPE/input/SoilProperty/",
#'                                          lon = 107.688,
#'                                          lat = 37.829)
#' }
#' @export
#'
get_SoilProperties <- function(patch = "D:/model/rSTEMMUS_SCOPE/input/SoilProperty/",
                               lon = NA,
                               lat = NA,
                               sf_points = NULL
){

  Soil_property_files <- list.files(patch, pattern = ".tif$", full.names=TRUE, recursive=F)
  Soil_property_files <- Soil_property_files[c(2,7,6,4,1,3,5,9,10,8)]

  if(missing(sf_points)){

    lat_lon <- data.frame("lon" = lon, "lat" = lat)

  }else{

    # coordinates
    lat_lon <- data.frame(sf::st_coordinates(sf_points$geometry))
    names(lat_lon) <- c("lon","lat")
  }

  lat_surfdata <- (lat_lon$lat + 90)*2
  lon_surfdata <- (lat_lon$lon)*2
  lon_surfdata <- ifelse(lon_surfdata<0, lon_surfdata+720, lon_surfdata)
  lat_lon_surfdata <- data.frame("lon" = lon_surfdata,"lat" = lat_surfdata)

  Soil_property_points <- list()

  for(i in 1:9){     #seq_along(fin)
    print(i)
    r <- terra::rast(Soil_property_files[i])
    Soil_property_points[[i]] <- terra::extract(r, lat_lon)
  }

  r <- terra::rast(Soil_property_files[10])
  Soil_property_points[[10]] <- terra::extract(r, lat_lon_surfdata)

  soil_parameters <- c()

  # replace the values to the location 1
  soil_parameters$FOC[1:6] <- unlist(Soil_property_points[[1]]/100)[-1]
  soil_parameters$FOS[1:6] <- unlist(Soil_property_points[[2]]/100)[-1]
  soil_parameters$MSOC[1:6] <- unlist(Soil_property_points[[3]]/10000)[-1]

  soil_parameters$Coef_Lamda[1:6] <- unlist(Soil_property_points[[4]])[-1]
  soil_parameters$Coefficient_Alpha[1:6] <- unlist(Soil_property_points[[5]])[-1]
  soil_parameters$SaturatedK[1:6] <- (unlist(Soil_property_points[[6]])[-1])/(24*3600)
  soil_parameters$Ks0 <- (unlist(Soil_property_points[[6]])[-1])[1]
  soil_parameters$Coefficient_n[1:6] <- unlist(Soil_property_points[[7]])[-1]
  soil_parameters$ResidualMC[1:6] <- unlist(Soil_property_points[[8]])[-1] #theta r
  soil_parameters$porosity[1:6] <- unlist(Soil_property_points[[9]])[-1]   #theta s
  soil_parameters$SaturatedMC[1:6] <- unlist(Soil_property_points[[9]])[-1]
  soil_parameters$theta_s0 <- (unlist(Soil_property_points[[9]])[-1])[1]

  # calculate field capacity
  soil_parameters$fieldMC[1:6] <- unlist(Soil_property_points[[8]])[-1] +
    (unlist(Soil_property_points[[9]])[-1] - unlist(Soil_property_points[[8]])[-1]) /
    (1 + (unlist(Soil_property_points[[5]])[-1]*341.9)^unlist(Soil_property_points[[7]])[-1])^(1 -  1/unlist(Soil_property_points[[7]])[-1])

  # fmax
  soil_parameters$fmax <- unlist(Soil_property_points[[10]])[-1]

  return(soil_parameters)

}

