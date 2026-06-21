% compile_stemmus_scope.m
% =========================================================================
% One-time compilation script for STEMMUS-SCOPE standalone deployment.
%
% PURPOSE:
%   Compiles STEMMUS_SCOPE_exe.m into a standalone executable that can
%   run on machines with only MATLAB Runtime (MCR) installed — no MATLAB
%   license required.
%
% PREREQUISITES:
%   - MATLAB (any supported version, e.g. R2021a+)
%   - MATLAB Compiler toolbox (check: ver('compiler'))
%   - Current directory must be rSTEMMUS_SCOPE/src/
%
% USAGE:
%   >> cd('path/to/rSTEMMUS_SCOPE/src')
%   >> compile_stemmus_scope
%
% OUTPUT:
%   STEMMUS_SCOPE_exe/ directory containing:
%     - stemmus_scope.exe     (Windows) or stemmus_scope (Linux/Mac)
%     - run_stemmus_scope.sh  (Linux/Mac launcher)
%     - requiredMCRProducts.txt
%     - readme.txt
%
% DISTRIBUTION:
%   1. Install MATLAB Runtime (free) on the target machine:
%      https://www.mathworks.com/products/compiler/matlab-runtime.html
%      (use the version matching the MATLAB used for compilation)
%   2. Copy the STEMMUS_SCOPE_exe/ folder to the target machine.
%   3. Run via R wrapper: run_inMATLAB(..., exe_method = "mcr")
%
% AUTHORS:
%   Arman Shirzad, EcoExtreML Contributors
%   Date: 2026-05-05
% =========================================================================

%% Pre-flight checks
fprintf('\n=== STEMMUS-SCOPE Standalone Compiler ===\n\n');

% Check MATLAB Compiler is installed
if isempty(ver('compiler'))
    error(['MATLAB Compiler toolbox is not installed.\n', ...
           'Install it via Add-Ons > Get Add-Ons > "MATLAB Compiler".\n', ...
           'Or check: https://www.mathworks.com/products/compiler.html']);
end
fprintf('  MATLAB Compiler: Found (v%s)\n', ver('compiler').Version);

% Check we're in the right directory
if ~isfile('STEMMUS_SCOPE_exe.m')
    error(['STEMMUS_SCOPE_exe.m not found in current directory.\n', ...
           'Please cd to rSTEMMUS_SCOPE/src/ before running this script.']);
end
fprintf('  Working directory: %s\n', pwd);
fprintf('  Entry point: STEMMUS_SCOPE_exe.m\n');

%% Identify all package directories to include
% STEMMUS-SCOPE uses MATLAB package folders (+folder) for namespacing.
% These must be explicitly included in the compiled archive.
pkg_dirs = {'+io', '+init', '+conductivity', '+soilmoisture', ...
            '+energy', '+equations', '+helpers', '+parameters', ...
            '+groundwater', '+dryair', '+plot'};

% Verify all package dirs exist
missing = {};
for i = 1:length(pkg_dirs)
    if ~isfolder(pkg_dirs{i})
        missing{end+1} = pkg_dirs{i}; %#ok<SAGROW>
    end
end
if ~isempty(missing)
    warning('Missing package directories: %s\nCompilation may fail.', strjoin(missing, ', '));
end

fprintf('  Package directories: %d found\n', length(pkg_dirs) - length(missing));

%% Build the mcc command arguments
output_dir = 'STEMMUS_SCOPE_exe';
fprintf('\n  Output directory: %s/\n', output_dir);
fprintf('\nStarting compilation (this may take 2-5 minutes)...\n\n');

% Build argument list
args = {'-m', 'STEMMUS_SCOPE_exe.m', ...
        '-d', output_dir, ...
        '-v', ...  % verbose output
        '-a', 'STEMMUS_SCOPE.m'};  % Explicit: mcc can't follow 'run STEMMUS_SCOPE' dynamic calls

% Add each package directory
for i = 1:length(pkg_dirs)
    if isfolder(pkg_dirs{i})
        args{end+1} = '-a'; %#ok<SAGROW>
        args{end+1} = pkg_dirs{i}; %#ok<SAGROW>
    end
end

% NOTE: Standalone .m files in src/ are automatically discovered by mcc's
% dependency analysis since they are in the same directory as the entry
% point. Only +package directories need explicit -a inclusion.

%% Run mcc
try
    mcc(args{:});
catch ME
    fprintf('\n❌ Compilation FAILED:\n%s\n', ME.message);
    fprintf('\nCommon fixes:\n');
    fprintf('  1. Ensure MATLAB Compiler toolbox is installed\n');
    fprintf('  2. Ensure all dependencies are on the MATLAB path\n');
    fprintf('  3. Try: mcc -m STEMMUS_SCOPE_exe.m -v  (minimal compile)\n');
    rethrow(ME);
end

%% Post-compilation summary
fprintf('\n=== Compilation Successful ===\n\n');
fprintf('Output: %s/\n', fullfile(pwd, output_dir));
fprintf('\nTo distribute:\n');
fprintf('  1. Copy the "%s/" folder to the target machine\n', output_dir);
fprintf('  2. Install MATLAB Runtime (free) on the target machine:\n');
fprintf('     https://www.mathworks.com/products/compiler/matlab-runtime.html\n');
fprintf('  3. Run via R: run_inMATLAB(patch, site, run, exe_method = "mcr")\n');
fprintf('\nTo test locally:\n');
if ispc
    fprintf('  %s\\STEMMUS_SCOPE_exe.exe path/to/config.txt\n', output_dir);
else
    fprintf('  ./%s/run_STEMMUS_SCOPE_exe.sh $MCR_ROOT path/to/config.txt\n', output_dir);
end
fprintf('\n');
