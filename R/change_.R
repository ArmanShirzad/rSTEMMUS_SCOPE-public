# SCOPE----

#' to change the current SCOPE options
#'
#' @description
#' `change_SCOPE_options` change current SCOPE model options in the input_data.xlsx file
#'
#' @details
#' This function change current SCOPE model options selected to run, @seealso [info_SCOPE_options()]
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run. The last can be used to name runs with different model parameters or settings,
#' @param calc_ebal,calc_vert_profiles,calc_fluor,calc_planck,calc_directional,calc_xanthophyllabs,calc_PSI,rt_thermal,calc_zo,soilspectrum,soil_heat_method,Fluorescence_model,calc_rss_rbs,apply_T_corr,verify,save_headers,makeplots,simulation default c(1,1,1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,1)
#' @return write the new SCOPE model options in the input_data.xlsx file
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' change_SCOPE_options(site_name = "DE-Hai",
#'                      run_name = "ECdata_36",
#'                      calc_ebal = 1)
#'
#' formattable::formattable(check_SCOPE_options(site_name = "DE-Hai", run_name = "ECdata_36"),
#'                          align = c("c","l"))
#' }
#'
#' @export
#'
change_SCOPE_options <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA,
    # set options
    calc_ebal = 1,
    calc_vert_profiles = 1,
    calc_fluor = 1,
    calc_planck = 0,
    calc_directional = 0,
    calc_xanthophyllabs = 1,
    calc_PSI = 0,
    rt_thermal = 0,
    calc_zo = 1,
    soilspectrum = 0,
    soil_heat_method = 1,
    Fluorescence_model = 0,
    calc_rss_rbs = 0,
    apply_T_corr = 1,
    verify = 0,
    save_headers = 1,
    makeplots = 0,
    simulation = 1
){

### model settings input_data.xls options spreadsheet
setoptions <- c(calc_ebal, calc_vert_profiles, calc_fluor, calc_planck,
               calc_directional, calc_xanthophyllabs, calc_PSI, rt_thermal,
               calc_zo, soilspectrum, soil_heat_method, Fluorescence_model,
               calc_rss_rbs, apply_T_corr, verify, save_headers, makeplots, simulation)


# open the excel file
input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

# change the model according the argument setoptions in the spreadsheet options
input_data[[2]]$`Simulation options` = c(NA,NA,NA,setoptions,NA,NA)

rio::export(input_data, paste0(patch, "runs/", site_name,  "_", run_name, "/", "input_data.xlsx"), col.names = FALSE)

return(print(paste0("The SCOPE model settings were altered inside the folder ", site_name, "_", run_name, " at runs/")))

}


#' to change the current SCOPE model default constants
#'
#' @description
#' `change_SCOPE_constants` change current SCOPE model default constants in the input_data.xlsx file
#'
#' @details
#' This function change current SCOPE model default constants selected to run, @seealso [check_SCOPE_constants()]
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run. The last can be used to name runs with different model parameters or settings,
#' @param LAT,LON,startDOY,endDOY,timezn the latitude, longitude, timezone and initial and final ts doy of the year ,
#' @param IGBP_veg_long the main IGBP landcover class in the point of interest,
#' @param veg_type_C default is 3, alternately can be use 4
#' @param Cab,Cca,Cdm,Cw,Cs,Cant,N,rho_thermal,tau_thermal PROSPECT submodel parameters for the default values @seealso [check_SCOPE_constants()]
#' @param Vcmo,m,BallBerry0,Type,kV,Rdparam,Tparam,Tyear,beta,kNPQs,qLs,stressfactor Leaf_Biochemical parameters for the default values @seealso [check_SCOPE_constants()]
#' @param fqe Fluorescence parameters @seealso [check_SCOPE_constants()]
#' @param spectrum,rss,rs_thermal,cs,rhos,lambdas,SMC,BSMBrightness,BSMlat,BSMlon Soil parameters @seealso [check_SCOPE_constants()]
#' @param LAI,hc,LIDFa,LIDFb,leafwidth Canopy parameters @seealso [check_SCOPE_constants()]
#' @param z,Rin,Rli,Ta,p,ea,u,Ca,Oa Meteo parameters @seealso [check_SCOPE_constants()]
#' @param zo,d,Cd,rb,CR,CD1,Psicor,CSSOIL,rbs,rwc Aerodynamic parameters @seealso [check_SCOPE_constants()]
#' @param tts,tto,psi Angles parameters @seealso [check_SCOPE_constants()]
#' @param delHaV,delSV,delHdV,delHaJ,delSJ,delHdJ,delHaP,delSP,delHdP,delHaR,delSR,delHdR,delHaKc,delHaKo,delHaT,Q10,s1,s2,s3,s4,s5,s6 Photosynthetic Temperature Dependence Functional parameters @seealso [check_SCOPE_constants()]

