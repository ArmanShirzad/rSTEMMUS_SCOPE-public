% recover_part1_2yr_bins.m
% Converts Part 1 .bin files from the crashed 2-year run to CSVs.
% Run from repo root:
%   cd rSTEMMUS_SCOPE/src
%   octave --no-gui --eval "run('../../2026Contributions/recover_part1_2yr_bins.m'); exit"
%
% Part 1 completed 4,345 timesteps: Jan 1, 2019 00:00 -> Jul 1, 2019 00:00

src_dir = 'C:/Users/armanshirzad/Repos/rSTEMMUS_SCOPE/rSTEMMUS_SCOPE/src';
addpath(src_dir);
out_dir = 'C:/Users/armanshirzad/Repos/rSTEMMUS_SCOPE/rSTEMMUS_SCOPE/output/DE-STG_DE-STG_Test_FIXED_Final_2yr_OCTAVE_2026Apr07_1524/';

% NS derived from aerodyn.bin: 9 columns × 8 bytes × NS = file size
aerodyn_info = dir([out_dir 'aerodyn.bin']);
fsize = aerodyn_info(1).bytes;
NS = fsize / (9 * 8);

[~, DeltZ_R, NL] = Dtrmn_Z(100, 500);
Ztot = cumsum(DeltZ_R);
depth     = Ztot';
thickness = DeltZ_R;

depth_str     = arrayfun(@(x) num2str(x), depth,     'UniformOutput', false);
thickness_str = arrayfun(@(x) num2str(x), thickness, 'UniformOutput', false);
soil_units    = repelem({'m-3 m-3'}, NL);
oC_units      = repelem({'oC'}, NL);
cm_units      = repelem({'cm'}, NL);
cms_units     = repelem({'cm s-1'}, NL);

fprintf('=== Part 1 Binary Recovery ===\n');
fprintf('Output dir: %s\n', out_dir);
fprintf('Timesteps: %d  |  Soil layers (NL): %d\n\n', NS, NL);

% ── helper ──────────────────────────────────────────────────────────────────
function write_csv(bin_path, csv_path, n_col, NS, header_lines, unit_line)
  if ~exist(bin_path, 'file')
    fprintf('  SKIP (missing): %s\n', bin_path); return;
  end
  fid_bin = fopen(bin_path, 'rb');
  raw = fread(fid_bin, Inf, 'double');
  fclose(fid_bin);
  data = reshape(raw, n_col, NS)';   % [NS x n_col]

  fid_csv = fopen(csv_path, 'w');
  for i = 1:length(header_lines)
    fprintf(fid_csv, '%s\n', header_lines{i});
  end
  fprintf(fid_csv, '%s\n', unit_line);
  fclose(fid_csv);
  dlmwrite(csv_path, data, '-append', 'delimiter', ',', 'precision', 16);
  fprintf('  OK  %s  (%d rows)\n', csv_path, NS);
end

% ── fluxes.csv  (n_col = 28) ─────────────────────────────────────────────
flu_hdr = strjoin({'simulation_number','nu_iterations','year','DoY', ...
  'Rntot','lEtot','Htot','Rnctot','lEctot','Hctot','Actot', ...
  'Rnstot','lEstot','Hstot','Gtot','Resp','aPAR','aPAR_Cab', ...
  'aPAR/rad.PAR','aPAR_Wm2','PAR','rad.Eoutf', ...
  'rad.Eoutf./fluxes.aPAR_Wm2','Trap','Evap','ET','GPP','NEE'}, ',');
flu_units = strjoin({'','','','','W m-2','W m-2','W m-2','W m-2', ...
  'W m-2','W m-2','umol m-2 s-1','W m-2',' W m-2','W m-2','W m-2', ...
  'umol m-2 s-1','umol m-2 s-1',' umol m-2 s-1','umol m-2 s-1', ...
  'W m-2','umol m-2 s-1','W m-2','W m-2','mm s-1','mm s-1','mm s-1', ...
  'Kg m-2 s-1','Kg m-2 s-1'}, ',');
