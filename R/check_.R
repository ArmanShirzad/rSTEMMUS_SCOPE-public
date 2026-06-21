# SCOPE ----

#' to check current SCOPE options
#'
#' @description
#' `check_SCOPE_options` present current SCOPE model options selected in the input_data.xlsx file
#'
#' @details
#' This function shows current SCOPE model options selected to run. If not changes were done
#' the options are the defaults @seealso [info_SCOPE_options()]
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run. The last can be used to name runs with different model parameters or settings,
#' @return a table with information about SCOPE current selected model options
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' check_SCOPE_options(site_name = "DE-Hai", run_name = "ECdata_36")
#'
#' formattable::formattable(check_SCOPE_options(site_name = "DE-Hai", run_name = "ECdata_36"),
#'                          align = c("c","l"))
#' }
#'
#' @export
#'
check_SCOPE_options <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA
  ){

input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

SCOPE_options <- input_data[[2]][4:21,1:2]
row.names(SCOPE_options) <- NULL

return(SCOPE_options)

}


#' to check current SCOPE constants
#'
#' @description
#' `check_SCOPE_constants` present current SCOPE model constant filled in the input_data.xlsx file
#'
#' @details
#' This function shows current SCOPE  constant used to run the model. If it was not changed while
#' using @seealso [input_constants()] it will present the default values.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run. The last can be used to name runs with different model parameters or settings,
#' @return a table with information about SCOPE current model constant parameters
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(check_SCOPE_constants(site_name = "DE-Hai", run_name = "ECdata_36")[[1]],
#'             align = c("l","c","c","l"))
#'
#' formattable::formattable(check_SCOPE_constants(site_name = "DE-Hai", run_name = "ECdata_36")[[2]],
#'             align = c("l","c","c","l"))
#' }
#'
#' @export
#'
check_SCOPE_constants <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA
){
  input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

  SCOPE_constants <- input_data[[4]][6:117,c(1,2,8,9)]
  SCOPE_constants <- dplyr::filter(SCOPE_constants, !is.na("Input_for_SCOPE"))
  SCOPE_constants[,1] <- stringr::word(SCOPE_constants[,1], 1)
  SCOPE_constants[is.na(SCOPE_constants)] <- ""

  Tparam <- input_data[[4]][25, c(1,2,3,4,5,6,9)]
  constant_list <- list(SCOPE_constants, Tparam)

  return(constant_list)

}


#'  to check current SCOPE time series input files used by the model
#'
#' @description
#' `check_SCOPE_tsInputs` present current time series inputs used by the SCOPE model
#'
#' @details
#' This function shows current time series inputs used by SCOPE to run the model. More information about the
#' variable desciption and units @seealso [info_SCOPE_tsInputs()].
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run. The last can be used to
#' name runs with different model parameters or settings,
#' @return a table with information about SCOPE model current time series inputs
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' check_SCOPE_ts_Inputs(site_name = "DE-Hai", run_name = "ECdata_36")
#'
#' formattable::formattable(check_SCOPE_ts_Inputs(site_name = "DE-Hai",
#'                          run_name = "ECdata_36"), align = c("l","l"))
#' }
#'
#' @export
#'
check_SCOPE_tsInputs <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA
){
  input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

  SCOPE_ts_inputs <- input_data[[3]][3:33, c(1,2)]
  SCOPE_ts_inputs <- dplyr::filter(SCOPE_ts_inputs, !is.na("files"))

  row.names(SCOPE_ts_inputs) <- NULL

  return(SCOPE_ts_inputs)

}


# STEMMUS----

#' to check the STEMMUS Model Settings options
#'
#' @description
#' `check_STEMMUS_ModelSettings` present current model settings (options) for STEMMUS
#'
#' @details
#' This function shows current STEMMUS model options selected to run. If not changes were done
#' the options are the defaults @seealso [info_STEMMUS_ModelSettings()].
#' **important** differently from SCOPE options any change in the settings will impact all
#' next runs and not a specific site_name/run_name as in SCOPE.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @return a table with information about STEMMUS current selected model settings or options
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(check_STEMMUS_ModelSettings(), align = c("l","c"))
#' }
#'
#' @export
#'
check_STEMMUS_ModelSettings <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/"

){

  Settings <- utils::read.table(paste0(patch,"src/+io/checkModelSettings.m"), sep="|")

  Settings$V1[-1] |>
    stringr::str_split(pattern = " ModelSettings.") |> unlist() |>
    stringr::str_split(pattern = ";") |> unlist() |>
    stringr::str_subset(pattern = " = ") |>
    tibble::as_tibble() |>
    tidyr::separate_wider_delim("value", " = ", names = c("name", "value")) -> ModelSettings

  return(ModelSettings)

}


