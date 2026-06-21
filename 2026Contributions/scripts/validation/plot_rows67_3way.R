# ============================================================
# plot_rows67_3way.R
# 3-Way SMC Comparison: Row 6 (1-day) and Row 7 (7-day)
# ============================================================

library(tidyverse)
library(lubridate)
library(hydroGOF)

project_root <- "/Users/armanmacair/repos/Stemmus-Scope/rSTEMMUS_SCOPE"
obs_file <- file.path(project_root, "2026Contributions/EC_DWD_ROTH_clean.rds")
matlab_theta_file <- file.path(project_root, "2026Contributions/validation_plots/Sim_Theta.csv")
output_dir <- file.path(project_root, "2026Contributions/validation_plots/20260408_Final1Day7Day_3way")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

extract_smc_60cm <- function(theta_file, label) {
  raw <- read.csv(theta_file, header = FALSE)
  depths <- as.numeric(raw[1, ])
  idx_60cm <- which(depths == 60)
  if (length(idx_60cm) == 0) {
    idx_60cm <- which.min(abs(depths - 60))
  } else {
    idx_60cm <- idx_60cm[1]
  }
  as.numeric(raw[-(1:3), idx_60cm])
}

cat("Loading observations...\n")
obs_raw <- readRDS(obs_file)

cat("Loading MATLAB...\n")
matlab_smc <- extract_smc_60cm(matlab_theta_file, "MATLAB")
matlab_start <- min(obs_raw$timestamp, na.rm = TRUE)
matlab_df_full <- tibble(
  timestamp = matlab_start + hours(0:(length(matlab_smc) - 1)),
  matlab_SMC = matlab_smc
)

plot_run <- function(run_name, title, output_png, start_date, end_date, octave_file) {
  cat(sprintf("\n=== Processing %s ===\n", run_name))
  
  obs_df <- obs_raw %>%
    filter(timestamp >= as.POSIXct(start_date, tz = "UTC"),
           timestamp <= as.POSIXct(end_date, tz = "UTC")) %>%
    select(timestamp, obs_SMC = SMC_60cm) %>%
    mutate(obs_SMC = obs_SMC / 100)
    
  matlab_df <- matlab_df_full %>%
    filter(timestamp >= as.POSIXct(start_date, tz = "UTC"),
           timestamp <= as.POSIXct(end_date, tz = "UTC"))
           
  octave_smc <- extract_smc_60cm(octave_file, "Octave")
  octave_df <- tibble(
    timestamp = as.POSIXct(start_date, tz = "UTC") + hours(0:(length(octave_smc) - 1)),
    octave_SMC = octave_smc
  )
  
  combined <- obs_df %>%
    left_join(matlab_df, by = "timestamp") %>%
    left_join(octave_df, by = "timestamp")
    
  valid <- combined %>% filter(!is.na(obs_SMC), !is.na(matlab_SMC), !is.na(octave_SMC))
  
  if(nrow(valid) > 0) {
      kge_matlab <- KGE(valid$matlab_SMC, valid$obs_SMC, out.type = "full")
      kge_octave <- KGE(valid$octave_SMC, valid$obs_SMC, out.type = "full")
      
      annotation_text <- paste0(
        "MATLAB vs Obs\n",
        sprintf("  Alpha   : %.3f\n",  kge_matlab$KGE.elements["Alpha"]),
        sprintf("  Beta    : %.3f\n",  kge_matlab$KGE.elements["Beta"]),
        sprintf("  KGE     : %.3f\n\n", kge_matlab$KGE.value),
        "Octave vs Obs\n",
        sprintf("  Alpha   : %.3f\n",  kge_octave$KGE.elements["Alpha"]),
        sprintf("  Beta    : %.3f\n",  kge_octave$KGE.elements["Beta"]),
        sprintf("  KGE     : %.3f",    kge_octave$KGE.value)
      )
  } else {
      annotation_text <- "Insufficient Data"
  }
  
  plot_df <- combined %>%
    select(timestamp, obs_SMC, matlab_SMC, octave_SMC) %>%
    pivot_longer(cols = c(obs_SMC, matlab_SMC, octave_SMC),
                 names_to = "source", values_to = "SMC") %>%
    mutate(source = recode(source,
      obs_SMC    = "Observations",
      matlab_SMC = "MATLAB",
      octave_SMC = "Octave"
    ))
    
  p <- ggplot(plot_df, aes(x = timestamp, y = SMC, color = source, linewidth = source)) +
    geom_line(alpha = 0.88) +
    scale_color_manual(values = c(
      "Observations"      = "black",
      "MATLAB"            = "#2166AC",
      "Octave"            = "#B2182B"
    )) +
    scale_linewidth_manual(values = c(
      "Observations"      = 1.0,
      "MATLAB"            = 0.9,
      "Octave"            = 0.9
    ), guide = "none") +
    annotate("label",
             x = as.POSIXct(start_date, tz = "UTC"), # left side
             y = 0.415,
             label = annotation_text,
             hjust = 0, vjust = 1,
             size = 3.2, family = "mono",
             fill = "white", color = "gray20") +
    coord_cartesian(ylim = c(0.05, 0.45)) +
    labs(
      title    = sprintf("Soil Moisture at 60 cm — 3-Way Comparison (%s)", run_name),
      subtitle = title,
      x        = "Date",
      y        = expression(paste("Volumetric Water Content (m"^3, " m"^-3, ")")),
      color    = "Source"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      legend.position      = "bottom",
      plot.title           = element_text(face = "bold", size = 15),
      plot.subtitle        = element_text(size = 11, color = "gray40"),
      panel.grid.minor     = element_blank(),
      legend.title         = element_blank()
    )
    
  out_file <- file.path(output_dir, output_png)
  ggsave(out_file, p, width = 14, height = 6, dpi = 150)
  cat("Saved:", out_file, "\n")
}

plot_run(
  run_name = "Row 6 (1-Day Fix)",
  title = "DE-STG Steglitz | Jan 1 2019 | Octave Final Fix",
  output_png = "01_3way_SMC_60cm_Row6_1Day.png",
  start_date = "2019-01-01 00:00:00",
  end_date = "2019-01-01 23:00:00",
  octave_file = file.path(project_root, "rSTEMMUS_SCOPE/output/DE-STG_1Day_OctaveFix_Test_2026Mar13_1446/Sim_Theta.csv")
)

plot_run(
  run_name = "Row 7 (7-Day SoilEvap Test)",
  title = "DE-STG Steglitz | Jan 1-7 2019 | Octave Final Fix",
  output_png = "01_3way_SMC_60cm_Row7_7Day.png",
  start_date = "2019-01-01 00:00:00",
  end_date = "2019-01-07 23:00:00",
  octave_file = file.path(project_root, "rSTEMMUS_SCOPE/output/DE-STG_7Day_SoilEvap_Test_2026Mar13_1502/Sim_Theta.csv")
)