write_csv([out_dir 'fluxes.bin'], [out_dir 'fluxes.csv'], 28, NS, {flu_hdr}, flu_units);

% ── Sim_Theta.csv  (n_col = 54) ──────────────────────────────────────────
write_csv([out_dir 'Sim_Theta.bin'], [out_dir 'Sim_Theta.csv'], NL, NS, ...
  {strjoin(depth_str, ','), strjoin(thickness_str, ',')}, strjoin(soil_units, ','));

% ── Sim_Temp.csv  (n_col = 54) ───────────────────────────────────────────
write_csv([out_dir 'Sim_Temp.bin'], [out_dir 'Sim_Temp.csv'], NL, NS, ...
  {strjoin(depth_str, ','), strjoin(thickness_str, ',')}, strjoin(oC_units, ','));

% ── Sim_hh.csv  (n_col = 54) ─────────────────────────────────────────────
write_csv([out_dir 'Sim_hh.bin'], [out_dir 'Sim_hh.csv'], NL, NS, ...
  {strjoin(depth_str, ','), strjoin(thickness_str, ',')}, strjoin(cm_units, ','));

% ── aerodyn.csv  (n_col = 9) ─────────────────────────────────────────────
write_csv([out_dir 'aerodyn.bin'], [out_dir 'aerodyn.csv'], 9, NS, ...
  {strjoin({'simulation_number','year','DoY','raa','rawc','raws','ustar','rac','ras'}, ',')}, ...
  strjoin({'','','','s m-1','s m-1','s m-1','m s-1','s m-1','s m-1'}, ','));

% ── surftemp.csv  (n_col = 8) ────────────────────────────────────────────
write_csv([out_dir 'surftemp.bin'], [out_dir 'surftemp.csv'], 8, NS, ...
  {strjoin({'simulation_number','year','DoY','Ta','Ts(1)','Ts(2)','Tcave','Tsave'}, ',')}, ...
  strjoin({'','','','C','C','C','C','C'}, ','));

% ── radiation.csv  (n_col = 11) ──────────────────────────────────────────
write_csv([out_dir 'radiation.bin'], [out_dir 'radiation.csv'], 11, NS, ...
  {strjoin({'simulation_number','year','DoY','Rin','Rli','HemisOutShort','HemisOutLong','HemisOutTot','Netshort','Netlong','Rntot'}, ',')}, ...
  strjoin({'','','','W m-2','W m-2','W m-2','W m-2','W m-2','W m-2','W m-2','W m-2'}, ','));

% ── waterStressFactor.csv  (n_col = 4) ───────────────────────────────────
write_csv([out_dir 'waterStressFactor.bin'], [out_dir 'waterStressFactor.csv'], 4, NS, ...
  {strjoin({'simulation_number','year','DoY','soilWaterStressFactor'}, ',')}, ...
  strjoin({'','','','-'}, ','));

% ── waterPotential.csv  (n_col = 4) ──────────────────────────────────────
write_csv([out_dir 'waterPotential.bin'], [out_dir 'waterPotential.csv'], 4, NS, ...
  {strjoin({'simulation_number','year','DoY','leafWaterPotential'}, ',')}, ...
  strjoin({'','','','m'}, ','));

% ── soil flux files  (n_col = 54 each) ───────────────────────────────────
for fname = {'qla','qlh','qlt','qva','qvh','qvt','qtot'}
  write_csv([out_dir fname{1} '.bin'], [out_dir fname{1} '.csv'], NL, NS, ...
    {strjoin(depth_str, ','), strjoin(thickness_str, ',')}, strjoin(cms_units, ','));
end

fprintf('\nRecovery complete. CSVs written to:\n  %s\n', out_dir);
fprintf('NOTE: .bin files are intentionally preserved.\n');
