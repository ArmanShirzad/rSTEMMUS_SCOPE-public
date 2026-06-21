#' information about the SCOPE inputs
#'
#' @description
#' `info_SCOPE_README` present the information about the SCOPE parameters from the readME spreadsheet of the input_data.xlsx file
#'
#' @details
#' This is a function show examples of typical input values ranges, parameters units, sensitivity of some
#' parameters per IBGP landcover class, among other information.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default ```"D:/model/rSTEMMUS_SCOPE/"```,
#' @param site_name,run_name the name of the location and the name of run. The last can be used to name runs with different model parameters or settings,
#' @return a table with information about SCOPE parameters
#' @family information about parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' info_SCOPE_README(site_name = "DE-Hai", run_name = "ECdata_36")
#'
#' formattable::formattable(info_SCOPE_README(site_name = "DE-Hai",
#'                          run_name = "ECdata_36")[[1]], align = c("l","l"))
#'
#' formattable::formattable(info_SCOPE_README(site_name = "DE-Hai", run_name = "ECdata_36")[[2]],
#'                          align = c("l","c","c"), caption = "Table1. Example of LIDF values")
#'
#' formattable::formattable(info_SCOPE_README(site_name = "DE-Hai", run_name = "ECdata_36")[[3]],
#' align = c("l","c","r","r","r","r","r","c","r","r"),
#' caption = "Table2. Examples of biochemical parameters for the model biochemical.m
#' Calibrated temperature sensitivity parameters for Vcmax and Resp")
#'
#' formattable::formattable(info_SCOPE_README(site_name = "DE-Hai", run_name = "ECdata_36")[[4]],
#' align = c("l","c","c","r","r","r"), caption = "Table3. Typical ranges of input values")
#' }
#'
#' @export
#'
info_SCOPE_README <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA
){

  input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

  SCOPE_readme <- input_data[[1]][1:95,c(1:10)]
  SCOPE_readme[is.na(SCOPE_readme)] <- ""

  read_list <- list()

  read_list[[1]] <- SCOPE_readme[3:10,1:2]
  row.names(read_list[[1]]) <- NULL

  read_list[[2]] <- SCOPE_readme[55:61,c(1,2,3)]
  row.names(read_list[[2]]) <- NULL
  names(read_list[[2]]) <- SCOPE_readme[54,1:3]

  read_list[[3]] <- SCOPE_readme[68:80,1:10]
  row.names(read_list[[3]]) <- NULL
  names(read_list[[3]]) <- SCOPE_readme[67,1:10]

  read_list[[4]] <- SCOPE_readme[85:95,1:6]
  row.names(read_list[[4]]) <- NULL
  names(read_list[[4]]) <- SCOPE_readme[84,1:6]

  return(read_list)

}


#' information about the SCOPE options
#'
#' @description
#' `info_SCOPE_options` present the information about the SCOPE model options from the input_data.xlsx file
#'
#' @details
#' This is function shows all SCOPE model options, values and default settings.
#' The function has no arguments, just need to run info_SCOPE_options()
#'
#' @return a table with information about SCOPE options
#' @family information about parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(info_SCOPE_options(), align = c("l","c","c","l"))
#'  }
#'
#' @export
#'
info_SCOPE_options <- function(){

SCOPE_options <-  data.frame(

"settings" = c("calc_ebal",
               "calc_vert_profiles",
               "calc_fluor",
               "calc_planck",
               "calc_directional",
               "calc_xanthophyllabs",
               "calc_PSI",
               "rt_thermal",
               "calc_zo",
               "soilspectrum",
               "soil_heat_method",
               "Fluorescence_model",
               "calc_rss_rbs",
               "apply_T_corr",
               "verify",
               "save_headers",
               "makeplots",
               "simulation"),

"default" = c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,1,1),

"range" = c("[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]",
            "[0,1,2]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1,2]"),

"description" = c("1 calculates the complete energy balance, otherwise 0",
                  "1 calculates vertical profiles of fluxes and temperatures, otherwise 0",
                  "1 calculates chlorophyll fluorescence, otherwise 0",
                  "1 calculates spectrum of thermal radiation with spectral emissivity instead of broadband, otherwise 0",
                  "1 calculates BRDF and directional temperature for many angles specified in a file. Be patient, this takes some time, otherwise 0",
                  "1 calculates dynamic xanthopyll absorption (zeaxanthin), for simulating PRI, otherwise 0",
                  "0 (recommended) treat the whole fluorescence spectrum as one spectrum (new calibrated optipar), if 1 differentiate PSI and PSII with Franck et al. spectra (of SCOPE 1.62 and older)",
                  "0 provides emissivity values as input and 1 uses values from fluspect and soil at 2400 nm for the TIR range",
                  "0 uses the zo and d values provided in the inputdata and 1 calculate zo and d from the LAI, canopy height, CD1, CR, CSSOIL (recommended if LAI changes in time series)",
                  "0 uses soil spectrum from a file and 1 simulate soil spectrum with the BSM model",
                  "0 uses standard calculation of thermal inertia from soil characteristics, 1 empiricaly calibrated formula (make function) and 2 as constant fraction of soil net radiation",
                  "0 uses empirical, with sustained NPQ (fit to Flexas' data) and 1 empirical, with sigmoid for Kn; 2: Magnani 2012 model",
                  "0 uses resistance rss and rbs as provided in inputdata and 1 calculate rss from soil moisture content and correct rbs for LAI (calc_rssrbs.m)",
                  "1 correct Vcmax and rate constants for temperature in biochemical.m, otherwise 0",
                  "1 verifiy the results (compare to saved 'standard' output) to test the code for the first time, otherwise 0",
                  "1 write header lines in output files, otherwise 0",
                  "1 plot the results, otherwise 0",
                  "0 individual runs. Specify one value for constant input, and an equal number (>1) of values for all input that varies between the runs,
                  1 time series (uses text files with meteo input as time series and 2 a Lookup_Table specify the values to be included (all possible combinations of inputs will be used)"
                     ))

return(SCOPE_options)

}


