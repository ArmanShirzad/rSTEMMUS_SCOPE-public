#' to set all time series model inputs for a location
#'
#' @description
#' `input_timeseries` set all time series parameters required to run the model.
#'
#' @details
#' This is a function to prepare all time series input parameters to run the model.
#' **important** @seealso [info_SCOPE_README()] to more information about which inputs are required or optional,
#' also the units must be used.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default ```"D:/model/rSTEMMUS_SCOPE/"```,
#' @param site_name,run_name the name of the location and the name of run. The last can be used to name runs with different model parameters or settings,
#' @param data_frame if all data input are into one data.frame with column names (t_, Ta_, RH_, u_, p_, rain_, Rin_, Rli_, LAI_, CO2_, ea_)
#' @param t_file required
#' @param year_file required
#' @param Ta_file required
#' @param RH_file required
#' @param ea_file required
#' @param VPD_file required
#' @param Rin_file required
#' @param Rli_file required
#' @param p_file required
#' @param u_file required
#' @param CO2_file optional
#' @param rain_file required
#' @param z_file optional
#' @param tts_file optional
#' @param LAI_file optional, but very important
#' @param hc_file optional
#' @param Vcmax_file optional
#' @param Cab_file optional
#' @param LIDF_file optional
#' @return returns all files with static from STEMMUS and SCOPE will be write in the folder input/site_name_run_name_time
#' @family set input parameters
#'
#' @examples
#' \dontrun{
#' input_timeseries(patch = "D:/model/rSTEMMUS_SCOPE/",
#'               site_name = "DE-HoH",
#'               run_name = "ECdata_01",
#'               t_file =	ts_DWD$t_,
#'               year_file	= year(ts_DWD$timestamp),
#'               Rin_file	= ts_DWD$Rin_sun,
#'               Rli_file	= ts_DWD$Rli_,
#'               p_file	= ts_DWD$p_,
#'               Ta_file =	ts_DWD$Ta_,
#'               RH_file = ts_DWD$RH_,
#'               ea_file =	ts_DWD$ea_,
#'               u_file	= ts_DWD$u_,
#'               rain_file = ts_DWD$rain_/36000,
#'               VPD_file = ts_DWD$VPD_,
#'               tts_file	= tts_calc,             # optional
#'               CO2_file	= DE_ICOS$CO2_,         # optional
#'               LAI_file =	LAI500_Modis$LAI)
#' }
#'
#' @export
#'
input_timeseries <- function(patch = "D:/model/rSTEMMUS_SCOPE/",
                      site_name = NA,
                      run_name = NULL,
                      data_frame = NULL, # if all data input is into one data.frame with column names (t_, Ta_, RH_, u_, p_, rain_, Rin_, Rli_, LAI_, CO2_, ea_)
                      t_file =	NULL,
                      year_file	= NULL,
                      Ta_file =	NULL,
                      RH_file = NULL,
                      ea_file =	NULL,
                      VPD_file = NULL,
                      Rin_file	= NULL,
                      Rli_file	= NULL,
                      p_file	= NULL,
                      u_file	= NULL,
                      CO2_file	= NULL,
                      rain_file = NULL,
                      z_file	= NULL,
                      tts_file	= NULL,
                      LAI_file =	NULL,
                      hc_file	= NULL,
                      Vcmax_file	= NULL,
                      Cab_file	= NULL,
                      LIDF_file = NULL
){


  if(missing(data_frame)){

  argumants <- data.frame(
    "arg" = c("t_file","year_file","Rin_file","Rli_file","p_file","Ta_file","ea_file","u_file","CO2_file","z_file"
              ,"tts_file","LAI_file","hc_file","Vcmax_file","Cab_file","LIDF_file","RH_file","VPD_file", "rain_file"),
    "valid" = c(!is.null(t_file), !is.null(year_file), !is.null(Rin_file), !is.null(Rli_file), !is.null(p_file),
                !is.null(Ta_file), !is.null(ea_file), !is.null(u_file), !is.null(CO2_file), !is.null(z_file),
                !is.null(tts_file), !is.null(LAI_file), !is.null(hc_file), !is.null(Vcmax_file),
                !is.null(Cab_file), !is.null(LIDF_file), !is.null(RH_file), !is.null(VPD_file), !is.null(rain_file)),
    "vector"= c("t_","year_","Rin_","Rli_","p_","Ta_","ea_","u_","CO2_","z_",
                "tts_","LAI_","hc_","Vcmax_","Cab_","LIDF_","RH_","vpd_", "rain_"),
    "xls_content" = c(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0),
    "position_xls"= c(10,11,12,13,14,15,16,17,20,21,22,25,26,28,29,32,NA,NA,NA),
    "Mdata_content" = c(1, 0,1,1,1,1, 0,1, 0, 0, 0, 1, 0, 0, 0, 0,1,1,1),
    "position_Mdata"= c(1,NA,7,8,5,2,NA,4,NA,NA,NA,10,NA,NA,NA,NA,3,9,6),
    "file" = c("t_.dat","year_.dat","Rin_.dat","Rli_.dat","p_.dat","Ta_.dat","ea_.dat","u_.dat","CO2_.dat","z_.dat",
               "tts_.dat","LAI_.dat","hc_.dat","Vcmax_.dat","Cab_.dat","LIDF_.dat","RH_.dat","vpd_.dat","rain_.dat"))

  argumants_T <- argumants[argumants$valid == "TRUE",]
  argumants_xls <- argumants[argumants$valid == "TRUE" & argumants$xls_content == 1,]
  argumants_Mdata <- argumants[argumants$valid == "TRUE" & argumants$Mdata_content == 1,]

  argumants_F <- argumants[argumants$valid == "FALSE" & argumants$Mdata_content == 1,]

  if(sum(argumants_Mdata$Mdata_content) < 10){

    print("the required input(s) below are missing")
    return(print(argumants_F))

    } else {

    print("all required inputs arrived")

  }

  vars_Mdata <- sapply(argumants_Mdata$arg, function(x) {
    data.frame(get(as.name(x))) })

  Mdata_df <- data.frame(rep(as.character(""),length(vars_Mdata$t_file.get.as.name.x..)),
                         round(vars_Mdata$t_file.get.as.name.x.., 3),
                         round(vars_Mdata$Ta_file.get.as.name.x.., 2),
                         round(vars_Mdata$RH_file.get.as.name.x.., 2),
                         round(vars_Mdata$u_file.get.as.name.x.., 2),
                         round(vars_Mdata$p_file.get.as.name.x.., 2),
                         round(vars_Mdata$rain_file.get.as.name.x.., 7),
                         round(vars_Mdata$Rin_file.get.as.name.x.., 2),
                         round(vars_Mdata$Rli_file.get.as.name.x.., 2),
                         round(vars_Mdata$VPD_file.get.as.name.x.., 2),
                         round(vars_Mdata$LAI_file.get.as.name.x.., 2))

  names(Mdata_df) <- c("space", argumants_Mdata$vector)

  utils::write.table(format(Mdata_df, nsmall = 8),
              paste0(patch, "runs/", site_name, "_", run_name, "/", "Mdata.txt"),
              row.names = F, col.names = F, quote = FALSE, sep = "   ")

  vars_xls <- lapply(argumants_xls$arg, function(x) {
    data.frame(as.character(""), as.double(get(as.name(x)))) })

  names(vars_xls) <- c(argumants_xls$vector)

    for (i in 1:length(argumants_xls$arg)) {

    utils::write.table(format(vars_xls[[i]], nsmall = 8),
                paste0(patch, "runs/", site_name, "_", run_name, "/", argumants_xls$file[i]),
                row.names = F, col.names = F, quote = FALSE, sep = "   ")
  }

  input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

  for (i in 1:length(argumants_xls$arg)) {

       input_data[[3]]$files[argumants_xls[i,5]] <- argumants_xls[i,8]
  }

  rio::export(input_data, paste0(patch, "runs/", site_name, "_", run_name, "/", "input_data.xlsx"), col.names = FALSE)

  LAI_dat <- data.frame(as.character(""), round(t_file,7), round(LAI_file,2))
  utils::write.table(format(LAI_dat, nsmall = 8), paste0(patch, "runs/", site_name, "_", run_name, "/", "LAI_.dat"),
                     row.names = F, col.names = F, quote = FALSE, sep = "   ")

  if(!is.null(hc_file) == TRUE) {
    utils::write.table(format(cbind(as.character(""),t_file, hc_file), nsmall = 8),
                paste0(patch, "runs/", site_name, "_", run_name, "/", "hc_.dat"),
                row.names = F, col.names = F, quote = FALSE, sep = "   ")
  } else {
    print("no hc")
}


}else{

  names <- names(data_frame)

  if(length(unique(is.element(c("t_", "Ta_", "RH_", "u_", "p_", "rain_", "Rin_", "Rli_", "VPD_", "LAI_"),
                              names))) > 1){

    print("the required input(s) below are missing")

    return(c("t_", "Ta_", "RH_", "u_", "p_", "rain_", "Rin_", "Rli_", "VPD_",
             "LAI_")[is.element(c("t_", "Ta_", "RH_", "u_", "p_", "rain_", "Rin_",
                                  "Rli_", "VPD_", "LAI_"), names) == FALSE])

  } else {

    print("all required inputs arrived")

  }

  for (i in 1:length(names)) {

    df <- data.frame(as.character(""), data_frame[names[i]])

    utils::write.table(format(df, nsmall = 8),
                paste0(patch, "runs/", site_name, "_", run_name, "/", names[i], ".dat"),
                row.names = F, col.names = F, quote = FALSE, sep = "   ")
     }

  LAI_dat <- data.frame(as.character(""), data_frame$t_, data_frame$LAI_)
  utils::write.table(format(LAI_dat, nsmall = 8),
              paste0(patch, "runs/", site_name, "_", run_name, "/", "LAI_.dat"),
              row.names = F, col.names = F, quote = FALSE, sep = "   ")

  if(!is.null(data_frame$hc_) == TRUE) {
    utils::write.table(format(cbind(as.character(""), data_frame$t_, data_frame$hc_), nsmall = 8),
                paste0(patch, "runs/", site_name, "_", run_name, "/", "hc_.dat"),
                row.names = F, col.names = F, quote = FALSE, sep = "   ")
  } else {
    print("no hc")
  }

  Mdata <- data_frame[c("t_", "Ta_", "RH_", "u_", "p_", "rain_", "Rin_", "Rli_", "VPD_", "LAI_")]
  Mdata <- data.frame(as.character(""), Mdata)
  #
  utils::write.table(format(Mdata, nsmall = 8),
              paste0(patch, "runs/", site_name, "_", run_name, "/", "Mdata.txt"),
              row.names = F, col.names = F, quote = FALSE, sep = "   ")

  # include the input names .dat in the xls filenames spreadsheet ----
  input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

  names <- as.vector.data.frame(paste0(names(data_frame),".dat"))
  names(names) <- names(data_frame)
  input_data[[3]]$files[10:32] <- c(names["t_"],names["year_"],names["Rin_"],names["Rli_"],names["p_"],names["Ta_"],names["ea_"],names["u_"],
                                    NA,NA,names["CO2_"],names["z_"],names["tts_"],NA,NA,names["LAI_"],names["hc_"],
                                    NA,names["Vcmax_"],names["Cab_"],NA,NA,names["LIDF_"])

  rio::export(input_data, paste0(patch, "runs/", site_name, "_", run_name, "/", "input_data.xlsx"), col.names = FALSE)

  }


  return(print(paste0("The inputs were created inside the folder ", site_name, "_", run_name, " at runs/")))

}
