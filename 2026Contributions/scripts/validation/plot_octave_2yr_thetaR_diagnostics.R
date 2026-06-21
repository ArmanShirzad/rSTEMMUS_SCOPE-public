## Diagnostic plots from the post-theta_r Octave 2yr Roth run.
## Per user request: SMC, GPP, NEE, LE, H, G, Rn.
## Plots saved both inside the run dir (as requested) and mirrored to
## 2026Contributions/validation_plots/... so the results are tracked + pushed.

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(lubridate); library(ggplot2); library(tidyr)
})

run_dir <- "rSTEMMUS_SCOPE/output/DE-STG_DE-STG_2yr_thetaR_soilprops_OCTAVE_2026May21_1552"
in_run_dir   <- file.path(run_dir, "plots")            # as user asked
mirror_dir   <- "2026Contributions/validation_plots/20260612_octave_2yr_thetaR_diagnostics"
dir.create(in_run_dir,  showWarnings = FALSE, recursive = TRUE)
dir.create(mirror_dir,  showWarnings = FALSE, recursive = TRUE)

# ---- Load fluxes (col 1: 28 cols; row 1=header, row 2=units, row 3+ = data) ----
fluxes <- read_csv(file.path(run_dir, "fluxes.csv"),
                   skip = 2, col_names = FALSE, show_col_types = FALSE)
n <- nrow(fluxes)
ts <- seq.POSIXt(as.POSIXct("2019-01-01 00:00", tz = "UTC"),
                 by = "hour", length.out = n)

# Column map (1-indexed):
#  5 = Rntot, 6 = lEtot, 7 = Htot, 11 = Actot, 15 = Gtot,
# 16 = Resp, 24 = Trap, 25 = Evap, 26 = ET, 27 = GPP, 28 = NEE
df <- tibble(
  timestamp = ts,
  Rn   = fluxes[[5]],    # W/m^2
  LE   = fluxes[[6]],    # W/m^2
  H    = fluxes[[7]],    # W/m^2
  G    = fluxes[[15]],   # W/m^2
  Trap = fluxes[[24]] * 3600 * 24,    # mm/day
  Evap = fluxes[[25]] * 3600 * 24,    # mm/day
  ET   = fluxes[[26]] * 3600 * 24,    # mm/day
  GPP  = fluxes[[27]] * 22.73e6,      # Kg/m^2/s -> umol CO2 / m^2 / s
  NEE  = fluxes[[28]] * 22.73e6
)

# ---- Load soil moisture profile ----
theta <- read_csv(file.path(run_dir, "Sim_Theta.csv"),
                  skip = 3, col_names = FALSE, show_col_types = FALSE)
depths <- c(1,2,3,5,7,9,11,13,15,17,19,21,23,25,27.5,30,32.5,35,40,45,50,55,60,
            70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,
            245,260,280,300,320,340,360,380,400,420,440,460,480,500)
# Use sensor-equivalent depths (10, 30, 60, 100 cm)
col_at <- function(d) which.min(abs(depths - d))
smc_df <- tibble(
  timestamp = ts,
  smc_10cm  = theta[[col_at(10)]],
  smc_30cm  = theta[[col_at(30)]],
  smc_60cm  = theta[[col_at(60)]],
  smc_100cm = theta[[col_at(100)]]
)

# Daily aggregation for cleaner plots
df_d <- df |>
  mutate(date = as.Date(timestamp)) |>
  group_by(date) |>
  summarise(across(c(Rn, LE, H, G), mean, na.rm = TRUE),
            ET   = mean(ET, na.rm = TRUE),
            Trap = mean(Trap, na.rm = TRUE),
            Evap = mean(Evap, na.rm = TRUE),
            GPP  = mean(GPP, na.rm = TRUE),
            NEE  = mean(NEE, na.rm = TRUE),
            .groups = "drop")
smc_d <- smc_df |>
  mutate(date = as.Date(timestamp)) |>
  group_by(date) |>
  summarise(across(starts_with("smc"), mean, na.rm = TRUE), .groups = "drop")

save_both <- function(p, fname, w, h) {
  ggsave(file.path(in_run_dir, fname), p, width = w, height = h, dpi = 130)
  ggsave(file.path(mirror_dir, fname), p, width = w, height = h, dpi = 130)
}