#' information about time series input files
#'
#' @description
#' `info_SCOPE_tsInputs` present information about the SCOPE timeseries data informed at input_data.xlsx file
#'
#' @details
#' This is function shows all time series data used in the SCOPE and which ones are
#' currently being used by the model
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run. The last can be used to name runs with different model parameters or settings,
#' @return a table with information about SCOPE time series inputs
#' @family information about parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' info_SCOPE_ts_Inputs(site_name = "DE-Hai", run_name = "ECdata_36")
#'
#' formattable(info_SCOPE_ts_Inputs(site_name = "DE-Hai", run_name = "ECdata_36"), align = c("l","l"))
#' }
#'
#' @export
#'
info_SCOPE_tsInputs <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA
){
  input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

  readme_descr <- input_data[[1]][16:45,c(1,3)]
  row.names(readme_descr) <- NULL
  names(readme_descr) <- c("file_name", "description")
  readme_descr <- dplyr::filter(readme_descr, !is.na("description"))
  readme_descr[is.na(readme_descr)] <- ""

  SCOPE_ts_inputs <- input_data[[3]][3:33, c(1,2)]
  SCOPE_ts_inputs <- dplyr::filter(SCOPE_ts_inputs, !is.na("files"))

  row.names(SCOPE_ts_inputs) <- NULL

  return(readme_descr)

}


#' information about the STEMMUS Model Settings and Options
#'
#' @description
#' `info_STEMMUS_ModelSettings` present the information about the STEMMUS model settings/options
#'
#' @details
#' This is function shows STEMMUS model settings/options, default values, units and description.
#' The function has no arguments, just need to run info_STEMMUS_ModelSettings()
#'
#' @return a table with information about STEMMUS settings
#' @family information about parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(info_STEMMUS_ModelSettings(), align = c("l","c","c","l"))
#' }
#'
#' @export
#'
info_STEMMUS_ModelSettings <- function(){

ModelSettings <- data.frame(
  "settings" = c("R_depth", "J", "SWCC", "Hystrs", "Thmrlefc", "Soilairefc", "hThmrl", "W_Chg",
                      "ThmrlCondCap", "ThermCond", "SSUR", "fc", "Tr", "T0",
                      "rwuef", "rroot", "SFCC", "Tot_Depth", "Eqlspace", "NS", "NIT", "KT", "NL"),

  "default" = c("350", "1", "1", "0", "1", "0", "1", "1", "1", "1", "10^2", "0.02", "20", "273.15",
                 "1", "1.5*1e-3", "1", "500", "0", "1", "30", "0", "100"),

  "units" = c("[cm]", "[-]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[0,1]","[1,2,2,4]",
              "[cm-1]","[?]","[degree C]","[k]", "[-]","[-]","[-]",
              "[cm]", "[0,1]", "[n] types", "[n] interactions", "[n] steps", "[n] elements"),

  "description" = c("rootzone depth",
                    "index of soil type for choosing soil physical parameters",
                    "soil water characteristic curve, 0 for Clapp and Hornberger and 1 for Van Gen",
                    "considers hysteresis if the value is 1, otherwise 0",
                    "considers the isothermal water flow if the value is 0, otherwise 1",
                    "considers dry air transport if the value is 1, otherwise 0",
                    "a special calculation of water capacity is used if the value is 1, otherwise 0",
                    "calculates the heat of wetting by Millys method if 0 and by Lyle Pruntys method if 1",
                    "Millys effective thermal capacity and conductivity formulation to verify the vapor and heat transport in extremly dry soil",
                    "effective thermal conductivity methods, 1 for De Vries, 2 for Jonhansen, 3 for simplified De Vries (Tian 2016) or 4 for Farouki",
                    "surface area, for loam 10^5 or for sand 10^2 (cm^-1)",
                    "fraction of clay, for loam 0.036; for sand 0.02",
                    "reference temperature, Tr",
                    "reference temperature, T0",
                    "other settings, rwuef",
                    "other settings, rroot",
                    "other settings, SFCC",
                    "other settings, Tot_Depth [cm], it should be usually bigger than 0.5m",
                    "the space step equal or not, for 0 the DeltZ would be reset in 50cm by hand",
                    "number of soil types",
                    "time and domain information setting, desirable number of iterations in a time step",
                    "time and domain information setting, number of time steps",
                    "determination of NL, the number of elements"
                    ))

return(ModelSettings)

}