#' @return write the new SCOPE model default constants in the input_data.xlsx file
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' change_SCOPE_constants(site_name = "DE-Hai",
#'                        run_name = "ECdata_36",
#'                        LAT = st_coordinates(EC_loc)[3,2],
#'                        LON = st_coordinates(EC_loc)[3,1],
#'                        IGBP_veg_long = IGBP_Modis_EC$class[3],
#'                        hc = hc_EC_points$hc[3],
#'                        veg_type_C = 3,
#'                        Cab = 120)
#'
#' formattable::formattable(check_SCOPE_constants(site_name = "DE-Hai", run_name = "ECdata_36")[[1]],
#'                          align = c("l","c","c","l"))
#'
#' }
#'
#' @export
#'
change_SCOPE_constants <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA, run_name = NA,
    LAT = NA, LON = NA,
    IGBP_veg_long = NA,
    hc = NA,
    veg_type_C = 3,
    ### model inputs constant inputdata spreadsheet
    # PROSPECT
    Cab = 120,  Cca = 30 , Cdm = 0.015, Cw = 0.009, Cs = 0, Cant = 0,
    N = 1.4, rho_thermal = 0.01, tau_thermal = 0.01,
    # Leaf_Biochemical
    Vcmo =  80, m = 9, BallBerry0 = 0.015, Type = 0, kV = 0.6396,
    Rdparam = 0.015, Tparam = c(0.2, 0.3, 288, 313, 328),
    #Leaf_Biochemical (magnani model)
    Tyear = 9.74, beta = 0.507, kNPQs = 0, qLs = 1, stressfactor = 1,
    # Fluorescence
    fqe = 0.010,
    # Soil
    spectrum = 1, rss = 500, rs_thermal = 0.06, cs = 1180, rhos = 1800,
    lambdas = 1.55, SMC = 25.0,
    BSMBrightness = 0.50, BSMlat = LAT, BSMlon = LON,
    # Canopy
    LAI = 3, LIDFa = -0.35, LIDFb = -0.15, leafwidth = 0.10, #hc = 25,
    # Meteo
    z = 40, Rin = 600, Ta = 10, Rli = 300,
    p = 970, ea = 15, u = 2, Ca = 410, Oa = 209,
    # Aerodynamic
    zo = 2.5, d = 5.34, Cd = 0.30, rb =  10.00, CR = 0.35, CD1 = 20.60,
    Psicor = 0.20, CSSOIL = 0.01, rbs = 10.00, rwc = 0,
    # timeseries
    startDOY = 0, endDOY = 366, timezn = 1, #LAT = LAT, LON = LON,
    # Angles
    tts = 30, tto = 0, psi = 90,
    # Photosynthetic Temperature Dependence Functional Parameters
    delHaV = 65330.00, delSV = 485.00, delHdV = 149250.00,
    delHaJ = 43540.00, delSJ = 495.00, delHdJ = 152040.00,
    delHaP = 53100.00, delSP = 490.00, delHdP = 150650.00,
    delHaR = 46390.00, delSR = 490.00, delHdR = 150650.00,
    delHaKc = 79430.00, delHaKo = 36380.00, delHaT = 37830.00,
    Q10 = 2.00, s1 = 0.30, s2 = 313.15, s3 = 0.20,
    s4 =	288.15, s5 = 1.30, s6 = 328.15

){

  input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

  # in the spreadsheet inputdata
  input_data[[4]]$values <- c(NA, NA, NA, NA, NA, NA, NA,
                              Cab, Cca, Cdm, Cw, Cs, Cant, N, rho_thermal, tau_thermal, NA, NA,
                              Vcmo, m, BallBerry0, Type, kV, Rdparam, Tparam[1], NA,
                              Tyear, beta, kNPQs, qLs, stressfactor, NA, NA,
                              fqe, NA, NA,
                              spectrum, rss, rs_thermal, cs, rhos, lambdas, SMC, BSMBrightness, BSMlat, BSMlon, NA, NA,
                              LAI, hc, LIDFa, LIDFb, leafwidth, NA, NA,
                              z, Rin, Ta, Rli, p, ea, u, Ca, Oa, NA, NA,
                              zo, d, Cd, rb, CR, CD1, Psicor, CSSOIL, rbs, rwc, NA, NA,
                              startDOY, endDOY, LAT, LON, timezn, NA, NA,
                              tts, tto, psi, NA,
                              delHaV, delSV, delHdV, NA,
                              delHaJ, delSJ, delHdJ, NA,
                              delHaP, delSP, delHdP, NA,
                              delHaR, delSR, delHdR, NA,
                              delHaKc, delHaKo, delHaT, NA,
                              Q10, s1, s2, s3, s4, s5, s6, NA, NA, NA, NA, NA, NA)

  # Biome 1
  if(IGBP_veg_long == "Evergreen Broadleaf Forest") {
    Tparam = c(0.2, 0.3, 288, 313, 328) }
  if(IGBP_veg_long == "Permanent Wetlands" & hc >= 5) {
    Tparam = c(0.2, 0.3, 288, 313, 328) }
  # Biome 2
  if(IGBP_veg_long == "Deciduous Broadleaf Forest") {
    Tparam = c(0.2, 0.3, 283, 311, 328) }
  # Biome 3
  if(IGBP_veg_long == "Mixed Forests") {
    Tparam = c(0.2, 0.3, 288, 313, 328) }
  # Biome 4
  if(IGBP_veg_long == "Deciduous Needleleaf Forest") {
    Tparam = c(0.2, 0.3, 278, 303, 328) }
  # Biome 5
  if(IGBP_veg_long == "Evergreen Broadleaf Forest") {
    Tparam = c(0.2, 0.3, 278, 303, 328) }
  # Biome 6
  if(IGBP_veg_long == "Grasslands" & veg_type_C == 4) {
    Tparam = c(0.2, 0.3, 288, 313, 328)
    Vcmo =  35.8
    m = 4
    Rdparam = 0.055}
  # Biome 7
  if(IGBP_veg_long == "Open Shrublands") {
    Tparam = c(0.2, 0.3, 278, 313, 328) }
  if(IGBP_veg_long == "Closed Shrublands") {
    Tparam = c(0.2, 0.3, 278, 313, 328) }
  if(IGBP_veg_long == "Permanent Wetlands" & hc <= 5) {
    Tparam = c(0.2, 0.3, 278, 313, 328) }
  # Biome 8
  if(IGBP_veg_long == "Savannas") {
    Tparam = c(0.2, 0.3, 288, 303, 328) }
  if(IGBP_veg_long == "Woody Savannas") {
    Tparam = c(0.2, 0.3, 288, 303, 328) }
  # Biome 9
  if(IGBP_veg_long == "Croplands") {
    Tparam = c(0.2, 0.3, 281, 308, 328) }
  if(IGBP_veg_long == "Grassland" & veg_type_C == 3) {
    Tparam = c(0.2, 0.3, 281, 308, 328) }

  input_data[[4]][25,2:6] <- Tparam

  rio::export(input_data, paste0(patch, "runs/", site_name, "_", run_name, "/", "input_data.xlsx"), col.names = FALSE)

  return(print(paste0("The SCOPE default constants, input_data were updated for the location in the folder ", site_name, "-", run_name, " at.. runs/")))

}