#' to check the current STEMMUS Model Soil Constants
#'
#' @description
#' `check_STEMMUS_SoilConstants` present current model Soil Constants inputs for STEMMUS
#'
#' @details
#' This function shows current STEMMUS model Soil Constants inputs. If not changes were done
#' the options are the defaults @seealso [info_STEMMUS_SoilConstants()].
#' **important** differently from SCOPE constant parameters any change in the settings will impact all
#' next runs and not a specific site_name/run_name run as in SCOPE.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @return a table with information about STEMMUS current Soil Constants inputs
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(check_STEMMUS_SoilConstants(), align = c("l","c"))
#' }
#'
#' @export
#'
check_STEMMUS_SoilConstants <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/"

){

  checkSoilConstants <- utils::read.table(paste0(patch,"src/+io/checkSoilConstants.m"), sep="|")

  checkSoilConstants$V1[-1] |>
    stringr::str_remove(pattern = "    SoilConstants.") |> stringr::str_remove(pattern = ";") |>
    stringr::str_subset(pattern = " = ") |> tibble::as_tibble() |>
    tidyr::separate_wider_delim("value", " = ", names = c("name", "value")) -> SoilConstants

  return(SoilConstants)

}


#' to check the current STEMMUS Model constants from the define file
#'
#' @description
#' `check_STEMMUS_DefineConstants` present current model defined Constants inputs for STEMMUS
#'
#' @details
#' This function shows current STEMMUS model defined constants inputs. If not changes were done
#' the options are the defaults @seealso [info_STEMMUS_DefineConstants()].
#' **important** differently from SCOPE constant parameters any change in the settings will impact all
#' next runs and not a specific site_name/run_name run as in SCOPE. These constant are different from the
#' soil constant [info_STEMMUS_SoilConstants()].
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @return a table with information about STEMMUS current defined constants inputs
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(check_STEMMUS_DefineConstants(), align = c("l","c"))
#' }
#'
#' @export
#'
check_STEMMUS_DefineConstants <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/"

){

  checkConstants <- utils::read.table(paste0(patch,"src/+io/define_constants.m"), sep="|")

  checkConstants$V1[-1] |>
    stringr::str_split(pattern = " const.") |> unlist() |>
    stringr::str_split(pattern = ";") |> unlist() |>
    stringr::str_subset(pattern = " = ") |>
    tibble::as_tibble() |>
    tidyr::separate_wider_delim("value", " = ", names = c("name", "value")) -> Constants

  return(Constants)

}