#' information about the STEMMUS Soil Constants
#'
#' @description
#' `info_STEMMUS_SoilConstants` present the information about the STEMMUS Soil Constants
#'
#' @details
#' This is function shows STEMMUS model Soil Constants, units, default values and description.
#' The function has no arguments, just need to run info_STEMMUS_SoilConstants()
#'
#' @return a table with information about STEMMUS Soil Constants
#' @family information about parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(info_STEMMUS_SoilConstants(), align = c("l","c","c","l"))
#' }
#'
#' @export
#'
info_STEMMUS_SoilConstants <- function(){

SoilConstants <- data.frame(
  "soil_constants" = c("hd", "hm", "CHST", "Elmn_Lnth", "Dmark", "Phi_S", "Phi_soc", "Lamda_soc", "Theta_soc", "XK"),

  "default" = c("-1e7", "-9899", "0", "0", "0", "[-17.9 -17 -17 -19 -10 -10]", "-0.0103", "2.7", "0.6", "0.025"),

  "units" = c("[-]", "[-]", "[-]", "[-]", "[-]", "[-]", "[-]", "[-]", "[-]", "[-]"),

  "description" =c("getSoilConstants", "getSoilConstants", "getSoilConstants", "getSoilConstants",
                  "getSoilConstants", "getSoilConstants", "getSoilConstants", "getSoilConstants", "getSoilConstants",
                  "XK=0.11 for silt loam and XK = 0.025 for sand, the SoilConstants.XK is used in updateSoilVariables"))

return(SoilConstants)

}