# STEMMUS----

#' to change the current STEMMUS Model settings
#'
#' @description
#' `change_STEMMUS_ModelSettings` change current model settings for STEMMUS
#'
#' @details
#' This function change current STEMMUS model settings @seealso [info_STEMMUS_ModelSettings()].
#' **important** differently from SCOPE options, any change in the settings will impact all
#' next runs and not a specific site_name/run_name run.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run will be changed in the runs folder. The last can be used to name runs with different model parameters or settings,
#' @param R_depth,J,SWCC,Hystrs,Thmrlefc,Soilairefc,hThmrl,W_Chg,ThmrlCondCap,ThermCond,SSUR,fc,Tr,T0,rwuef,rroot,SFCC,Tot_Depth,Eqlspace,NS,NIT,KT,NL defaut is c(350,1,1,0,1,0,1,1,1,1,"10^2",0.02,20,273.15,1,"1.5*1e-3",1,500,0,1,30,0,100)
#' @return write the new STEMMUS settings
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' change_STEMMUS_ModelSettings(J = 1)
#'
#' formattable::formattable(check_STEMMUS_ModelSettings(), align = c("l","c"))
#'}
#'
#' @export
#'
change_STEMMUS_ModelSettings <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA,
    R_depth = 350,
    J = 1,
    SWCC = 1,
    Hystrs = 0,
    Thmrlefc = 1,
    Soilairefc = 0,
    hThmrl = 1,
    W_Chg = 1,
    ThmrlCondCap = 1,
    ThermCond = 1,
    SSUR = "10^2",
    fc = 0.02,
    Tr = 20,
    T0 = 273.15,
    rwuef = 1,
    rroot = "1.5 * 1e-3",
    SFCC = 1,
    Tot_Depth = 500,
    Eqlspace = 0,
    NS = 1,
    NIT = 30,
    KT = 0,
    NL = 100

){

  Settings <- c(
    "function ModelSettings = getModelSettings()",
    "    %{",
    "    %}",
    "",
    paste0("    ModelSettings.R_depth = ", R_depth, ";"),
    "",
    "    % Indicator denotes the index of soil type for choosing soil physical parameters",
    paste0("    ModelSettings.J = ", J, ";"),
    "",
    "    % indicator for choose the soil water characteristic curve, =0, Clapp and",
    "    % Hornberger; =1, Van Gen",
    paste0("    ModelSettings.SWCC = ", SWCC, ";"),
    "",
    "    % If the value of Hystrs is 1, then the hysteresis is considered, otherwise 0;",
    paste0("    ModelSettings.Hystrs = ", Hystrs, ";"),
    "",
    "    % Consider the isothermal water flow if the value is 0, otherwise 1;",
    paste0("    ModelSettings.Thmrlefc = ", Thmrlefc, ";"),
    "",
    "    % The dry air transport is considered with the value of 1,otherwise 0;",
    paste0("    ModelSettings.Soilairefc = ", Soilairefc, ";"),
    "",
    "    % Value of 1, the special calculation of water capacity is used, otherwise 0;",
    paste0("    ModelSettings.hThmrl = ", hThmrl, ";"),
    "",
    "    % Value of 0 means that the heat of wetting would be calculated by Milly's",
    "    % method/Otherwise,1. The method of Lyle Prunty would be used;",
    paste0("    ModelSettings.W_Chg = ", W_Chg, ";"),
    "",
    "    % The indicator for choosing Milly's effective thermal capacity and conductivity",
    "    % formulation to verify the vapor and heat transport in extremly dry soil.",
    paste0("    ModelSettings.ThmrlCondCap = ", ThmrlCondCap, ";"),
    "",
    "    % The indicator for choosing effective thermal conductivity methods, 1= de vries",
    "    % method;2= Jonhansen methods;3= Simplified de vries method(Tian 2016);4=",
    "    % Farouki methods",
    paste0("    ModelSettings.ThermCond = ", ThermCond, ";"),
    "",
    "    % Surface area for loam 10^5,for sand 10^2 (cm^-1)",
    paste0("    ModelSettings.SSUR = ", SSUR, ";"),
    "",
    "    % The fraction of clay,for loam 0.036; for sand 0.02",
    paste0("    ModelSettings.fc = ", fc, ";"),
    "",
    "    % Reference temperature",
    paste0("    ModelSettings.Tr = ", Tr, ";"),
    paste0("    ModelSettings.T0 = ", T0, ";"),
    "",
    "    % Other settings",
    paste0("    ModelSettings.rwuef = ", rwuef, ";"),
    paste0("    ModelSettings.rroot = ", rroot, ";"),
    paste0("    ModelSettings.SFCC = ", SFCC, ";"),
    "",
    paste0("    ModelSettings.Tot_Depth = ", Tot_Depth, "; % Unit is cm. it should be usually bigger than 0.5m. Otherwise,"),
    paste0("    ModelSettings.Eqlspace = ", Eqlspace, "; % Indicator for deciding is the space step equal or not; % the DeltZ would be reset in 50cm by hand;"),
    "",
    paste0("    ModelSettings.NS = ", NS, "; % Number of soil types;"),
    "",
    "    % The time and domain information setting",
    paste0("    ModelSettings.NIT = ", NIT, "; % Desirable number of iterations in a time step;"),
    paste0("    ModelSettings.KT = ", KT, "; % Number of time steps;"),
    "",
    "    % Determination of NL, the number of elments",
    paste0("    ModelSettings.NL = ", NL, ";"),
    "    if ~ModelSettings.Eqlspace",
    "        [DeltZ, DeltZ_R, NL, ML] = Dtrmn_Z(ModelSettings.NL, ModelSettings.Tot_Depth);",
    "    else",
    "        for i = 1:ModelSettings.NL",
    "           DeltZ(i) = ModelSettings.Tot_Depth / ModelSettings.NL;",
    "        end",
    "    end",
    paste0("    ModelSettings.NL = NL;"),
    paste0("    ModelSettings.ML = ML;"),
    paste0("    ModelSettings.DeltZ = DeltZ;"),
    paste0("    ModelSettings.DeltZ_R = DeltZ_R;"),
    "",
    "end"
  )

  utils::write.table(Settings, paste0(patch, "runs/", site_name, "_", run_name, "/", "getModelSettings.m"),
                     row.names = F, col.names = F, quote = FALSE, sep = "   ")

  return(print("STEMMUS Model Settings modified, check it using get_ModelSettings() function"))

}