#' to check the current STEMMUS Model soil initial
#'
#' @description
#' `check_STEMMUS_SoilInitials` present current model soil initial inputs for STEMMUS
#'
#' @details
#' This function shows current STEMMUS model soil initial temperature and water content inputs in
#' different depths. These constants for the first timestamps are required to run the model @seealso [get_SoilInitials()].
#' **important** the soil initial values are passed by the function @seealso [input_constants()]
#' for each run.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run. The last can be used to name runs with different model parameters or settings,
#' @return a table with information about STEMMUS current soil initial inputs
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(check_STEMMUS_SoilInitials(site_name ="DE-Hai",
#' run_name = "ECdata_36")[[1]], align = c("l","c"))
#' formattable::formattable(check_STEMMUS_SoilInitials(site_name ="DE-Hai",
#' run_name = "ECdata_36")[[2]], align = c("l","c"))
#' }
#'
#' @export
#'
check_STEMMUS_SoilInitials <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA
){

soil_init <- rhdf5::H5Fopen(paste0(patch, "runs/", site_name, "_", run_name, "/","soil_init.mat"))

initials <- list(
  "Soil_Temperature [degree C]" = tibble::tibble(
    "names" = c("Tss", "InitT0", "InitT1", "InitT2", "InitT3", "InitT4", "InitT5", "InitT6"),
    "values" = round(c(soil_init$Tss[1], soil_init$InitT0[1], soil_init$InitT1[1], soil_init$InitT2[1],
                 soil_init$InitT3[1], soil_init$InitT4[1], soil_init$InitT5[1], soil_init$InitT6[1]),2)),
  "Soil_Water_Content [m3 m-3]" =  tibble::tibble(
    "names" = c("InitX0", "InitX1", "InitX2", "InitX3", "InitX4", "InitX5", "InitX6", "BtmX"),
    "values" = round(c(soil_init$InitX0[1], soil_init$InitX1[1], soil_init$InitX2[1], soil_init$InitX3[1],
                 soil_init$InitX4[1], soil_init$InitX5[1], soil_init$InitX6[1], soil_init$BtmX[1]),2)))

rhdf5::h5closeAll()

return(initials)

}

#' to check the current STEMMUS Model soil properties
#'
#' @description
#' `check_STEMMUS_SoilProperties` present current model soil properties inputs for STEMMUS
#'
#' @details
#' This function shows current STEMMUS model soil properties inputs in different depths.
#' These constants are required to run the model @seealso [get_SoilProperties()].
#' **important** the soil initial values are passed by the function @seealso [input_constants()]
#' for each run.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run. The last can be used to
#' name runs with different model parameters or settings,
#' @return a table with information about STEMMUS current soil properties inputs
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(check_STEMMUS_SoilProperties(site_name ="DE-Hai",
#' run_name = "ECdata_36"), align = c("l","c","c","c","c","c","c","l"))
#' }
#'
#' @export
#'
check_STEMMUS_SoilProperties <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA
){

  soil_properties <- rhdf5::H5Fopen(paste0(patch, "runs/", site_name, "_", run_name, "/","soil_parameters.mat"))

  properties <- tibble::tibble(
      "names" = c("Clay Fraction",
                  "Sandy Fraction",
                  "Organic (Carbon) Fraction ",
                  "Porosity",
                  "Saturated SWC",
                  "theta_s0",
                  "Field Capacity",
                  "Residual SWC",
                  "Coefficient n",
                  "Coefficient lambda",
                  "Coefficient alpha",
                  "Saturated hydraulic conductivity",
                  "Ks0",
                  "Fmax"),
      "Layer_1" = c(round(soil_properties$FOC[1:6],2)[[1]],
                    round(soil_properties$FOS[1:6],2)[[1]],
                    round(soil_properties$MSOC[1:6],2)[[1]],
                    round(soil_properties$porosity[1:6],2)[[1]],
                    round(soil_properties$SaturatedMC[1:6],7)[[1]],
                    round(soil_properties$theta_s0[1],2)[[1]],
                    round(soil_properties$fieldMC[1:6],2)[[1]],
                    round(soil_properties$ResidualMC[1:6],4)[[1]],
                    round(soil_properties$Coefficient_n[1:6],2)[[1]],
                    round(soil_properties$Coef_Lamda[1:6],3)[[1]],
                    round(soil_properties$Coefficient_Alpha[1:6],4)[[1]],
                    round(soil_properties$SaturatedK[1:6],5)[[1]],
                    round(soil_properties$Ks0[1],2)[[1]],
                    round(soil_properties$fmax[1],2)[[1]]),
      "Layer_2" = c(round(soil_properties$FOC[1:6],2)[[2]],
                    round(soil_properties$FOS[1:6],2)[[2]],
                    round(soil_properties$MSOC[1:6],2)[[2]],
                    round(soil_properties$porosity[1:6],2)[[2]],
                    round(soil_properties$SaturatedMC[1:6],7)[[2]],
                    NA,
                    round(soil_properties$fieldMC[1:6],2)[[2]],
                    round(soil_properties$ResidualMC[1:6],4)[[2]],
                    round(soil_properties$Coefficient_n[1:6],2)[[2]],
                    round(soil_properties$Coef_Lamda[1:6],3)[[2]],
                    round(soil_properties$Coefficient_Alpha[1:6],4)[[2]],
                    round(soil_properties$SaturatedK[1:6],5)[[2]],
                    NA,
                    NA),
      "Layer_3" = c(round(soil_properties$FOC[1:6],2)[[3]],
                    round(soil_properties$FOS[1:6],2)[[3]],
                    round(soil_properties$MSOC[1:6],2)[[3]],
                    round(soil_properties$porosity[1:6],2)[[3]],
                    round(soil_properties$SaturatedMC[1:6],7)[[3]],
                    NA,
                    round(soil_properties$fieldMC[1:6],2)[[3]],
                    round(soil_properties$ResidualMC[1:6],4)[[3]],
                    round(soil_properties$Coefficient_n[1:6],2)[[3]],
                    round(soil_properties$Coef_Lamda[1:6],3)[[3]],
                    round(soil_properties$Coefficient_Alpha[1:6],4)[[3]],
                    round(soil_properties$SaturatedK[1:6],5)[[3]],
                    NA,
                    NA),
      "Layer_4" = c(round(soil_properties$FOC[1:6],2)[[4]],
                    round(soil_properties$FOS[1:6],2)[[4]],
                    round(soil_properties$MSOC[1:6],2)[[4]],
                    round(soil_properties$porosity[1:6],2)[[4]],
                    round(soil_properties$SaturatedMC[1:6],7)[[4]],
                    NA,
                    round(soil_properties$fieldMC[1:6],2)[[4]],
                    round(soil_properties$ResidualMC[1:6],4)[[4]],
                    round(soil_properties$Coefficient_n[1:6],2)[[4]],
                    round(soil_properties$Coef_Lamda[1:6],3)[[4]],
                    round(soil_properties$Coefficient_Alpha[1:6],4)[[4]],
                    round(soil_properties$SaturatedK[1:6],5)[[4]],
                    NA,
                    NA),
      "Layer_5" = c(round(soil_properties$FOC[1:6],2)[[5]],
                    round(soil_properties$FOS[1:6],2)[[5]],
                    round(soil_properties$MSOC[1:6],2)[[5]],
                    round(soil_properties$porosity[1:6],2)[[5]],
                    round(soil_properties$SaturatedMC[1:6],7)[[5]],
                    NA,
                    round(soil_properties$fieldMC[1:6],2)[[5]],
                    round(soil_properties$ResidualMC[1:6],4)[[5]],
                    round(soil_properties$Coefficient_n[1:6],2)[[5]],
                    round(soil_properties$Coef_Lamda[1:6],3)[[5]],
                    round(soil_properties$Coefficient_Alpha[1:6],4)[[5]],
                    round(soil_properties$SaturatedK[1:6],5)[[5]],
                    NA,
                    NA),
      "Layer_6" = c(round(soil_properties$FOC[1:6],2)[[6]],
                    round(soil_properties$FOS[1:6],2)[[6]],
                    round(soil_properties$MSOC[1:6],2)[[6]],
                    round(soil_properties$porosity[1:6],2)[[6]],
                    round(soil_properties$SaturatedMC[1:6],7)[[6]],
                    NA,
                    round(soil_properties$fieldMC[1:6],2)[[6]],
                    round(soil_properties$ResidualMC[1:6],4)[[6]],
                    round(soil_properties$Coefficient_n[1:6],2)[[6]],
                    round(soil_properties$Coef_Lamda[1:6],3)[[6]],
                    round(soil_properties$Coefficient_Alpha[1:6],4)[[6]],
                    round(soil_properties$SaturatedK[1:6],5)[[6]],
                    NA,
                    NA),
      "units" = c("fraction (/100)",
                  "fraction (/100)",
                  "fraction (/10000)",
                  "[m3 m-3]",
                  "[m3 m-3]",
                  "[m3 m-3]",
                  "[m3 m-3]",
                  "[m3 m-3]",
                  "[-]",
                  "[-]",
                  "[-]",
                  "[cm d-1]",
                  "[cm s-1]",
                  "[-]"))

  rhdf5::h5closeAll()

  return(properties)

}


#' to check the current STEMMUS Model global forcing data
#'
#' @description
#' `check_STEMMUS_ForcingGlobal` present current model global forcing data inputs for STEMMUS
#'
#' @details
#' This function shows current STEMMUS model global forcing data inputs.
#' **important** This global information is required to run the model and the global forcing data
#' are passed by the function @seealso [input_constants()] for each run.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run. The last can be used to
#' name runs with different model parameters or settings,
#' @return a table with information about STEMMUS current global forcing data inputs
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(check_STEMMUS_ForcingGlobal(site_name ="DE-Hai",
#' run_name = "ECdata_36"), align = c("l","c","c"))
#' }
#'
#' @export
#'
check_STEMMUS_ForcingGlobal <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA
){

  forcing_globals <- rhdf5::H5Fopen(paste0(patch, "runs/", site_name, "_", run_name, "/","forcing_globals.mat"))

  properties <- tibble::tibble(
    "names" = c("Site Name", "Latitude", "Longitude", "Altitude",
                "Timestep size in seconds", "Number of timestamps",
                "IGBP vegetation class", "Canopy Height", "Measurement Height"),

    "values" = c(intToUtf8(forcing_globals$sitename[1:6]),
                 forcing_globals$latitude[1],
                 forcing_globals$longitude[1],
                 forcing_globals$elevation[1],
                 forcing_globals$DELT[1],
                 forcing_globals$Dur_tot[1],
                 intToUtf8(forcing_globals$IGBP_veg_long[,1:200]),
                 forcing_globals$canopy_height[1],
                 forcing_globals$reference_height[1]),

  "units" = c("[-]", "degree","degree", "[m]", "[Int]", "[sec]", "[-]", "[m]", "[m]"))

  rhdf5::h5closeAll()

  return(properties)
}

