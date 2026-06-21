#' to set all statical input parameters and model setting required
#'
#' @description
#' `input_constants` set all statical parameters and model setting required to run the model.
#'
#' @details
#' This is a function to prepare all static input parameters to run the model.
#' **important** the result of the get_SoilProperty needs to be informed,
#' otherwise all the soil properties need to be included manually.
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default ```"D:/model/rSTEMMUS_SCOPE/"```,
#' @param site_name,run_name,Simulation_Name the name of the location and the name of run. The second can be used to name runs with different model parameters or settings,
#' @param LAT,LON,elevation the latitude, longitude and elevation of the point of interest,
#' @param IGBP_veg_long the main IGBP landcover class in the point of interest,
#' @param veg_type_C default is 3, alternately can be use 4
#' @param initial_soil_temperature, soil temperature in the 6 depths (). It can be obtained in ERA5 data with funtion get_SoilInitials
#' @param initial_volumetric_soil_water volumetric soil water in the 6 depths (). It can be obtained in ERA5 data with funtion @seealso [get_SoilInitials()]
#' @param soil_property_list a list of soil properties extracted from the function @seealso [get_SoilProperties()]
#' @param coef_n,coef_alpha,saturatedk,ks0,residualMC,saturatedMC,porosity,theta_s0,fieldMC,FOClay,MSOCarbon,FOSand,coef_Lamda,fmax alternatively
#' include a data.frame("depth0"=X,"depth5"=X,"depth30"=X,"depth60"=X,"depth100"=X,"depth200"=X) with the values for each soil property,
#' the inputs ks0, theta_s0 and fmax require only one value. @seealso [get_SoilProperties()]
#' @param soil_type the type of soil will change some STEMMUS constants, default "sand" or alternatively "loam".
#' @param R_depth,J,SWCC,Hystrs,Thmrlefc,Soilairefc,hThmrl,W_Chg,ThmrlCondCap,ThermCond,SSUR,fc,Tr,T0,rwuef,rroot,SFCC,Tot_Depth,Eqlspace,NS,NIT,KT,NL getModelSettings.m
#' @param hd,hm,CHST,Elmn_Lnth,Dmark,Phi_S1,Phi_S2,Phi_S3,Phi_S4,Phi_S5,Phi_S6,Phi_soc,Lamda_soc,Theta_soc,XK getSoilConstants.m
#' @param A,h,c,cp,cp_specific,R,R_specific,rhoa,kappa,MH2O,Mair,MCO2,sigmaSB,deg2rad,C2K,CKTN,l,g,RHOL,RHOI,Rv,RDA,RHO_bulk,Hc,GWT,MU_a,Gamma0,Gamma_w,Lambda1,Lambda2,Lambda3,MU_W0,MU1,b,W0,c_L,c_V,c_a,c_i,lambdav,k define_constants.m
#' @param startDOY,endDOY,timezn,n_timestamps day of the year for the start and end of the run period. The the timezone and number of timestamps being run.
#' @param timestep_min, four hourly data use 60, half hour 30 (maximum possible is 180 for timestamp of every 3 hours)
#' @param soil_file,leaf_file,atmos_file default "soilnew.txt", "Optipar2017_ProspectD.mat","FLEX-S3_std.atm",  @seealso [info_SCOPE_README()], @seealso [info_SCOPE_options()]
#' SCOPE model inputs, constants from inputdata spreadsheet
#' @param Cab,Cca,Cdm,Cw,Cs,Cant,N,rho_thermal,tau_thermal PROSPECT submodel parameters for the default values @seealso [check_SCOPE_constants()]
#' @param Vcmo,m,BallBerry0,Type,kV,Rdparam,Tparam,Tyear,beta,kNPQs,qLs,stressfactor Leaf_Biochemical parameters for the default values @seealso [check_SCOPE_constants()]
#' @param fqe Fluorescence parameters @seealso [check_SCOPE_constants()]
#' @param spectrum,rss,rs_thermal,cs,rhos,lambdas,SMC,BSMBrightness,BSMlat,BSMlon Soil parameters @seealso [check_SCOPE_constants()]
#' @param LAI,hc,LIDFa,LIDFb,leafwidth Canopy parameters @seealso [check_SCOPE_constants()]
#' @param z,Rin,Rli,Ta,p,ea,u,Ca,Oa Meteo parameters @seealso [check_SCOPE_constants()]
#' @param zo,d,Cd,rb,CR,CD1,Psicor,CSSOIL,rbs,rwc Aerodynamic parameters @seealso [check_SCOPE_constants()]
#' @param tts,tto,psi Angles parameters @seealso [check_SCOPE_constants()]
#' @param delHaV,delSV,delHdV,delHaJ,delSJ,delHdJ,delHaP,delSP,delHdP,delHaR,delSR,delHdR,delHaKc,delHaKo,delHaT,Q10,s1,s2,s3,s4,s5,s6 Photosynthetic Temperature Dependence Functional parameters @seealso [check_SCOPE_constants()]
#' @param setoptions a vector of model settings from the input_data.xls options spreadsheet @seealso [info_SCOPE_options()]
#' @return returns all files with static from STEMMUS and SCOPE will be write in the folder input/site_name_run_name_time
#' @family set input parameters
#'
#' @examples
#' \dontrun{
#' input_constants(patch = "D:/model/rSTEMMUS_SCOPE/",
#'                   site_name = "DE-HoH",
#'                   run_name = "ECdata_01",
#'                   LAT = 37.83,
#'                   LON = 107.69,
#'                   elevation = 500,
#'                   IGBP_veg_long = "Grassland",
#'                   soil_type = "sand", # alternatively "loam"
#'                   hc = 0.03,
#'                   z = 2,
#'                   zo = 0.00369,
#'                   d = 0.0201,
#'                   n_timestamps = 7344, # number of timestamps
#'                   timestep_min = 30, # hourly 60, half hour 30
#'                   # CDS ERA5Land layers 1 to 4
#'                   initial_soil_temperature = data.frame("skt"=Initial_01MAY19_Yachi_p[1,2],
#'                                                         "stl1"=Initial_01MAY19_Yachi_p[2,2],
#'                                                         "stl2"=Initial_01MAY19_Yachi_p[3,2],
#'                                                         "stl3"=Initial_01MAY19_Yachi_p[4,2],
#'                                                         "stl4"=Initial_01MAY19_Yachi_p[5,2]),
#'                   initial_volumetric_soil_water = data.frame("swvl1"=Initial_01MAY19_Yachi_p[6,2],
#'                                                              "swvl2"=Initial_01MAY19_Yachi_p[7,2],
#'                                                              "swvl3"=Initial_01MAY19_Yachi_p[8,2],
#'                                                              "swvl4"=Initial_01MAY19_Yachi_p[9,2]),
#'                   soil_property_list = Soil_property_CRNs,
#'                   startDOY = 121,
#'                   endDOY = 274,
#'                   timezn = 8,
#'                   Tyear = 8.3,
#'                   Cab = 80,
#'                   Cca = 25,
#'                   Cdm = 0.012,
#'                   LAI = 0.46,
#'                   Vcmo = 120,
#'                   m = 7,
#'                   BallBerry0 = 0.025,
#'                   Ta = 20,
#'                   SMC = 0.15,
#'                   LIDFa = -0.4667,
#'                   leafwidth = 0.003,
#'                   Ca = 380,
#'                   setoptions = c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1))
#' }
#'
#' @export
input_constants <- function(patch = "D:/model/rSTEMMUS_SCOPE/",
                              site_name = NA,
                              run_name = NA,
                        #
                        # STEMMUS Parameters
                        # global forncing data inputs
                        n_timestamps = NA, # number of timestamps
                        timestep_min = NA, # hourly 60, half hour 30
                        #hc = NA,     # also used in input_data.xls
                        #z = NA,  # also used in input_data.xls
                        elevation = NA,
                        IGBP_veg_long = NA,

                        # soil initial conditions inputs
                        initial_volumetric_soil_water = data.frame("swvl1"=NA,"swvl2"=NA,"swvl3"=NA,"swvl4"=NA), #CDS ERA5Land layers 1 to 4
                        initial_soil_temperature = data.frame("skt"=NA,"stl1"=NA,"stl2"=NA,"stl3"=NA,"stl4"=NA), #CDS ERA5Land layers 1 to 4

                        # Soil properties inputs
                        soil_property_list = NA, #Soil_property_points
                        #Derived from the PTF_SoilGrids_Schaap datasets  from the valid depths: 0, 5, 15, 30, 60, 100 and 200 cm (sl1 to sl7), excluding sl3 (15cm).
                        coef_n = data.frame("depth0"=NA,"depth5"=NA,"depth30"=NA,"depth60"=NA,"depth100"=NA,"depth200"=NA),
                        coef_alpha = data.frame("depth0"=NA,"depth5"=NA,"depth30"=NA,"depth60"=NA,"depth100"=NA,"depth200"=NA),
                        saturatedk = data.frame("depth0"=NA,"depth5"=NA,"depth30"=NA,"depth60"=NA,"depth100"=NA,"depth200"=NA),
                        ks0 = data.frame("depth0"=NA),
                        residualMC = data.frame("depth0"=NA,"depth5"=NA,"depth30"=NA,"depth60"=NA,"depth100"=NA,"depth200"=NA),
                        saturatedMC = data.frame("depth0"=NA,"depth5"=NA,"depth30"=NA,"depth60"=NA,"depth100"=NA,"depth200"=NA),
                        porosity = data.frame("depth0"=NA,"depth5"=NA,"depth30"=NA,"depth60"=NA,"depth100"=NA,"depth200"=NA),
                        theta_s0 = data.frame("depth0"=NA),
                        fieldMC = data.frame("depth0"=NA,"depth5"=NA,"depth30"=NA,"depth60"=NA,"depth100"=NA,"depth200"=NA),
                        # soil grid layers (1, 2) are combined and the values from the depth 1,3,5,6,7,8 are used per variable
                        FOClay = data.frame("depth4.5"=NA,"depth16.6"=NA,"depth49.29"=NA,"depth82.9"=NA,"depth138.3"=NA,"depth229.6"=NA),
                        MSOCarbon = data.frame("depth4.5"=NA,"depth16.6"=NA,"depth49.29"=NA,"depth82.9"=NA,"depth138.3"=NA,"depth229.6"=NA),
                        FOSand = data.frame("depth4.5"=NA,"depth16.6"=NA,"depth49.29"=NA,"depth82.9"=NA,"depth138.3"=NA,"depth229.6"=NA),
                        #Only the Lambda file layers l1, l3, l5, l6, l7, l8 (depth_indices) were combined and used
                        coef_Lamda = data.frame("l1"=NA,"l3"=NA,"l5"=NA,"l6"=NA,"l7"=NA,"l8"=NA),
                        fmax = NA,

                        soil_type = "sand", # or "loam"

                        # STEMMUS getModelSettings.m
                        R_depth = 350, J = 1, SWCC = 1, Hystrs = 0, Thmrlefc = 1, Soilairefc = 0,
                        hThmrl = 1, W_Chg = 1, ThmrlCondCap = 1, ThermCond = 1, SSUR = "10^2",
                        fc = 0.02, Tr = 20, T0 = 273.15, rwuef = 1, rroot = "1.5 * 1e-3",
                        SFCC = 1, Tot_Depth = 500, Eqlspace = 0, NS = 1, NIT = 30, KT = 0, NL = 100,
                        # STEMMUS getSoilConstants.m
                        hd = -1e7, hm = -9899, CHST = 0, Elmn_Lnth = 0, Dmark = 0,
                        Phi_S1=-17.9, Phi_S2=-17, Phi_S3=-17, Phi_S4=-19, Phi_S5=-10, Phi_S6=-10,
                        Phi_soc = -0.0103, Lamda_soc = 2.7, Theta_soc = 0.6, XK = 0.011,
                        # STEMMUS define_constants.m
                        A = "6.02214E23", h = "6.6262E-34", c = "299792458", cp = "1004",
                        cp_specific = "1.013E-3", R = "8.314", R_specific = "0.287",
                        rhoa = "1.2047", kappa = "0.4", MH2O = "18", Mair = "28.96",
                        MCO2 = "44", sigmaSB = "5.67E-8", deg2rad = "pi / 180",
                        C2K = "273.15", CKTN = "(50 + 2.575 * 20)", l = "0.5",
                        g = "981", RHOL =  "1", RHOI = "0.92", Rv = "461.5 * 1e4",
                        RDA = "287.1 * 1e4", RHO_bulk = "1.25", Hc = "0.02",
                        GWT = "7", MU_a = "1.846 * 10^(-4)",
                        Gamma0 = "71.89", Gamma_w = "const.RHOL*const.g",
                        Lambda1 = "0.228 / 100", Lambda2 = "-2.406/100", Lambda3 =  "4.909/100",
                        MU_W0 = "2.4152 * 10^(-4)", MU1 = "4742.8", b = "4 * 10^(-6)", W0 = "1.001 * 10^3",
                        c_L = "4.186", c_V = "1.870", c_a = "1.005",  c_i = "2.0455", lambdav = "2.45",
                        k = "0.41",

                        #
                        # SCOPE parameters
                        # input_data.xls filenames spreadsheet
                        Simulation_Name	= site_name,
                        soil_file =	"soilnew.txt",
                        leaf_file	= "Optipar2017_ProspectD.mat",
                        atmos_file =	"FLEX-S3_std.atm",

                        ### model settings input_data.xls options spreadsheet
                        setoptions = c(1,  # calc_ebal = 1,
                                       1,  # calc_vert_profiles = 0,
                                       1,  # calc_fluor = 0,
                                       0,  # calc_planck = 0,
                                       0,  # calc_directional = 0,
                                       1,  # calc_xanthophyllabs = 1,
                                       0,  # calc_PSI = 0,
                                       0,  # rt_thermal = 0,
                                       1,  # calc_zo = 1,
                                       0,  # soilspectrum = 1,
                                       0,  # soil_heat_method = 1,
                                       0,  # Fluorescence_model = 0,
                                       0,  # calc_rss_rbs = 0,
                                       1,  # apply_T_corr = 1,
                                       0,  # verify = 0,
                                       1,  # save_headers = 1,
                                       0,  # makeplots = 0,
                                       1), # simulation = 1,

                        veg_type_C = 3,

                        #
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
                        LAI = 3, hc = 25, LIDFa = -0.35, LIDFb = -0.15, leafwidth = 0.10,
                        # Meteo
                        z = 40, Rin = 600, Ta = 10, Rli = 300,
                        p = 970, ea = 15, u = 2, Ca = 410, Oa = 209,
                        # Aerodynamic
                        zo = 2.5, d = 5.34, Cd = 0.30, rb =  10.00, CR = 0.35, CD1 = 20.60,
                        Psicor = 0.20, CSSOIL = 0.01, rbs = 10.00, rwc = 0,
                        # timeseries
                        startDOY = 0, endDOY = 366, LAT = LAT, LON = LON, timezn = 1,
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

  # Forcing data ----
  # load the forcing data - MATLAB file (.mat)

  forcing_globals <- rhdf5::H5Fopen(paste0(patch,"runs/", site_name, "_", run_name, "/", "forcing_globals.mat"))

  IGBP_utf8 <- c(utf8ToInt(IGBP_veg_long),rep(32,200-length(utf8ToInt(IGBP_veg_long))))

  new_IGBP <- t((as.matrix(as.integer(rep(IGBP_utf8, n_timestamps)))))

  rhdf5::h5set_extent(forcing_globals, "IGBP_veg_long", dim(new_IGBP))

  forcing_globals$IGBP_veg_long[1,] <- new_IGBP

  forcing_globals$DELT[1] <- 60*timestep_min  # timestep size in seconds 60*30 (or 60*60 if hourly)
  forcing_globals$Dur_tot[1] <- n_timestamps
  forcing_globals$canopy_height[1] <- hc
  forcing_globals$elevation[1] <- elevation
  forcing_globals$latitude[1] <- LAT
  forcing_globals$longitude[1] <- LON
  forcing_globals$reference_height[1] <- z
  forcing_globals$sitename[1:6] <- utf8ToInt(site_name)

  rhdf5::h5closeAll()

  # Initial conditions ----
  # (the datetime that starts the timeseries data)
  # open soil initial conditions .mat file
  soil_init <- rhdf5::H5Fopen(paste0(patch,"runs/", site_name, "_", run_name, "/", "soil_init.mat"))

  soil_init$Tss[1] <- initial_soil_temperature$skt - 273.15 # K to °c
  soil_init$InitT0[1] <- initial_soil_temperature$skt - 273.15
  soil_init$InitT1[1] <- initial_soil_temperature$stl1 - 273.15
  soil_init$InitT2[1] <- initial_soil_temperature$stl2 - 273.15
  soil_init$InitT3[1] <- initial_soil_temperature$stl3 - 273.15
  soil_init$InitT4[1] <- initial_soil_temperature$stl4 - 273.15
  soil_init$InitT5[1] <- initial_soil_temperature$stl4 - 273.15
  soil_init$InitT6[1] <- initial_soil_temperature$stl4 - 273.15
  soil_init$InitX0[1] <- initial_volumetric_soil_water$swvl1
  soil_init$InitX1[1] <- initial_volumetric_soil_water$swvl1
  soil_init$InitX2[1] <- initial_volumetric_soil_water$swvl2
  soil_init$InitX3[1] <- initial_volumetric_soil_water$swvl3
  soil_init$InitX4[1] <- initial_volumetric_soil_water$swvl4
  soil_init$InitX5[1] <- initial_volumetric_soil_water$swvl4
  soil_init$InitX6[1] <- initial_volumetric_soil_water$swvl4
  soil_init$BtmX[1] <- initial_volumetric_soil_water$swvl4

  rhdf5::h5closeAll()

  # Soil properties ----
  # open the Matlab soil_parameters.mat file
  soil_parameters <- rhdf5::H5Fopen(paste0(patch,"runs/", site_name, "_", run_name, "/", "soil_parameters.mat"))

  if(missing(soil_property_list)){

    # replace the values to the location 1
    soil_parameters$FOC[1:6] <- FOClay
    soil_parameters$FOS[1:6] <- FOSand
    soil_parameters$MSOC[1:6] <- MSOCarbon

    soil_parameters$Coef_Lamda[1:6] <- coef_Lamda
    soil_parameters$Coefficient_Alpha[1:6] <- coef_alpha
    soil_parameters$SaturatedK[1:6] <- saturatedk
    soil_parameters$Ks0[1] <- ks0
    soil_parameters$Coefficient_n[1:6] <- coef_n
    soil_parameters$ResidualMC[1:6] <- residualMC
    soil_parameters$porosity[1:6] <- porosity
    soil_parameters$SaturatedMC[1:6] <- saturatedMC
    soil_parameters$theta_s0[1] <- theta_s0

    soil_parameters$fieldMC[1:6] <- fieldMC
    soil_parameters$fmax <- fmax

    rhdf5::h5closeAll()

  }else{

    # replace the values to the location 1
    soil_parameters$FOC[1:6] <- soil_property_list$FOC[1:6]
    soil_parameters$FOS[1:6] <- soil_property_list$FOS[1:6]
    soil_parameters$MSOC[1:6] <- soil_property_list$MSOC[1:6]

    soil_parameters$Coef_Lamda[1:6] <- soil_property_list$Coef_Lamda[1:6]
    soil_parameters$Coefficient_Alpha[1:6] <- soil_property_list$Coefficient_Alpha[1:6]
    soil_parameters$SaturatedK[1:6] <- soil_property_list$SaturatedK[1:6]
    soil_parameters$Ks0[1] <- soil_property_list$Ks0[1]
    soil_parameters$Coefficient_n[1:6] <- soil_property_list$Coefficient_n[1:6]
    soil_parameters$ResidualMC[1:6] <- soil_property_list$ResidualMC[1:6]
    soil_parameters$porosity[1:6] <- soil_property_list$porosity[1:6]
    soil_parameters$SaturatedMC[1:6] <- soil_property_list$SaturatedMC[1:6]
    soil_parameters$theta_s0[1] <- soil_property_list$theta_s0[1]

    soil_parameters$fieldMC[1:6] <- soil_property_list$fieldMC[1:6]
    soil_parameters$fmax <- soil_property_list$fmax[1]

    rhdf5::h5closeAll()

  }

  if(soil_type == "loam") {
    SSUR = "10^5"
    fc = 0.036
    XK = 0.011
      }

    # getModelSettings
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

    # getSoilConstants
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

      # define_constants.m
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


  # SCOPE constants ----
  # open the excel file
  input_data <- rio::import_list(paste0(patch,"runs/", site_name, "_", run_name, "/", "input_data.xlsx"))

  # change the model according the argument setoptions in the spreadsheet options
  input_data[[2]]$`Simulation options` = c(NA,NA,NA,setoptions,NA,NA)

  # change the model files in the spreadsheet filenames
  input_data[[3]]$files[3:6] <- c(site_name, soil_file, leaf_file, atmos_file)

  # Biome ----

  # IGBP in STEMMUS-SCOPE	              Vegetation type in SCOPE
  # No vegetation	                      No vegetation
  # Croplands	                          Biome 9: Agriculture / C3 grassland
  # Croplands	                          Biome 9: Agriculture / C3 grassland
  # Cropland/natural vegetation mosaics	Biome 9: Agriculture / C3 grassland
  # Cropland/natural vegetation mosaics	Biome 9: Agriculture / C3 grassland
  # Evergreen Broadleaf Forest  	      Biome 1: Broadleaf - evergreen trees
  # Deciduous Broadleaf Forest	        Biome 2: Broadleaf - deciduous trees
  # Evergreen Needleleaf Forest 	      Biome 4: Needleleaf evergreen trees
  # Deciduous needleleaf Forest 	      Biome 5: Needleleaf deciduous trees
  # Mixed Forests	                      Biome 3: Broadleaf and needle leaf trees
  # Woody savannas	                    Biome 8: Tree/Savanna
  # Savannas 	                          Biome 8: Tree/Savanna
  # Closed shrublands	                  Biome 7: Shrub/Stepp
  # Grassland 	                        Biome 6: Short vegetation / C4 grassland or Biome 9: Agriculture / C3 grassland
  # Not available in IGBP	Shade plant
  # Open shrublands	                    Biome 7: Shrub/Stepp
  # Permanent Wetlands 	                Biome 1: Broadleaf - evergreen trees
  # Permanent Wetlands 	                Biome 1: Broadleaf - evergreen trees
  # Permanent Wetlands 	                Biome 7: Shrub/Stepp

  # Biome 1: Broadleaf - evergreen trees	    C3	0.2	 0.30	288	313	328	  9	  0.015	    80
  # Biome 2: Broadleaf - deciduous trees    	C3	0.2	 0.30	283	311	328	  9	  0.015	    80
  # Biome 3: Broadleaf and needle leaf trees	C3	0.2	 0.30	281	307	328	  9	  0.015	    80
  # Biome 4: Needleleaf evergreen trees	      C3	0.2	 0.30	278	303	328	  9	  0.015	    80
  # Biome 5: Needleleaf deciduous trees	      C3	0.2	 0.30	278	303	328	  9	  0.015	    80
  # Biome 6: Short vegetation / C4 grassland	C4	0.2	 0.30	288	313	328	  4	  0.025	    35.8
  # Biome 7: Shrub/Stepp                      C3	0.2	 0.30	278	313	328	  9	  0.015	    80
  # Biome 8: Tree/Savanna	                    C3	0.2	 0.30	288	303	328	  9	  0.015	    80
  # Biome 9: Agriculture / C3 grassland	      C3	0.2	 0.30	281	308	328	  9	  0.015	    80

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
  if(IGBP_veg_long == "Deciduous needleleaf Forest") {
    Tparam = c(0.2, 0.3, 278, 303, 328) }
  # Biome 5
  if(IGBP_veg_long == "Evergreen Broadleaf Forest") {
    Tparam = c(0.2, 0.3, 278, 303, 328) }
  # Biome 6
  if(IGBP_veg_long == "Grassland" & veg_type_C == 4) {
    Tparam = c(0.2, 0.3, 288, 313, 328)
    Vcmo =  35.8
    m = 4
    Rdparam = 0.055}
  # Biome 7
  if(IGBP_veg_long == "Open shrublands") {
    Tparam = c(0.2, 0.3, 278, 313, 328) }
  if(IGBP_veg_long == "Closed shrublands") {
    Tparam = c(0.2, 0.3, 278, 313, 328) }
  if(IGBP_veg_long == "Permanent Wetlands" & hc <= 5) {
    Tparam = c(0.2, 0.3, 278, 313, 328) }
  # Biome 8
  if(IGBP_veg_long == "Savannas") {
    Tparam = c(0.2, 0.3, 288, 303, 328) }
  if(IGBP_veg_long == "Woody savannas") {
    Tparam = c(0.2, 0.3, 288, 303, 328) }
  # Biome 9
  if(IGBP_veg_long == "Croplands") {
    Tparam = c(0.2, 0.3, 281, 308, 328) }
  if(IGBP_veg_long == "Grassland" & veg_type_C == 3) {
    Tparam = c(0.2, 0.3, 281, 308, 328) }

  # Model constants ----
  # (in the spreadsheet inputdata)
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

  input_data[[4]][25,2:6] <- Tparam

  rio::export(input_data, paste0(patch, "runs/", site_name,  "_", run_name, "/", "input_data.xlsx"), col.names = FALSE)

  return(print(paste0("The model settings, default constants, site dependent inputs and initial conditions files forcing_globals.mat, soil_init.mat, soil_parameters.mat were updated for the location in the folder ", site_name, "-", run_name, " at runs/")))

}