#' to change the current STEMMUS Model Soil Constants
#'
#' @description
#' `change_STEMMUS_SoilConstants` change current model Soil Constants inputs for STEMMUS
#'
#' @details
#' This function change current STEMMUS model Soil Constants inputs @seealso [info_STEMMUS_SoilConstants()].
#' **important** differently from SCOPE constant parameters any change in the constants will impact all
#' next runs and not a specific site_name/run_name run as in SCOPE.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run will be changed in the runs folder. The last can be used to name runs with different model parameters or settings,
#' @param hd,hm,CHST,Elmn_Lnth,Dmark,Phi_S1,Phi_S2,Phi_S3,Phi_S4,Phi_S5,Phi_S6,Phi_soc,Lamda_soc,Theta_soc,XK, dafault = c(-1e7, -9899,0,0,0,-17.9,-17,-17,-19,-10,-10,-0.0103,2.7,0.6,0.025)
#' @return write the new STEMMUS Soil Constants inputs
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' change_soil_constants(XK = 0.025)
#'
#' formattable::formattable(check_STEMMUS_SoilConstants(), align = c("l","c"))
#'}
#'
#' @export
#'
change_STEMMUS_SoilConstants <- function(
    patch = "D:/model/rSTEMMUS_SCOPE/",
    site_name = NA,
    run_name = NA,
    hd = -1e7,
    hm = -9899,
    CHST = 0,
    Elmn_Lnth = 0,
    Dmark = 0,
    Phi_S1=-17.9,
    Phi_S2=-17,
    Phi_S3=-17,
    Phi_S4=-19,
    Phi_S5=-10,
    Phi_S6=-10,
    Phi_soc = -0.0103,
    Lamda_soc = 2.7,
    Theta_soc = 0.6,
    XK = 0.025

){

Soil_Constants <- c(
  "function SoilConstants = getSoilConstants()",
  "",
  paste0("    SoilConstants.hd = ", hd, ";"),
  paste0("    SoilConstants.hm = ", hm,";"),
  paste0("    SoilConstants.CHST = ", CHST, ";"),
  paste0("    SoilConstants.Elmn_Lnth = ", Elmn_Lnth, ";"),
  paste0("    SoilConstants.Dmark = ", Dmark, ";"),
  paste0("    SoilConstants.Phi_S = ", "[",Phi_S1,Phi_S2,Phi_S3,Phi_S4,Phi_S5,Phi_S6,"]", ";"),
  paste0("    SoilConstants.Phi_soc = ", Phi_soc, ";"),
  paste0("    SoilConstants.Lamda_soc = ", Lamda_soc, ";"),
  paste0("    SoilConstants.Theta_soc = ", Theta_soc, ";"),
  "    % XK=0.11 for silt loam; For sand XK = 0.025",
  "    % SoilConstants.XK is used in updateSoilVariables",
  paste0("    SoilConstants.XK = ", XK, ";"),
  "",
  "end")

utils::write.table(Soil_Constants, paste0(patch, "runs/", site_name, "_", run_name, "/", "getSoilConstants.m"),
                   row.names = F, col.names = F, quote = FALSE, sep = "   ")

return(print("constants modified, check it using get_soil_constants() function"))

}


