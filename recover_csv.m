arg_list = argv();
workspace_path = 'rSTEMMUS_SCOPE/src/octave-workspace';
% Current output path (where binary Sim_Theta.bin is)
out_dir = 'rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_6mo_OCTAVE_2026Feb11_1721/';
% Previous successful run path (for headers)
header_dir = 'rSTEMMUS_SCOPE/output/DE-STG_Test_FIXED_InitSMC_OCTAVE_2026Feb05_1509/';

if exist(workspace_path, 'file')
  disp(['Loading workspace from ' workspace_path ' ...']);
  load(workspace_path);
else
  error('Workspace not found!');
end

disp('Workspace loaded.');

% Helper function to copy headers and append data
function write_csv_w_header(filename, data, header_path, num_headers)
  fid = fopen(header_path, 'r');
  fid_out = fopen(filename, 'w');
  for i=1:num_headers
    line = fgetl(fid);
    fprintf(fid_out, '%s\n', line);
  end
  fclose(fid);
  fclose(fid_out);
  dlmwrite(filename, data, '-append', 'delimiter', ',', 'precision', 16);
end

KT_run = size(Sim_Theta_U, 1);
disp(['Recovering ', num2str(KT_run), ' timesteps...']);

% 1. Sim_Theta.csv
disp('Writing Sim_Theta.csv...');
try
  write_csv_w_header([out_dir 'Sim_Theta.csv'], Sim_Theta_U, [header_dir 'Sim_Theta.csv'], 3);
  disp('Success: Sim_Theta.csv');
catch
  disp('Failed to write Sim_Theta.csv');
end

% 2. Sim_Temp.csv
disp('Writing Sim_Temp.csv...');
try
  write_csv_w_header([out_dir 'Sim_Temp.csv'], Sim_Temp, [header_dir 'Sim_Temp.csv'], 3);
  disp('Success: Sim_Temp.csv');
catch
  disp('Failed to write Sim_Temp.csv');
end

% 3. fluxes.csv
disp('Writing fluxes.csv...');
% Reconstruct fluxes matrix
% columns based on header from previous run
% 1:sim_num, 2:iterations, 3:year, 4:DoY, 5:Rntot, 6:lEtot, 7:Htot, ...
flux_data = nan(KT_run, 28);
flux_data(:,1) = (1:KT_run)'; % sim_num
if exist('xyt', 'var')
  flux_data(:,3) = xyt.year(1:KT_run); % year
  flux_data(:,4) = xyt.t(1:KT_run); % DoY
end

% Try to fill data from stored history arrays if available in 'fluxes' struct
if exist('fluxes', 'var')
   % Check typical fields history
   % Note: if STEMMUS_SCOPE does not store history in 'fluxes', these checks will fail
   % but Sim_Theta is the priority.
   if isfield(fluxes, 'Rntot') && length(fluxes.Rntot) >= KT_run; flux_data(:,5) = fluxes.Rntot(1:KT_run); end
   if isfield(fluxes, 'lEtot') && length(fluxes.lEtot) >= KT_run; flux_data(:,6) = fluxes.lEtot(1:KT_run); end
   if isfield(fluxes, 'Htot') && length(fluxes.Htot) >= KT_run; flux_data(:,7) = fluxes.Htot(1:KT_run); end
   if isfield(fluxes, 'Rnctot') && length(fluxes.Rnctot) >= KT_run; flux_data(:,8) = fluxes.Rnctot(1:KT_run); end
   if isfield(fluxes, 'lEctot') && length(fluxes.lEctot) >= KT_run; flux_data(:,9) = fluxes.lEctot(1:KT_run); end
   if isfield(fluxes, 'Hctot') && length(fluxes.Hctot) >= KT_run; flux_data(:,10) = fluxes.Hctot(1:KT_run); end
   if isfield(fluxes, 'Actot') && length(fluxes.Actot) >= KT_run; flux_data(:,11) = fluxes.Actot(1:KT_run); end
   if isfield(fluxes, 'Rnstot') && length(fluxes.Rnstot) >= KT_run; flux_data(:,12) = fluxes.Rnstot(1:KT_run); end
   if isfield(fluxes, 'lEstot') && length(fluxes.lEstot) >= KT_run; flux_data(:,13) = fluxes.lEstot(1:KT_run); end
   if isfield(fluxes, 'Hstot') && length(fluxes.Hstot) >= KT_run; flux_data(:,14) = fluxes.Hstot(1:KT_run); end
   if isfield(fluxes, 'Gtot') && length(fluxes.Gtot) >= KT_run; flux_data(:,15) = fluxes.Gtot(1:KT_run); end
   if isfield(fluxes, 'Resp') && length(fluxes.Resp) >= KT_run; flux_data(:,16) = fluxes.Resp(1:KT_run); end
   if isfield(fluxes, 'ET') && length(fluxes.ET) >= KT_run; flux_data(:,26) = fluxes.ET(1:KT_run); end
end

try
  write_csv_w_header([out_dir 'fluxes.csv'], flux_data, [header_dir 'fluxes.csv'], 2);
  disp('Success: fluxes.csv');
catch
  disp('Failed to write fluxes.csv');
end

disp('Recovery finished.');
exit;
