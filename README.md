## README
------------------------------------------------------------------------
## rSTEMMUS_SCOPE
Codes to run the STEMMUS_SCOPE model in MATLAB from R. Integrated code of SCOPE and STEMMUS. SCOPE is a radiative transfer and energy balance model (see https://github.com/AlbyDR/rSCOPE), and STEMMUS model is a two-phase mass and heat transfer model. For more information about the coupling between these two models, please check this [reference](https://gmd.copernicus.org/articles/14/1379/2021/). 

### To install rSTEMMUS_SCOPE, use:
``` r
devtools::install_github("EcoExtreML/rSTEMMUS_SCOPE")
library(rSTEMMUSSCOPE)
```
You may need to install the rhdf5 package before using BiocManager, as shown below.
``` r
install.packages("BiocManager")
BiocManager::install("rhdf5")
```

### 🚀 Quick Start: Standard Roadmap Template

The most efficient way to set up a new simulation is using our **Standard Roadmap Template**. It is machine-agnostic, handles unit conversions (e.g., Celsius to Kelvin), and supports high-performance parallel execution out-of-the-box.

> **Template Path:** [`2026Contributions/scripts/runs/standardRoadmapLocation.R`](./2026Contributions/scripts/runs/standardRoadmapLocation.R)
>
> 1.  **Copy** the template and rename it (e.g., `roadmap_MySite.R`).
> 2.  **Edit [SECTION 2]** with your site metadata and weather data path.
> 3.  **Run** the script to automatically generate inputs and launch the model.

---
#### Model Documentation

The documentation of the STEMMUS_SCOPE model can be found [here](https://ecoextreml.github.io/STEMMUS_SCOPE).

STEMMUS_SCOPE supports three execution engines (pick one — set via `exe_method` in `run_inMATLAB()`):

| Engine | `exe_method` | License | Required version | Notes |
|:--|:--|:--|:--|:--|
| **MATLAB** | `"matlab"` (default) | Commercial | R2021a+ (uses the `-batch` flag) | Fastest on Windows |
| **GNU Octave** | `"octave"` | Free (GPL) | 8.0+ — tested on 11.1.0 with `io` + `statistics` packages | Cross-platform; on Windows the bundled `tar.exe` is used to parse xlsx (no system `unzip` needed) |
| **MATLAB Runtime** | `"mcr"` | Free, redistributable | Runtime pinned per release (current build: R2024a Runtime, ~3 GB from MathWorks) | Needs a precompiled `STEMMUS_SCOPE_exe` binary — download from project releases or build once with [src/compile_stemmus_scope.m](rSTEMMUS_SCOPE/src/compile_stemmus_scope.m) |

The MATLAB code is downloaded and unzipped on first run via ```initial_setup()```.

#### First-run troubleshooting

- **R can't find Octave / MATLAB / MCR**: [run_inMATLAB.R](R/run_inMATLAB.R) searches `C:\Program Files\GNU Octave\*`, `C:\Program Files\MATLAB\R*`, and `C:\Program Files\MATLAB\MATLAB Runtime\v*` on Windows (and `/Applications`, `/usr/local/MATLAB`, `/opt/MATLAB` on Unix). If your install is elsewhere, prepend its `bin/` to `PATH` before `Rscript`, or set `STEMMUS_SCOPE_EXE` to the compiled binary path.
- **Octave fails with `error: xlsopen ... unzip`**: Octave's `io` package shells out to `unzip` to read xlsx. On Windows installs without `unzip` on PATH, [src/+io/readXlsxNative.m](rSTEMMUS_SCOPE/src/+io/readXlsxNative.m) is used as a fallback (via the bundled `tar.exe`) — no action needed. If you also want `xlsread` itself to work, drop Info-ZIP `unzip.exe` into any PATH folder.
- **Background launches hang at timestep 0**: a known Windows quirk — if Rscript is launched without a console, the child engine deadlocks writing to a closed stdout. The wrapper now redirects engine output to `runs/SITE_RUN/engine_stdout.log` / `engine_stderr.log`; if you maintain a fork, mirror that redirection.
- **Soil temperatures or SMC look physically impossible (e.g. −267 °C, 25 m³/m³)**: confirm you converted °C → K (`+273.15`) for `initial_soil_temperature` and `% → fraction` (`/100`) for `initial_volumetric_soil_water` before passing them to `input_constants()`. The roadmap template already does this.

**Recent Key Features & Functional Changes:**

1. **`R/run_inMATLAB.R` Updates:**
   Dropped hardcoded CPU core limits and added cross-platform smart path detection + an Octave execution fallback.
   ```R
   if (octave) {
     cmd <- sprintf("cd '%s' && octave --no-gui --silent --eval 'STEMMUS_SCOPE; exit'", src_dir)
   } else {
     # MATLAB Exec (Auto-detecting Path for Windows/Mac/Linux)
     if (.Platform$OS.type == "unix") {
       mac_apps <- list.files("/Applications", pattern = "^MATLAB_R", full.names = TRUE)
     ...
   ```

2. **`rSTEMMUS_SCOPE/src/STEMMUS_SCOPE.m` (New):**
   838 new lines of MATLAB code were added to serve as the unified root execution script.
   ```matlab
   % Create execution paths dynamically
   d1 = pwd;
   % adding path of STEMMUS_SCOPE model: default dir=src
   addpath(d1)
   ...
   t_cpu = cputime;
   StartInit
   [Simu_Step] = Initial_root_biomass(Simu_Step);
   ```

3. **`run_simulation_background.sh` (New):**
   A background shell scripting tool was added to securely run simulations using `nohup`.
   ```bash
   # Run the simulation in the background using nohup
   nohup Rscript -e "
     source('R/run_inMATLAB.R')
     run_inMATLAB(patch = '${PATCH_DIR}', cores = ${CORES}, octave = ${OCTAVE})
   " > "$LOG_FILE" 2>&1 &
   ```

4. **`recover_csv.m` (New):**
   A standalone MATLAB script to rescue or process simulated variable outputs into clean CSV formats without failing the model trace.
   ```matlab
   function recover_csv(directory_path)
   ...
       vars_to_extract = {
           'Sim_Theta',... % soil moisture profile
           'Sim_TempE',... % soil temperature profile
           'Sim_Trns', ... % Transpiration (W m-2)
   ...
       for i = 1:length(vars_to_extract)
           var_name = vars_to_extract{i};
           file_path = fullfile(run_dir, [var_name, '.mat']);
   ...
           csvwrite(csv_path, var_data);
   ```

**directory structure**

After run ```initial_setup(patch = "D:/model/rSTEMMUS_SCOPE/")```, the following structure should be created.

```
D:/model/rSTEMMUS_SCOPE/
   - input/
     - directional/
     - fluspect_parameters/
     - leafangles/
     - radiationdata/
     - soil_spectrum/
     - files (template_config.txt, Mdata.txt, input_data.xls, forcing_globals.mat, soil_parameters.mat and soil_init.mat)
   - output/
      - AR-SLu_2024-01-25-0911 (output example)
   - runs/
      - file (path.txt)
      - AR-SLu_2024-01-25-0911 (input example)
   - src/
      - ... (MATLAB codes)
```

To check the installation by running the test dataset as below.

```
run_inMATLAB(patch = "D:/model/rSTEMMUS_SCOPE/",
             site_name = "AR-SLu",
             run_name = "2024-01-25-0911")
```             
note: change the patch according to the ```initial_setup()``` choice and include the patch in MATLAB ```"D:/model/rSTEMMUS_SCOPE/src/"```
             
------------------------------------------------------------------------
After collecting and organising the data required to run the model (see input variables below), there will be four steps (functions) to run a time series simulation for a specific location.
[see here the steps](https://github.com/EcoExtreML/rSTEMMUS_SCOPE/blob/master/run_steps.md)

> For a complete, automated recipe (including parallel setup), see the [Standard Roadmap Template](./2026Contributions/scripts/runs/standardRoadmapLocation.R).

------------------------------------------------------------------------

**Main model outputs from the simulations**

| output file | variable                     |   unit    | observation         |
|:-------|:-----------------------------|:---------:|:--------------------|
| Sim_Theta | Soil Water Content (SWC) | [m3 m-3] | per depth (1 to 500 cm) |
| Sim_Temp  | Soil Temperature (Ts)    |   [°C]   | per depth (1 to 500 cm) |
| Sim_hh  | Soil Water Potential (SWP)    |   [cm]   | per depth (1 to 500 cm) |
| surftemp | Surface Temperature (LST)  |   [°C]   | soil skin and canopy |
| waterPotential | Leaf Water Potential (LWP)  |   [m]   |  |
| waterStreessFactor | Soil Water Stress (factor)  |   [-]   | from 0 to 1 |
| fluxes | Evapotranspiration (ET) | [W m-2] | divide by soil (Evap) and plant (Trap) |
| fluxes | Heat Fluxes (lE, H, G) | [W m-2] | divide by soil (s) and canopy (c) |
| fluxes | Net Ecosystem Carbon Exchange (NEE) | [Kg m-2 s-1] |  |
| fluxes | Vegetation Gross Primary Production (GPP) | [Kg m-2 s-1] |  |
| fluxes | other variables (A, Rn, Resp, aPAR) | [W m-2; umol m-2 s-1] |  |
| aerodyn | aerodynmic parameters (raa, rawc, raws, ustar, rac, ras) | [s m-1] |  |
| fluoreecence | Fluorecence | [W m-2 um-1 sr-1] | wavelengths 640 to 850 nm |
| reflectance | Fraction of Radiation (in observation direction *pi/irradiance) | [-] | from 400 to 2400 nm |

**Soil-Vegetation-Atmophere interactions**

![image](https://github.com/user-attachments/assets/74685153-ec0b-44e3-8e44-1a101485712f)


------------------------------------------------------------------------

**The required input data are divided into:**

```         
  1.1 Meteorological and vegetation properties time series inputs
  
  1.2 Site-specific characteristics

  1.3 Soil Initial Conditions
  
  1.4 Soil Properties

  1.5 Constants and model settings
```

------------------------------------------------------------------------
#### 1.1 Time Series inputs (vectors .dat)

| symbol | variable                     |   unit    | observation         |
|:-------|:-----------------------------|:---------:|:--------------------|
| rain\_ | Precipitation                | [cm s-1]  | 1 cm/s = 36000 mm/h |
| Ta\_   | Air Temperature              |   [°C]    |                     |
| RH\_   | Relative Humidity            |    [%]    | 0 \<= RH \<= 100    |
| p\_    | Atmospheric Pressure         |   [hPa]   |                     |
| u\_    | Wind speed                   |  [m s-1]  | u \>= 0.05          |
| CO2\_  | Carbon Dioxide Concentration | [mg m-3]  |                     |
| Rin\_  | Incoming Shortwave Radiation |  [W m-2]  |                     |
| Rli\_  | Incoming Longwave Radiation  |  [W m-2]  |                     |
| LAI\_  | Leaf Area Index              | [m2 m-2]  | LAI \>= 0.01        |
| ea\_   | Air Vapor Pressure           |   [hPa]   | eq-01               |
| VPD\_  | Vapor Pressure Deficit       |   [hPa]   | eq-02               |
| tts\_  | Zenith Solar Angle           |    [-]    |                     |
| t\_    | Timestamp (doy_float)        |    [-]    | decimal Julian day  |
| year\_ | Year                         | [integer] | Calendar year       |
| Cab\_  | Chlorophyll ab               | [ug cm-2] |                     |
| hc\_   | Canopy Height                |    [m]    | hc \>= 0.01         |

### $`ea = 6.107*10^{7.5 * Ta \choose 237.3 + Ta}* {RH\choose 100}`$            **(eq-01)** 

### $`VPD = 6.107*10^{7.5 * Ta \choose 237.3 + Ta}* 1 - {RH\choose 100}`$       **(eq-02)**

------------------------------------------------------------------------
#### 1.2 Site-specific characteristics

| symbol | variable | unit | observation |
|:---------------|:---------------------|:--------------:|:------------------|
| sitename | Name on the site | string | 2 chr - 3 chr (DE-C01) |
| Dur_tot | Number of timestamps | double |  |
| DELT | Timestep size in seconds | double | 60x30min or 60x60min hourly |
| latitude | Latitude (x) | degree |  |
| longitude | Longitude (y) | degree |  |
| elevation | Altitude (DEM) | [m] |  |
| reference_height | Measurement Height (z) | [m] |  |
| IGBP_veg_long | Long name IGBP vegetation class | string |  |
| canopy_height | Canopy Height (hc) | [m] |  |

------------------------------------------------------------------------
#### 1.3 Soil Initial Conditions (soil_init.mat)

| symbol | variable | unit | observation |
|:-----------|:-----------|:----------:|:------------------------------------|
| SWC | Initial soil water content | m3 m-3 | “volumetric soil water” layer 1 to 4 (swvl1, swvl2, swvl3, swvl4) |
| Ts | Initial soil temperature | °C | "Skin temperature” (skt) and “Soil temperature” level 1 to 4 (stl1, stl2, stl3, stl4) |

note: data from CDS ERA5 Land

------------------------------------------------------------------------
#### 1.4 Soil Properties (soil_parameters.mat)

| symbol | variable | unit | observation |
|:--------------|:-----------------|:-------------:|:----------------------|
| SaturatedK<sup>1</sup> | Saturated hydraulic conductivity | [cm s-1] | 1x6 [Ks]/(24\*3600) *cm d-1* |
| ks0<sup>1</sup> | First element of SaturatedK vector | [cm s-1] | 1x1 |
| porosity<sup>1</sup> | Porosity | [m3 m-3] | 1x6 [thetas] |
| theta_s0<sup>1</sup> | First element of porosity vector | [m3 m-3] | 1x1 |
| SaturatedMC<sup>1</sup> | Saturated SWC | [m3 m-3] | 1x6 [thetas] |
| ResidualMC<sup>1</sup> | Residual SWC | [m3 m-3] | 1x6 [thetar] |
| Coefficient_Alpha<sup>1</sup> | Coefficient Alpha | [cm-1] | 1x6 [alpha] |
| Coefficient_n<sup>1</sup> | Coefficient n | [-] | 1x6 [n] |
| fieldMC<sup>2</sup> | Field Capacity | [m3 m-3] | 6x1 |
| FOS<sup>3</sup> | Sandy Fraction | fraction (/100) | 6x1x1 [SAND1/2] |
| FOC<sup>3</sup> | Clay | fraction (/100) | 6x1x1 [CLAY1/2] |
| MSOC<sup>3</sup> | Organic Fraction (Carbon) | fraction (/10000) | 6x1x1 [OC1/2] |
| fmax |  | [-] | 1x1 surfdata |
| Coef_Lamda<sup>4</sup> | Lambda per depth | [-] | 6x1x1 Lambda folder |

<sup>[1]</sup> Derived from the **PTF_SoilGrids_Schaap** datasets (*n, alpha, Ks, thetas, thetar) from the valid depths: 0, 5, 15, 30, 60, 100 and 200 cm (sl1* to sl7), excluding *sl3 (15cm).*

<sup>[2]</sup> Calculated field capacity form field moisture content\
#### $`fieldMC = theta_r + (theta_s - theta_r) / (1 + (alpha*phi_fc)^{coef_n})^{(1 - (1 / coef_n))}`$            **(eq-03)** 

*where phifc = 341.9 - soil water potential at field capacity (cm)*

<sup>3</sup> Both layers (1, 2) are combined, and the values from depths 1,3,5,6,7,8 are used per variable

<sup>4</sup> Only the Lambda file layers l1, l3, l5, l6, l7, l8 (depth_indices) were combined and used

### To download global maps to extract the above variables run the follow code:

```
# the file is 24GB, so you may need more time ...
# download, unzip in the folder ../input/SoilProperty/ using ...                       
download_SoilProperty("D:/model/rSTEMMUS_SCOPE/", timeout = 1000)   

# extract to your location using the argument latitude and longitude (+proj=longlat +datum=WGS8)
Soil_property_loc1 <- get_SoilProperties(patch = "D:/model/rSTEMMUS_SCOPE/input/SoilProperty/",
                                         lon = 107.688,
                                         lat = 37.829)
```

##### note: you can also download manually from https://zenodo.org/api/records/15488066/files/SoilProperty.zip/content, then unzip and place it in "D:/model/rSTEMMUS_SCOPE/input/" or inside the "input" folder in your patch choice
------------------------------------------------------------------------
#### 1.5 Constants and model settings
Use functions of the family "info", "check" and "change" to get more information about which constant (model parameters) and model settings from STEMMUS and SCOPE can be changed to calibrate the model for the site characteristics.

---

## 🧭 Simulation Run Catalog

All simulation runs executed during the 2026 development cycle for the Steglitz (DE-STG) site.

<details>
<summary><b>All Runs & Validation Results (Click to Expand)</b></summary>

<br>

#### Complete Run History (16 runs)

| # | Run Name | Engine | Period | Timesteps | Key Result | Date |
|:--|:---------|:-------|:-------|:----------|:-----------|:-----|
| 1 | `Parallel_LAI_1–5` (5 runs) | Octave | 1 day each | 24 each | ✅ 4.7× speedup, zero conflicts | 2026-03-06 |
| 2 | `Test_FIXED_6mo_OCTAVE_2026Feb11` | Octave | Jan–Jun 2019 | 4,344 | 92% recovered after SIGHUP crash, r=0.325 (early, pre-fix) | 2026-02-11 |
| 3 | `Test_FIXED_TempSMC_3d_Zerorain_OCTAVE_2026Feb24` | Octave | Jan 1–3, 2019 | 72 | Rain=0 produces same wet bias → drainage bug isolated | 2026-02-24 |
| 4 | `7Day_SoilEvap_Test_2026Mar` | Octave | 7 days | 168 | Soil evaporation diagnostic | 2026-03 |
| 5 | `Test_FIXED_Final_6mo_OCTAVE_2026Mar13` | Octave | Jan–Jun 2019 | 4,344 | Final 6mo after all fixes, r=0.901 (Octave vs MATLAB) | 2026-03-13 |
| 6 | `Test_FIXED_Final_2yr_OCTAVE_2026Apr07` | Octave | 2019–2020 | 17,544 (part 1) | First 2yr Octave attempt | 2026-04-07 |
| 7 | `Test_FIXED_Final_2yr_OCTAVE_part2_2026Apr08` | Octave | 2019–2020 | 17,544 (part 2) | Stitched continuation of run #6 | 2026-04-08 |
| 8 | `2yr_continuous_final_2026Apr11` | Octave | 2019–2020 | 17,544 | Full continuous 2yr, 8.3 hours | 2026-04-11 |
| 9 | `2yr_continuous_final_MATLAB_2026Apr16` | MATLAB | 2019–2020 | 17,544 | Continuous 2yr MATLAB, 34.5 hours (no soil props → r=0.145) | 2026-04-16 |
| 10 | `2yr_final_soilprops_OCTAVE_2026Apr20` | Octave | 2019–2020 | 17,544 | **Definitive Octave run** with soil properties, r=0.832 at 60cm | 2026-04-20 |
| 11 | `2yr_final_soilprops_MATLAB_2026Apr21` | MATLAB | 2019–2020 | 17,544 | Intermediate MATLAB run with soil props | 2026-04-21 |
| 12 | `2yr_final_soilprops_MATLAB_2026Apr22` | MATLAB | 2019–2020 | 17,544 | **Definitive MATLAB run**, r=0.857 at 60cm, 73 min | 2026-04-22 |
| 13 | `theta_r_guard_test_MATLAB_2026May10` | MATLAB | Jan 1–3, 2019 | 72 | ✅ theta_r floor guard smoke test passed | 2026-05-10 |

---

#### 📍 Definitive Validation Results (Runs #10 and #12)

The definitive 2yr simulations with DE-STG Van Genuchten soil properties:

**MATLAB vs Observations (by depth):**

| Depth | r | KGE | RMSE (m³/m³) | Bias (m³/m³) |
|:------|:--|:----|:-------------|:-------------|
| 10 cm | 0.577 | -0.355 | 0.113 | +0.094 |
| 20 cm | 0.663 | -2.401 | 0.127 | +0.116 |
| 30 cm | 0.636 | -1.200 | 0.105 | +0.089 |
| **60 cm** | **0.857** | **0.718** | **0.060** | **-0.049** |

**Engine Parity (MATLAB vs Octave) — ✅ PASS at all depths:**

| Depth | r | RMSE | Bias |
|:------|:--|:-----|:-----|
| 10 cm | 0.851 | 0.044 | +0.001 |
| 20 cm | 0.843 | 0.040 | -0.000 |
| 30 cm | 0.841 | 0.041 | -0.002 |
| 60 cm | 0.830 | 0.042 | -0.004 |

> **Validation Plots:** [`2026Contributions/validation_plots_multidepth/`](./2026Contributions/validation_plots_multidepth/)

---

### High-Performance Parallelization Benchmark

To validate the multi-core architectural overhaul, a **5-core Parallel Smoke Test** was executed on 2026-03-06. The test successfully ran 5 concurrent 1-day simulations (24 timesteps each) with independent Leaf Area Index (LAI) multipliers for each process.

> **Test Script:** [`2026Contributions/scripts/utils/test_parallel.R`](./2026Contributions/scripts/utils/test_parallel.R)
> **Hardware:** Apple M4 (10-core CPU)

| Metric | Serial Execution (Old) | Parallel Execution (New) | Speedup |
|---|---|---|---|
| **Simulation Batch** | 5 Runs x 1 Day | 5 Runs x 1 Day | — |
| **Total Wall Time** | ~12.5 Minutes | **2.65 Minutes** | **~4.7x** |
| **CPU Utilization** | 1 Core | 5 Cores | **500%** |
| **Conflict Risk** | N/A | **Zero** (Isolated `runs/` trees) | Fixed |

#### 📊 Smoke Test Results (5-Run Batch)

| Run ID | Parameter Variation | Status | Duration |
|---|---|---|---|
| `Parallel_LAI_1` | LAI x 1.0 | ✅ SUCCESS | 2.58m |
| `Parallel_LAI_2` | LAI x 1.5 | ✅ SUCCESS | 2.56m |
| `Parallel_LAI_3` | LAI x 2.0 | ✅ SUCCESS | 2.55m |
| `Parallel_LAI_4` | LAI x 2.5 | ✅ SUCCESS | 2.54m |
| `Parallel_LAI_5` | LAI x 3.0 | ✅ SUCCESS | 2.54m |

---

### 🔍 Current Status & Open Issues

**3-Engine validation (DE-STG, 2yr, SMC @ 60 cm vs observations, n = 17 543 hourly pairs):**

| Engine | Build | r | KGE | RMSE [m³/m³] | Bias [m³/m³] |
|:--|:--|---:|---:|---:|---:|
| MATLAB R2025b | source + all fixes + soil props (Apr 22) | 0.857 | 0.718 | 0.060 | −0.049 |
| MCR R2024a | compiled binary, license-free (May 15) | 0.843 | 0.696 | 0.055 | −0.043 |
| Octave 11.1.0 | pre-`theta_r` baseline (Apr 20) | 0.832 | 0.684 | 0.061 | −0.045 |
| Octave vs MATLAB | engine parity | 0.830 | 0.776 | 0.042 | −0.004 |
| MCR vs MATLAB | binary fidelity | 0.951 | 0.849 | 0.021 | +0.006 |

| Priority | Issue | Status |
|---|---|---|
| ✅ | Octave soil drainage / `KL_h` matrix corruption (nested-function scoping) | **Fixed Mar 13** — `calculateHydraulicConductivity.m` refactor |
| ✅ | Energy balance Newton-Raphson divergence in Octave | **Fixed Mar 13** — `ebal.m` damping schedule + NaN guards |
| ✅ | Precipitation handling | **Eliminated Feb 24** — zero-rain experiment |
| ✅ | Multi-depth engine parity | **PASS** at 10, 20, 30, 60 cm (May 10, MATLAB↔Octave bias < 0.004 m³/m³ at every depth) |
| ✅ | MATLAB NaN/complex cascade with site-specific Van Genuchten parameters | **Fixed Apr 22** — defensive guards in 5 files |
| ✅ | Octave xlsx read on Windows (`unzip` missing from PATH) | **Fixed May 21** — pure-Octave `readXlsxNative.m` via `tar.exe` |
| 🟡 | Octave dry-period collapse (SMC → 0 in Jul–Oct 2020) | `theta_r` floor guard added in `calculateTheta_LL.m`; 2yr rerun in progress |
| 🟡 | MCR clean-machine validation (Windows box without MATLAB installed) | Manual step — binary attached to GitHub Release |

</details>