# ---- Plot 1: Energy fluxes (Rn, LE, H, G) over 2yr ----
p_energy <- df_d |>
  pivot_longer(c(Rn, LE, H, G), names_to = "flux", values_to = "value") |>
  mutate(flux = factor(flux, levels = c("Rn", "LE", "H", "G"))) |>
  ggplot(aes(date, value, colour = flux)) +
  geom_line(linewidth = 0.4) +
  facet_wrap(~ flux, ncol = 1, scales = "free_y", strip.position = "right") +
  scale_colour_manual(values = c(Rn = "#e6550d", LE = "#3182bd",
                                 H = "#e31a1c", G = "#636363"),
                     guide = "none") +
  scale_x_date(date_breaks = "3 months", date_labels = "%b %Y") +
  labs(x = NULL, y = "Flux [W/m²]",
       title = "DE-STG (ROTH) — daily-mean energy fluxes, 2019–2020",
       subtitle = "STEMMUS-SCOPE Octave (post-θᵣ) 2-year continuous simulation") +
  theme_minimal(base_size = 11) +
  theme(strip.text = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1))
save_both(p_energy, "01_energy_fluxes_Rn_LE_H_G.png", 14, 9)

# ---- Plot 2: Carbon fluxes (GPP, NEE) ----
p_carbon <- df_d |>
  pivot_longer(c(GPP, NEE), names_to = "flux", values_to = "value") |>
  ggplot(aes(date, value, colour = flux)) +
  geom_hline(yintercept = 0, colour = "black", linewidth = 0.4) +
  geom_line(linewidth = 0.45) +
  facet_wrap(~ flux, ncol = 1, scales = "free_y", strip.position = "right") +
  scale_colour_manual(values = c(GPP = "#1b9e77", NEE = "#7570b3"), guide = "none") +
  scale_x_date(date_breaks = "3 months", date_labels = "%b %Y") +
  labs(x = NULL, y = "[µmol CO₂ / m² / s]",
       title = "DE-STG (ROTH) — daily-mean carbon fluxes, 2019–2020",
       subtitle = "GPP (gross primary production) and NEE (net ecosystem exchange)") +
  theme_minimal(base_size = 11) +
  theme(strip.text = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1))
save_both(p_carbon, "02_carbon_fluxes_GPP_NEE.png", 14, 6)

# ---- Plot 3: Soil moisture multi-depth ----
p_smc <- smc_d |>
  pivot_longer(starts_with("smc"), names_to = "depth", values_to = "smc") |>
  mutate(depth = factor(depth,
                        levels = c("smc_10cm","smc_30cm","smc_60cm","smc_100cm"),
                        labels = c("10 cm","30 cm","60 cm","100 cm"))) |>
  ggplot(aes(date, smc, colour = depth)) +
  geom_line(linewidth = 0.45) +
  scale_colour_brewer(palette = "Set1", name = "depth") +
  scale_x_date(date_breaks = "3 months", date_labels = "%b %Y") +
  labs(x = NULL, y = "Soil moisture [m³/m³]",
       title = "DE-STG (ROTH) — soil moisture profile, 2019–2020",
       subtitle = "Sensor-equivalent depths through post-θᵣ Octave 2-year run") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top",
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1))
save_both(p_smc, "03_soil_moisture_multidepth.png", 14, 5)

# ---- Plot 4: Combined dashboard (all 7 variables in one figure) ----
df_long <- df_d |>
  pivot_longer(c(Rn, LE, H, G, GPP, NEE), names_to = "var", values_to = "value")
df_long$var <- factor(df_long$var,
                      levels = c("Rn","LE","H","G","GPP","NEE"))
p_dash <- ggplot(df_long, aes(date, value, colour = var)) +
  geom_hline(yintercept = 0, colour = "black", linewidth = 0.3) +
  geom_line(linewidth = 0.35) +
  facet_wrap(~ var, ncol = 1, scales = "free_y", strip.position = "right") +
  scale_colour_manual(values = c(Rn = "#e6550d", LE = "#3182bd", H = "#e31a1c",
                                 G = "#636363", GPP = "#1b9e77", NEE = "#7570b3"),
                     guide = "none") +
  scale_x_date(date_breaks = "3 months", date_labels = "%b %Y") +
  labs(x = NULL, y = NULL,
       title = "DE-STG (ROTH) — 7-variable dashboard, 2019–2020",
       subtitle = "Rn / LE / H / G in W m⁻²; GPP / NEE in µmol CO₂ m⁻² s⁻¹; daily means") +
  theme_minimal(base_size = 11) +
  theme(strip.text = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1))