#' information about the STEMMUS define constants file
#'
#' @description
#' `info_STEMMUS_DefineConstants` present the information about the STEMMUS define constants
#'
#' @details
#' This is function shows some STEMMUS model constants and their default values.
#' The function has no arguments, just need to run info_STEMMUS_DefineConstants()
#'
#' @return a table with information about some STEMMUS constants
#' @family information about parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(info_STEMMUS_DefineConstants(), align = c("l","c","c","l"))
#' }
#'
#' @export
#'
info_STEMMUS_DefineConstants <- function(){

define_constants <- data.frame(

    "model_constants" = c("A", "h", "c", "cp", "cp_specific", "R", "R_specific",
                         "rhoa", "kappa", "MH2O", "Mair", "MCO2", "sigmaSB", "deg2rad",
                         "C2K", "CKTN", "l", "g", "RHOL", "RHOI", "Rv", "RDA", "RHO_bulk",
                         "Hc", "GWT", "MU_a", "Gamma0", "Gamma_w", "Lambda1", "Lambda2", "Lambda3", "MU_W0",
                         "MU1", "b", "W0", "c_L", "c_V", "c_a", "c_i", "lambdav", "k"),

    "default" = c("6.02214E23","6.6262E-34","299792458","1004","1.013E-3","8.314","0.287",
                  "1.2047", "0.4", "18", "28.96", "44", "5.67E-8", "pi / 180",
                  "273.15", "(50 + 2.575*20)","0.5","981","1","0.92","461.5*1e4","287.1*1e4","1.25",
                  "0.02","7","1.846*10^(-4)","71.89","const.RHOL*const.g","0.228/100","-2.406/100","4.909/100","2.4152*10^(-4)",
                  "4742.8","4*10^(-6)","1.001*10^3","4.186","1.870","1.005","2.0455","2.45","0.41"),

    "units" = c("[mol-1]", "[J s]", "[m s-1]", "[J kg-1 K-1]", "[MJ.kg-1.C-1]", "[J mol-1K-1]", "[kJ.kg-1.K-1]",
                "[kg m-3]", "[-]", "[g mol-1]", "[g mol-1]", "[g mol-1]", "[W m-2 K-4]", "[rad]",
                "[K]", "[-]", "[-]", "[cm s-2]", "[g cm-3]", "[g cm-3]", "[cm2 s-2 Cels-1]", "[cm2 s-2 Cels-1]", "[g cm-3]",
                "[-]", "[-]", "[g cm-1 s-1]", "[g s-2]", "[g cm-2 s-2]", "[-]", "[W m-1 Cels-1] (1 W.s=J)", "[-]", "[g cm-1 s-1]",
                "[J mol-1]", "[cm]", "[-]", "[J/g-1/Cels-1]", "[J/g-1/Cels-1]", "[J/g-1/Cels-1]", "[J/g-1/Cels-1]",
                "[MJ.kg-1]", "[-]"),

    "description" =c("Constant of Avogadro", "Plancks constant", "Speed of light", "Specific heat of dry air",
                    "specific heat at cte pressure FAO56 p26 box6", "Molar gas constant", "specific gas FAO56 p26 box6",
                    "Specific mass of air", "Von Karman constant", "Molecular mass of water", "Molecular mass of dry air",
                    "Molecular mass of carbon dioxide", "Stefan Boltzman constant", "Conversion from deg to rad",
                    "Melting point of water", "Constant used in calculating viscosity factor for hydraulic conductivity",
                    "Coefficient in VG mode", "Gravity acceleration", "Water density", "Ice density",
                    "Gas constant for vapor (original J.kg^-1.Cels^-1)","Gas constant for dry air (original J.kg^-1.Cels^-1)",
                    "Bulk density of sand", "Henry's constant",
                    "The gain factor(dimensionless),which assesses the temperature % dependence of the soil water retention curve is set as 7 for % sand (Noborio et al, 1996)",
                    "Viscosity of air (original 1.846*10^(-5)kg.m^-1.s^-1)", "The surface tension of soil water at 25 Cels degree",
                    "Specific weight of water", "Coefficients in thermal conductivity", "From HYDRUS1D heat transport parameter (Chung Hortan 1987 WRR)",
                    "NA", "Viscosity of water at reference temperature(original 2.4152*10^(-5)kg.m^-1.s^-1)",
                    "Coefficient for calculating viscosity of water", "Coefficient for calculating viscosity of water",
                    "Coefficient for calculating differential heat of wetting by Milly's method",
                    "Specific heat capacity of liquid water, Notice the original unit is 4186kg^-1",
                    "Specific heat capacity of vapor", "Specific heat capacity of dry air",
                    "Specific heat capacity of ice", "latent heat of evaporation  FAO56 pag 31",
                    "karman's cte FAO 56 Eq4"))

return(define_constants)

}


#' information about the valid bioma classes from IGBP land cover
#'
#' @description
#' `info_IGBP_classes` present the valid landcover classes from IGBP
#'
#' @details
#' Only this LCLU classes are accepted. **important** need to be written exactly like that.
#' The function has no arguments, just need to run info_IGBP_classes()
#'
#' @return a table with the available landcover classes from IGBP
#' @family information about parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' formattable::formattable(info_IGBP_classes(), align = c("l","c","c","l"))
#' }
#'
#' @export
#'
info_IGBP_classes <- function(){

  IGBP_classes <- data.frame("Veg_classes" = c("Evergreen Broadleaf Forest",
                                               "Evergreen Needleleaf Forest",
                                               "Deciduous Broadleaf Forest",
                                               "Deciduous Needleleaf Forest",
                                               "Mixed Forests",
                                               "Permanent Wetlands",
                                               "Grassland",
                                               "Open Shrublands",
                                               "Closed Shrublands",
                                               "Savannas",
                                               "Woody Savannas",
                                               "Croplands"))

  return(IGBP_classes)

}

