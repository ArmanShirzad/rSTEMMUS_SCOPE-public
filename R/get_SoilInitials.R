#' to download soil initial conditions from ERA5
#'
#' @description
#' `get_SoilInitials` returns Soil temperature and Volumetric Soil Water per depth required to run the model.
#'
#' @details
#' This is a function to Download the soil initial from Copernicus ERA5. Soil temperature and Volumetric Soil Water per depth
#' are required to run the model.
#' **important** to run this function is needed to set a key to the keychain (ecmwfr) to have access to the
#' Copernicus platform.
#'
#' @param patch the patch to save/write the file
#' @param dataset = "reanalysis-era5-land"
#' @param product = "reanalysis"
#' @param vars = c(
#' @param area_box = c(52.10, 9.75, 51.0, 11.65),
#' @param years,months,days,times include the first day of the time series "YYYY", "MM", "DD" and "HH:mm"
#' @param format = "grib"
#' @param target_f = "download2.grib",
#' @param timeout_m = 50
#' @return returns list with all soil initials required
#' @family get input parameters
#'
#' @examples
#'
#' \dontrun{
#' library(ecmwfr)
#' set a key to the keychain
#' wf_set_key(key = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx")
#'
#' get_SoilInitials(dataset = "reanalysis-era5-land",
#'                  product = "reanalysis",
#'                  format = "grib",
#'                  area_box = c(52.10, 9.75, 51.0, 11.65),
#'                  #site_name = NA,
#'                  vars = c("skin_temperature",
#'                           "soil_temperature_level_1",
#'                           "soil_temperature_level_2",
#'                           "soil_temperature_level_3",
#'                           "soil_temperature_level_4",
#'                           "volumetric_soil_water_layer_1",
#'                           "volumetric_soil_water_layer_2",
#'                           "volumetric_soil_water_layer_3",
#'                           "volumetric_soil_water_layer_4"),
#'                 years = "2023",
#'                 months = "06",
#'                 days = "01",
#'                 times = "00:00",
#'                 path_file = "D:/model/rSTEMMUS_SCOPE/input/",
#'                 target_f = "download2.grib",
#'                 timeout_m = 50)
#'
#' initials_01JUN23 <- terra::rast("D:/model/rSTEMMUS_SCOPE/data/Init_Cond_01_JUN.grib")
#' }
#'
#' @export
#'
get_SoilInitials <- function(
    dataset = "reanalysis-era5-land",
    product = "reanalysis",
    format = "grib",
    area_box = NA,
    vars = NA,
    years = NA,
    months = NA,
    days = NA,
    times = NA,
    patch = NA,
    target_f = "download.grib",
    timeout_m = 50

){

  requested <- list(
    dataset_short_name = dataset,
    product_type = product,
    variable = vars,
    year = years,
    month = months,
    day = days,
    time = times,
    area = area_box,
    data_format = format,
    target = target_f)

  ecmwfr::wf_request(requested,  # the request
                     job_name = "InitialConditions",
                     transfer = TRUE,     # download the file
                     patch = patch)# store data in current working directory

}