save_both(p_dash, "04_dashboard_7variables.png", 14, 14)

# ---- Plot 5: Monthly mean diurnal cycles (energy fluxes) ----
df_md <- df |>
  mutate(month = month(timestamp, label = TRUE, abbr = TRUE),
         year  = year(timestamp), hour = hour(timestamp)) |>
  group_by(year, month, hour) |>
  summarise(across(c(Rn, LE, H, G), mean, na.rm = TRUE), .groups = "drop")
p_diurnal <- df_md |>
  pivot_longer(c(Rn, LE, H, G), names_to = "flux", values_to = "value") |>
  ggplot(aes(hour, value, colour = factor(year))) +
  geom_hline(yintercept = 0, colour = "black", linewidth = 0.3) +
  geom_line(linewidth = 0.5) +
  facet_grid(flux ~ month, scales = "free_y") +
  scale_colour_manual(values = c("2019" = "#d95f02", "2020" = "#1b9e77"),
                      name = "year") +
  scale_x_continuous(breaks = c(0, 6, 12, 18)) +
  labs(x = "hour of day", y = "W m⁻²",
       title = "DE-STG (ROTH) — monthly diurnal cycles, energy fluxes",
       subtitle = "Each panel shows hour-of-day average across the days of that month") +
  theme_minimal(base_size = 9) +
  theme(legend.position = "top",
        strip.text = element_text(face = "bold"),
        panel.grid.minor = element_blank())
save_both(p_diurnal, "05_monthly_diurnal_energy_fluxes.png", 22, 9)

# ---- Mini-table: annual sums and means ----
annual <- df_d |>
  mutate(year = year(date)) |>
  group_by(year) |>
  summarise(Rn_W_per_m2_mean = mean(Rn, na.rm = TRUE),
            LE_W_per_m2_mean = mean(LE, na.rm = TRUE),
            H_W_per_m2_mean  = mean(H, na.rm = TRUE),
            G_W_per_m2_mean  = mean(G, na.rm = TRUE),
            ET_mm_total      = sum(ET, na.rm = TRUE),
            Trap_mm_total    = sum(Trap, na.rm = TRUE),
            Evap_mm_total    = sum(Evap, na.rm = TRUE),
            GPP_umol_mean    = mean(GPP, na.rm = TRUE),
            NEE_umol_mean    = mean(NEE, na.rm = TRUE),
            .groups = "drop")
write.csv(annual, file.path(in_run_dir, "06_annual_summary.csv"), row.names = FALSE)
write.csv(annual, file.path(mirror_dir, "06_annual_summary.csv"), row.names = FALSE)
cat("Annual summary:\n"); print(annual, digits = 4)

# README
sink(file.path(in_run_dir, "00_README.txt"))
cat("Diagnostic plots from Octave post-theta_r 2-year run\n")
cat("====================================================\n\n")
cat("Source: ", run_dir, "\n\n")
cat("Plots in this folder:\n")
cat("  01_energy_fluxes_Rn_LE_H_G.png    daily-mean energy fluxes\n")
cat("  02_carbon_fluxes_GPP_NEE.png      daily-mean carbon fluxes\n")
cat("  03_soil_moisture_multidepth.png   SMC at 10/30/60/100 cm\n")
cat("  04_dashboard_7variables.png       all 7 variables in one figure\n")
cat("  05_monthly_diurnal_energy_fluxes.png  monthly diurnal cycles\n")
cat("  06_annual_summary.csv             annual sums and means\n")
sink()
file.copy(file.path(in_run_dir, "00_README.txt"),
          file.path(mirror_dir, "00_README.txt"), overwrite = TRUE)

cat(sprintf("\nWrote outputs to:\n  %s/\n  %s/\n", in_run_dir, mirror_dir))
