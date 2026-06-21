#' to create a input folder with required files to run the model
#'
#' @description
#' `new_run` returns a new folder with the required files to run the model for a location.
#'
#' @details
#' This is a function to prepare input folders and set-up path and files for a new run of STEMMUS_SCOPE/Matlab
#' simulations. The input structure is created in the ```../input/runs/site_name_inputs```.
#'
#' @param patch the path to the STEMMUS_SCOPE downloaded folder, example:```"D:/models/rSTEMMUS_SCOPE/"```.
#' @param StartTime a start datetime to the simulations/initial conditions in this format ```"2023-01-01T01:00"```.
#' @param EndTime a final datetime to end the simulations in the same format ```"2023-05-01T23:00"```.
#' @param site_name,run_name a short name for the site or location of the run.
#' @param output_name the default is the site_name (with _) and the datatime from the ```Sys.time()``` funtion.
#' @return It return a message "done!". it will show the path to the run subfolder were the input data will be saved.
#' @examples
#'
#' \dontrun{
#' new_run(patch = "D:/model/rSTEMMUS_SCOPE/",
#'       StartTime = "2023-06-01T00:00",
#'       EndTime = "2023-11-30T23:00",
#'       site_name = "DE-HoH",
#'       run_name = "ECdata_01",
#'       output_name = format(Sys.time(), "%Y%b%d_%H%M"))
#'
#' site_CRN_names <- c(paste0("DE-C0",1:9), paste0("DE-C",10:19))
#'
#' for (i in 1:19) {
#' new_run(patch = "D:/model/STEMMUS_SCOPE/",
#'            StartTime = "2023-06-01T00:00",
#'            EndTime = "2023-11-30T23:00",
#'            site_name = site_CRN_names[i],
#'            run_name = "DWD_36",
#'            output_name = format(Sys.time(), "%Y%b%d_%H%M"))
#'}
#'}
#'
#' @export
#'
new_run <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    StartTime = NA,
    EndTime = NA,
    site_name = NA,
    run_name = NA,
    output_name = format(Sys.time(), "%Y%b%d_%H%M")

){

  # create the config file with the paths for the input files ----
  config <- c(
    paste0("WorkDir=", patch),
    paste0("directional=", patch,"runs/", site_name, "_", run_name, "/directional/"),
    paste0("fluspect_parameters=", patch,"runs/", site_name, "_", run_name, "/fluspect_parameters/"),
    paste0("leafangles=", patch,"runs/", site_name, "_", run_name, "/leafangles/"),
    paste0("radiationdata=", patch,"runs/", site_name, "_", run_name, "/radiationdata/"),
    paste0("soil_spectrum=", patch,"runs/", site_name, "_", run_name, "/soil_spectrum/"),
    paste0("input_data=", patch,"runs/", site_name, "_", run_name, "/input_data.xlsx"),
    paste0("InitialConditionPath=", patch,"runs/", site_name, "_", run_name, "/"),
    paste0("StartTime=", StartTime),
    paste0("EndTime=", EndTime),
    paste0("InputPath=", patch,"runs/", site_name, "_", run_name, "/"),
    paste0("OutputPath=", patch,"output/", site_name, "_", run_name, output_name, "/")
  )

  # create a directory for the new run in the STEMMUS_SCOPE directory ../input/runs/ ----
  dir.create(paste0(patch,"runs/", site_name, "_", run_name))

  # copy general input files to the new directory ----
  file.copy(from=paste0(patch,"input/directional/"),
            to=paste0(patch,"runs/", site_name, "_", run_name, "/"),
            overwrite = TRUE, recursive = TRUE, copy.mode = TRUE, copy.date = TRUE)

  file.copy(from=paste0(patch,"input/fluspect_parameters/"),
            to=paste0(patch,"runs/", site_name, "_", run_name, "/"),
            overwrite = TRUE, recursive = TRUE, copy.mode = TRUE, copy.date = TRUE)

  file.copy(from=paste0(patch,"input/leafangles/"),
            to=paste0(patch,"runs/", site_name, "_", run_name, "/"),
            overwrite = TRUE, recursive = TRUE, copy.mode = TRUE, copy.date = TRUE)

  file.copy(from=paste0(patch,"input/radiationdata/"),
            to=paste0(patch,"runs/", site_name, "_", run_name, "/"),
            overwrite = TRUE, recursive = TRUE, copy.mode = TRUE, copy.date = TRUE)

  file.copy(from=paste0(patch,"input/soil_spectrum/"),
            to=paste0(patch,"runs/", site_name, "_", run_name, "/"),
            overwrite = TRUE, recursive = TRUE, copy.mode = TRUE, copy.date = TRUE)

  filespatch <- c(paste0(patch,"input/input_files/input_data.xlsx"),
                  paste0(patch,"input/input_files/soil_init.mat"),
                  paste0(patch,"input/input_files/forcing_globals.mat"),
                  paste0(patch,"input/input_files/soil_parameters.mat"),
                  paste0(patch,"input/input_files/getSoilConstants.m"),
                  paste0(patch,"input/input_files/define_constants.m"),
                  paste0(patch,"input/input_files/getModelSettings.m"))

  file.copy(filespatch,
            to=paste0(patch,"runs/", site_name, "_", run_name, "/"),
            overwrite = TRUE, recursive = FALSE, copy.mode = TRUE, copy.date = TRUE)

  # write the config file into the new folder input directory ----
  utils::write.table(config, file = paste0(patch, "runs/", site_name,  "_", run_name, "/",
                     site_name, "_", run_name,"_", "config.txt"),
                     quote = FALSE, col.names = FALSE, row.names = FALSE)

  return(print(paste0("The input folder ", site_name, "_", run_name, " was created in the folder runs.")  ))
}

