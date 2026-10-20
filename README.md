# rSTEMMUS_SCOPE

Run the STEMMUS_SCOPE model from R. STEMMUS_SCOPE couples SCOPE, a radiative transfer and energy balance
model (see https://github.com/AlbyDR/rSCOPE), with STEMMUS, a two-phase mass and heat transfer model in the
soil. For the coupling itself see this [reference](https://gmd.copernicus.org/articles/14/1379/2021/) and the
[STEMMUS_SCOPE documentation](https://ecoextreml.github.io/STEMMUS_SCOPE).

Based on the [rSTEMMUS_SCOPE](https://github.com/EcoExtreML/rSTEMMUS_SCOPE) package by Alby Duarte Rocha
(EcoExtreML); 2026 Octave/MATLAB/MCR fixes, setup tooling and validation by Arman Shirzad.

This repository contains the R package, the model source (`rSTEMMUS_SCOPE/src/`, with the 2026 fixes for
Octave and MATLAB), the input templates, a smoke test and a site template. Everything below works from a
fresh clone; nothing has to be downloaded from elsewhere.

------------------------------------------------------------------------

## Getting started

### 1. Requirements

| | Needed | Notes |
|:--|:--|:--|
| R | 4.1 or newer | `bootstrap.R` installs every R package the workflow needs |
| Git | any (optional) | to clone the repository; without Git, use **Code → Download ZIP** on GitHub and unzip it |
| One model engine | GNU Octave 8.0+ (free), MATLAB R2021a+, or the MATLAB Runtime with the compiled binary | see [Execution engines](#execution-engines); Octave is the free default |

Octave and MATLAB are found automatically in their standard install folders (on Windows under
`C:\Program Files`); the Windows Octave installer already includes the `io` and `statistics` packages the
model needs. Rtools is not needed.

**Windows:** put the repository in a short folder outside OneDrive, for example `C:\rstemmus`. Folder names
with spaces work, but very long paths do not (see [Troubleshooting](#troubleshooting)).

### 2. Install

Get the repository (or download and unzip the ZIP instead):

```bash
git clone https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public.git
```

Then run `bootstrap.R` from the repository folder, in either of two ways:

- **From R or RStudio (works on every system):**

  ```r
  setwd("C:/rstemmus/rSTEMMUS_SCOPE-public")   # the folder you cloned or unzipped
  source("bootstrap.R")
  ```

- **From a terminal:** `Rscript bootstrap.R`, run inside the repository folder. On Windows the R installer
  does not put `Rscript` on `PATH`, so a plain `Rscript` gives "not recognized"; use the full path instead,
  e.g. `"C:\Program Files\R\R-4.5.3\bin\Rscript.exe" bootstrap.R` (adjust the R version), or use the R route
  above.

`bootstrap.R` installs the CRAN and Bioconductor dependencies as prebuilt packages (the first time this can
take several minutes), extracts the input templates in `rSTEMMUS_SCOPE/`, and runs `verify_install()`.
It ends with:

```
PASS — ready to run simulations.
```

If it prints `FAIL` or `PARTIAL` instead, each missing component is listed with the command that fixes it.
You can repeat the check at any time from an R session started in the repository folder:

```r
devtools::load_all(".")
verify_install()
```

### 3. Check that the model runs (about 1 minute)

From R or RStudio, in the repository folder:

```r
source("examples/minimal_synthetic_run.R")          # GNU Octave
Sys.setenv(STEMMUS_ENGINE = "matlab")                # or MATLAB ("mcr" for the MATLAB Runtime) ...
source("examples/minimal_synthetic_run.R")          # ... then run it again
```

or from a terminal (with the full `Rscript.exe` path on Windows, see step 2):

```bash
Rscript examples/minimal_synthetic_run.R            # GNU Octave
Rscript examples/minimal_synthetic_run.R matlab     # MATLAB
```

This runs one synthetic summer day (24 hourly steps, no observations needed) through the complete workflow
and checks that the output is finite and physically plausible. It ends with:

```
  SMC 15 cm: 0.287 -> 0.302 m3/m3 | daily ET: 2.47 mm
Smoke test PASSED
```

Results are written to `rSTEMMUS_SCOPE/output/SYN-01_smoke_<ENGINE>_<date>/`. Read
[`examples/minimal_synthetic_run.R`](https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/blob/main/examples/minimal_synthetic_run.R)
as a complete, short example of the four steps described in [step 5](#5-the-four-functions-behind-a-run).

### 4. Run your own site

**a. Prepare the forcing file.** One `.rds` file holding a data frame with one row per time step (hourly)
and these 19 columns:

| column | content | unit |
|:--|:--|:--|
| `timestamp` | time of the step | `POSIXct`, UTC |
| `Rin`, `Rli` | incoming shortwave and longwave radiation | W m-2 |
| `p` | air pressure | hPa |
| `Ta` | air temperature | °C |
| `RH` | relative humidity | % |
| `ea` | vapour pressure | hPa |
| `ws` | wind speed | m s-1 |
| `prec_mm_EC` | precipitation | mm per hour |
| `LAI_FP` | leaf area index | m2 m-2 |
| `co2_flux` | required by the validator, not used (CO2 is set to a constant in the template) | |
| `soil_temp10cm`, `soil_temp20cm`, `soil_temp30cm`, `soil_temp50cm` | soil temperature; the first row is the initial condition | °C |
| `SMC_10cm`, `SMC_20cm`, `SMC_30cm`, `SMC_60cm` | soil moisture; the first row is the initial condition | % (volumetric) |

Check it before running anything. This catches the unit mistakes that otherwise only show up as nonsense
output (soil moisture given as a fraction, soil temperature given in Kelvin):

```r
devtools::load_all(".")
validate_weather_rds("path/to/your_site.rds")
```

**b. Copy the template** and edit only its `[SECTION 2]` (site name, engine, time window, path to the forcing
file, coordinates, elevation, vegetation class, canopy height):

```r
file.copy("2026Contributions/scripts/runs/standardRoadmapLocation2.R", "roadmap_MySite.R")
```

The template is
[`standardRoadmapLocation2.R`](https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/blob/main/2026Contributions/scripts/runs/standardRoadmapLocation2.R).
It converts the units for you (°C to K, % to fraction), checks the installation and the forcing file before
it starts, and its `[SECTION 6]` shows how to run several simulations in parallel. Valid vegetation classes
are listed by `info_IGBP_classes()`.

**c. Run it** from the repository folder, in R / RStudio or a terminal:

```r
source("roadmap_MySite.R")      # terminal: Rscript roadmap_MySite.R
```

It prints `Status: SUCCESS` at the end. Inputs are written to `rSTEMMUS_SCOPE/runs/<site>_<run>/` (including
`engine_stdout.log` and `engine_stderr.log`, the first place to look when a run fails) and results to
`rSTEMMUS_SCOPE/output/<site>_<run>_<date>/`; see [Main model outputs](#main-model-outputs) for the files.

### 5. The four functions behind a run

The template and the smoke test both call the same four functions. To write your own script, call them in
this order (all paths relative to the repository folder; full argument lists in `?new_run` etc.):

```r
devtools::load_all(".")
patch <- paste0(getwd(), "/rSTEMMUS_SCOPE/")

# 1. create runs/<site>_<run>/ from the input templates
new_run(patch = patch, StartTime = "2019-07-01T00:00", EndTime = "2019-07-01T23:00",
        site_name = "MY-SITE", run_name = "run01")

# 2. site constants and initial conditions
#    soil temperature in Kelvin, soil moisture as a volumetric fraction (m3 m-3)
input_constants(patch = patch, site_name = "MY-SITE", run_name = "run01",
                LAT = 52.46, LON = 13.32, elevation = 50,
                IGBP_veg_long = "Grassland", hc = 0.5,
                n_timestamps = 24, timestep_min = 60,
                initial_soil_temperature = data.frame(skt = 290.15, stl1 = 290.15, stl2 = 289.15,
                                                      stl3 = 288.15, stl4 = 287.15),
                initial_volumetric_soil_water = data.frame(swvl1 = 0.25, swvl2 = 0.26,
                                                           swvl3 = 0.27, swvl4 = 0.28),
                startDOY = 182, endDOY = 182, timezn = 1)

# 3. time series, one value per step (units in section 1.1 below);
#    my_forcing is your data frame, my_doy its decimal day of year
input_timeseries(patch = patch, site_name = "MY-SITE", run_name = "run01",
                 t_file = my_doy, year_file = my_year,
                 Rin_file = my_forcing$Rin, Rli_file = my_forcing$Rli, p_file = my_forcing$p,
                 Ta_file = my_forcing$Ta, RH_file = my_forcing$RH, ea_file = my_forcing$ea,
                 VPD_file = my_vpd, u_file = my_forcing$ws,
                 rain_file = my_forcing$prec_mm_EC / 36000,      # mm per hour -> cm s-1
                 LAI_file = my_forcing$LAI_FP, CO2_file = rep(415, 24))

# 4. run the model
run_inMATLAB(patch = patch, site_name = "MY-SITE", run_name = "run01",
             exe_method = "octave")                             # or "matlab" / "mcr"
```

[`run_steps.md`](https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/blob/main/run_steps.md) walks through
the same steps for a half-hourly case and then shows how to read and plot `Sim_Theta.csv` and `fluxes.csv`
and score them against observations.

------------------------------------------------------------------------

## Forcing data: what is and is not included

The model source, the R package and the input templates are all in this repository. **Eddy-covariance
observations are not included.** The Berlin-Steglitz (DE-STG) and TUB Campus Charlottenburg (TUCC) records
used in our own runs are operated by the Chair of Climatology, Technische Universitaet Berlin, as part of the
Urban Climate Observatory Berlin, and are available from the site operators on reasonable request.

This matters if you run one of the scripts under `2026Contributions/scripts/runs/` directly. Several of them
begin with a line such as

```r
steg_df <- readRDS("2026Contributions/EC_DWD_ROTH_clean.rds")
```

and that file is deliberately absent, so the script stops there. Those scripts are published as worked
examples of how our sites were configured, not as runnable demonstrations. For your own site, use the
template as described in [step 4](#4-run-your-own-site).

------------------------------------------------------------------------

## Execution engines

Pick one with `exe_method` in `run_inMATLAB()` (the template sets it in `[SECTION 2]`):

| Engine | `exe_method` | License | Required version | Notes |
|:--|:--|:--|:--|:--|
| **GNU Octave** | `"octave"` | Free (GPL) | 8.0+ — tested on 11.1.0 with `io` + `statistics` packages | Cross-platform; on Windows the bundled `tar.exe` is used to parse xlsx (no system `unzip` needed) |
| **MATLAB** | `"matlab"` (the function default) | Commercial | R2021a+ (uses the `-batch` flag) | Fastest on Windows |
| **MATLAB Runtime** | `"mcr"` | Free, redistributable | R2024a Runtime (~3 GB, free from MathWorks) | Needs a `STEMMUS_SCOPE_exe` binary built once with [src/compile_stemmus_scope.m](https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/blob/main/rSTEMMUS_SCOPE/src/compile_stemmus_scope.m) on a machine with MATLAB + MATLAB Compiler; no prebuilt binary is published. Without MATLAB, use Octave |

For the same input, MATLAB and Octave give the same smoke-test result; the 2-year engine comparison is in the
[Simulation Run Catalog](#-simulation-run-catalog).

------------------------------------------------------------------------

## Troubleshooting

- **R can't find Octave / MATLAB / MCR**: [run_inMATLAB.R](https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/blob/main/R/run_inMATLAB.R) searches `C:\Program Files\GNU Octave\*`, `C:\Program Files\MATLAB\R*`, and `C:\Program Files\MATLAB\MATLAB Runtime\v*` on Windows (and `/Applications`, `/usr/local/MATLAB`, `/opt/MATLAB` on Unix). If your install is elsewhere, prepend its `bin/` to `PATH` before `Rscript`, or set `STEMMUS_SCOPE_EXE` to the compiled binary path.
- **A run finishes but the output folder is empty**: read `rSTEMMUS_SCOPE/runs/<site>_<run>/engine_stderr.log`; the engine's error is there, not in the R console.
- **`git clone` fails on Windows with `Filename too long`**: clone into a short folder (for example `C:\Users\<you>\rstemmus`), or enable long paths once with `git config --global core.longpaths true`.
- **Octave fails with `error: xlsopen ... unzip`**: Octave's `io` package shells out to `unzip` to read xlsx. On Windows installs without `unzip` on PATH, [src/+io/readXlsxNative.m](https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/blob/main/rSTEMMUS_SCOPE/src/+io/readXlsxNative.m) is used as a fallback (via the bundled `tar.exe`) — no action needed.
- **Background launches hang at timestep 0**: if Rscript is launched without a console on Windows, the engine would deadlock writing to a closed stdout. `run_inMATLAB()` redirects engine output to `engine_stdout.log` / `engine_stderr.log` in the run folder to avoid this.
- **Soil temperatures or SMC look physically impossible (e.g. −267 °C, 25 m³/m³)**: `input_constants()` takes soil temperature in Kelvin (`+273.15`) and soil moisture as a fraction (`/100`). The template does both conversions; `validate_weather_rds()` flags a forcing file in the wrong units.
- **You installed from another copy or fork of this repository** and results differ from ours: older versions of `initial_setup()` unpacked `rSTEMMUS_SCOPE/src.zip` (the original upstream code) over `src/` and so removed the model fixes. Clone this repository again and rerun `Rscript bootstrap.R`; `src.zip` is no longer part of the repository.
- **The upstream package** `EcoExtreML/rSTEMMUS_SCOPE` is not the same code: it has no `verify_install()`, `validate_weather_rds()`, Octave or MCR support, and none of the model fixes. Use this repository as described above.

------------------------------------------------------------------------

## Repository layout

```
rSTEMMUS_SCOPE-public/
├── bootstrap.R                  one-command setup (step 2)
├── R/                           the R package: new_run(), input_constants(), input_timeseries(),
│                                run_inMATLAB(), verify_install(), validate_weather_rds(), ...
├── examples/
│   └── minimal_synthetic_run.R  smoke test (step 3)
├── run_steps.md                 the four steps plus output analysis
├── rSTEMMUS_SCOPE/              the model tree ("patch" in the R functions)
│   ├── src/                     STEMMUS_SCOPE model code (MATLAB/Octave)
│   ├── input/                   input templates   (extracted from input.7z by bootstrap.R)
│   ├── runs/                    one folder per run (extracted from runs.7z, then filled by new_run())
│   └── output/                  one folder per run with the results
├── 2026Contributions/
│   ├── scripts/runs/            site template (standardRoadmapLocation2.R) and our site scripts
│   └── docs/, validation_plots*/  validation and ablation results
└── tools/check_docs.R           checks that the R code in these docs runs and the links resolve
```

`rSTEMMUS_SCOPE/runs/AR-SLu_2024-01-25-0911/` is the example run shipped with the upstream input templates.
Its config file holds absolute `D:/model/rSTEMMUS_SCOPE/` paths, so it only runs with the model tree at exactly
that location; use the smoke test instead.

------------------------------------------------------------------------

## Main model outputs

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
| Ts | Initial soil temperature | K | "Skin temperature” (skt) and “Soil temperature” level 1 to 4 (stl1, stl2, stl3, stl4); pass Kelvin as ERA5-Land delivers it, `input_constants()` converts to °C |

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

```r
devtools::load_all(".")
patch <- paste0(getwd(), "/rSTEMMUS_SCOPE/")

# the file is 24GB, so you may need more time ...
# downloads and unzips into rSTEMMUS_SCOPE/input/SoilProperty/
download_SoilProperty(patch, timeout = 1000)

# extract to your location using the argument latitude and longitude (+proj=longlat +datum=WGS8)
Soil_property_loc1 <- get_SoilProperties(patch = paste0(patch, "input/SoilProperty/"),
                                         lon = 107.688,
                                         lat = 37.829)
```

Pass the result to `input_constants(..., soil_property_list = Soil_property_loc1)`; in the template this is the
commented `soil_property_list` line in `[SECTION 4]`.

##### note: you can also download manually from https://zenodo.org/api/records/15488066/files/SoilProperty.zip/content, then unzip it into `rSTEMMUS_SCOPE/input/` of your clone
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

> **Validation Plots:** [`2026Contributions/validation_plots_multidepth/`](https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/tree/main/2026Contributions/validation_plots_multidepth)

---

### High-Performance Parallelization Benchmark

To validate the multi-core architectural overhaul, a **5-core Parallel Smoke Test** was executed on 2026-03-06. The test successfully ran 5 concurrent 1-day simulations (24 timesteps each) with independent Leaf Area Index (LAI) multipliers for each process.

> **Test Script:** [`2026Contributions/scripts/utils/test_parallel.R`](https://github.com/ArmanShirzad/rSTEMMUS_SCOPE-public/blob/main/2026Contributions/scripts/utils/test_parallel.R)
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
| 🟡 | MCR clean-machine validation (Windows box without MATLAB installed) | Manual step — binary is built locally with `compile_stemmus_scope.m`, not published yet |

</details>