#' to change the current STEMMUS Model define Constants file
#'
#' @description
#' `change_STEMMUS_DefineConstants` change current model define Constants inputs for STEMMUS
#'
#' @details
#' This function change current STEMMUS model define Constants inputs @seealso [check_STEMMUS_DefineConstants()].
#' **important** differently from SCOPE constant parameters any change in the constants will impact all
#' next runs and not a specific site_name/run_name run as in SCOPE.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default "D:/model/rSTEMMUS_SCOPE/",
#' @param site_name,run_name the name of the location and the name of run will be changed in the runs folder. The last can be used to name runs with different model parameters or settings,
#' @param A,h,c,cp,cp_specific,R,R_specific,rhoa,kappa,MH2O,Mair,MCO2,sigmaSB,deg2rad,C2K,CKTN,l,g,RHOL parameters
#' @param RHOI,Rv,RDA,RHO_bulk,Hc,GWT,MU_a,Gamma0,Gamma_w,Lambda1,Lambda2,Lambda3,MU_W0,MU1,b,W0,c_L,c_V,c_a,c_i,lambdav,k more parameters
#' @return write the new STEMMUS define Constants inputs
#' @family check the current parameters and settings
#'
#' @examples
#'
#' \dontrun{
#' change_define_constants(A = "6.02214E23")
#'
#' formattable::formattable(check_STEMMUS_DefineConstants(), align = c("l","c"))
#'}
#'
#' @export
#'
change_STEMMUS_DefineConstants <- function(
    site_name = NA,
    run_name = NA,
    patch = "D:/model/rSTEMMUS_SCOPE/",
    A = "6.02214E23",
    h = "6.6262E-34",
    c = "299792458",
    cp = 1004,
    cp_specific = "1.013E-3",
    R = 8.314,
    R_specific = 0.287,
    rhoa = 1.2047,
    kappa = 0.4,
    MH2O = 18,
    Mair = 28.96,
    MCO2 = 44,
    sigmaSB = "5.67E-8",
    deg2rad = "pi / 180",
    C2K = 273.15,
    CKTN = "(50 + 2.575 * 20)",
    l = 0.5,
    g = 981,
    RHOL =  1,
    RHOI = 0.92,
    Rv = "461.5 * 1e4",
    RDA = "287.1 * 1e4",
    RHO_bulk = 1.25,
    Hc = 0.02,
    GWT = 7,
    MU_a = "1.846 * 10^(-4)",
    Gamma0 = 71.89,
    Gamma_w = "const.RHOL*const.g",
    Lambda1 = "0.228 / 100",
    Lambda2 = "-2.406/100",
    Lambda3 =  "4.909/100",
    MU_W0 = "2.4152 * 10^(-4)",
    MU1 = 4742.8,
    b = "4 * 10^(-6)",
    W0 = "1.001 * 10^3",
    c_L = 4.186,
    c_V = 1.870,
    c_a = 1.005,
    c_i = 2.0455,
    lambdav = 2.45,
    k = 0.41

){

def_constants <- c(
  "function [const] = define_constants()",
  "",
  paste0("    const.A = ", A, "; % [mol-1] Constant of Avogadro"),
  paste0("    const.h = ", h, "; % [J s] Plancks constant"),
  paste0("    const.c = ", c, "; % [m s-1] Speed of light"),
  paste0("    const.cp = ", cp, "; % [J kg-1 K-1] Specific heat of dry air"),
  paste0("    const.cp_specific =  ", cp_specific, "; % specific heat at cte pressure [MJ.kg-1.C-1] FAO56 p26 box6"),
  paste0("    const.R = ", R, "; % [J mol-1K-1] Molar gas constant"),
  paste0("    const.R_specific = ", R_specific, "; % specific gas [kJ.kg-1.K-1] FAO56 p26 box6"),
  paste0("    const.rhoa = ", rhoa, "; % [kg m-3] Specific mass of air"),
  paste0("    const.kappa = ", kappa, "; % [] Von Karman constant"),
  paste0("    const.MH2O = ", MH2O, "; % [g mol-1] Molecular mass of water"),
  paste0("    const.Mair = ", Mair, "; % [g mol-1] Molecular mass of dry air"),
  paste0("    const.MCO2 = ", MCO2, "; % [g mol-1] Molecular mass of carbon dioxide"),
  paste0("    const.sigmaSB = ", sigmaSB, "; % [W m-2 K-4] Stefan Boltzman constant"),
  paste0("    const.deg2rad = ", deg2rad, "; % [rad] Conversion from deg to rad"),
  paste0("    const.C2K = ", C2K, "; % [K] Melting point of water"),
  paste0("    const.CKTN = ", CKTN, "; % [] Constant used in calculating viscosity factor for hydraulic conductivity"),
  paste0("    const.l = ", l, "; % Coefficient in VG model"),
  paste0("    const.g = ", g, "; % [cm s-2] Gravity acceleration"),
  paste0("    const.RHOL = ", RHOL, "; % [g cm-3] Water density"),
  paste0("    const.RHOI = ", RHOI, "; % [g cm-3] Ice density"),
  paste0("    const.Rv = ", Rv, "; % [cm2 s-2 Cels-1] Gas constant for vapor (original J.kg^-1.Cels^-1)"),
  paste0("    const.RDA = ", RDA, "; % [cm2 s-2 Cels-1] Gas constant for dry air (original J.kg^-1.Cels^-1)"),
  paste0("    const.RHO_bulk = ", RHO_bulk, "; % [g cm-3] Bulk density of sand"),
  paste0("    const.Hc = ", Hc, "; % Henry's constant;"),
  paste0("    const.GWT = ", GWT, "; % The gain factor(dimensionless),which assesses the temperature % dependence of the soil water retention curve is set as 7 for % sand (Noborio et al, 1996)"),
  paste0("    const.MU_a = ", MU_a, "; % [g cm-1 s-1] Viscosity of air (original 1.846*10^(-5)kg.m^-1.s^-1)"),
  paste0("    const.Gamma0 = ", Gamma0, "; % [g s-2] The surface tension of soil water at 25 Cels degree"),
  paste0("    const.Gamma_w = ", Gamma_w, "; % [g cm-2 s-2] Specific weight of water"),
  paste0("    const.Lambda1 = ", Lambda1, "; % Coefficients in thermal conductivity"),
  paste0("    const.Lambda2 = ", Lambda2, "; % [W m-1 Cels-1] (1 W.s=J) From HYDRUS1D heat transport parameter (Chung Hortan 1987 WRR)"),
  paste0("    const.Lambda3 = ", Lambda3, "; %"),
  paste0("    const.MU_W0 = ", MU_W0, "; % [g cm-1 s-1] Viscosity of water at reference temperature(original 2.4152*10^(-5)kg.m^-1.s^-1)"),
  paste0("    const.MU1 = ", MU1, "; % [J mol-1] Coefficient for calculating viscosity of water"),
  paste0("    const.b = ", b, "; % [cm] Coefficient for calculating viscosity of water"),
  paste0("    const.W0 = ", W0, "; % Coefficient for calculating differential heat of wetting by Milly's method"),
  paste0("    const.c_L = ", c_L, "; % [J/g-1/Cels-1] Specific heat capacity of liquid water, Notice the original unit is 4186kg^-1"),
  paste0("    const.c_V = ", c_V, "; % [J/g-1/Cels-1] Specific heat capacity of vapor"),
  paste0("    const.c_a = ", c_a, "; % [J/g-1/Cels-1] Specific heat capacity of dry air"),
  paste0("    const.c_i = ", c_i, "; % [J/g-1/Cels-1] Specific heat capacity of ice"),
  paste0("    const.lambdav = ", lambdav, "; % latent heat of evaporation [MJ.kg-1] FAO56 pag 31"),
  paste0("    const.k = ", k, "; % karman's cte [] FAO 56 Eq4"),
  "",
  "end"
)

utils::write.table(def_constants, paste0(patch, "runs/", site_name, "_", run_name, "/", "define_constants.m"),
                   row.names = F, col.names = F, quote = FALSE, sep = "   ")

return(print("constants modified, check it using get_define_constants() function"))

}


# check if the setting below are important to change when necessary
# "D:/model/STEMMUS_SCOPE/src/+groundwater/initializeGroundwaterSettings.m"
