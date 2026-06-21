library(lubridate)
project_root <- "/Users/armanmacair/repos/Stemmus-Scope/rSTEMMUS_SCOPE"
octave_theta_file <- file.path(project_root, "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_Test_FIXED_Final_6mo_OCTAVE_2026Mar13_1846/Sim_Theta.csv")
matlab_theta_file <- file.path(project_root, "2026Contributions/validation_plots/Sim_Theta.csv")
obs_file <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")

raw_oct <- read.csv(octave_theta_file, header=FALSE)
cat("Octave rows:", nrow(raw_oct), "\n")

raw_mat <- read.csv(matlab_theta_file, header=FALSE)
cat("MATLAB rows:", nrow(raw_mat), "\n")

obs_raw <- readRDS(obs_file)
cat("Observation rows:", nrow(obs_raw), " Time diff:", difftime(obs_raw$timestamp[2], obs_raw$timestamp[1], units="mins"),"mins\n")
