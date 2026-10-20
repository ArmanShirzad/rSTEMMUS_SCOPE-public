#' to run the model in MATLAB (as time series simulation)
#'
#' @description
#' `run_inMATLAB` dispatches the STEMMUS-SCOPE simulation to one of three
#' execution engines: MATLAB (commercial), GNU Octave (free), or MATLAB
#' Runtime/MCR (free, requires pre-compiled binary).
#' @seealso [new_run())],  @seealso [input_constants())],  @seealso [input_timeseries()] be previously ran
#' with the same site_name and run_name
#'
#' @param patch the patch to the STEMMUS_SCOPE model directory, default ```"D:/model/rSTEMMUS_SCOPE/"```,
#' @param site_name,run_name the name of the location and the name of run. The last can be used to name runs with different model parameters or settings,
#' @param cores set 1,2,4,6,8 cores for ech run **experimental**
#' @return run the model in MATLAB that will return the resuls in the folder ```~/output/site_name_run_name_time/```
#'
#' @examples
#' \dontrun{
#'
#'run_inMATLAB(patch = "D:/model/rSTEMMUS_SCOPE/",
#'               site_name = "DE-HoH",
#'               run_name = "ECdata_01")
#'
#' n = 10
#' for (i in 1:10) {
#'
#' run_inMATLAB(patch = "D:/model/rSTEMMUS_SCOPE/",
#'            site_name = site_names[i],
#'            run_name = "DWD_36")
#'            svMisc::progress(i, n, progress.bar = TRUE, init = T) # time delay
#'            Sys.sleep(1800) # time delay in seconds 7200/60
#'            if (i == n) message("Done!")
#' }
#'
#' }
#'
#' @export

run_inMATLAB <- function(patch = "D:/model/rSTEMMUS_SCOPE/",
                site_name = NA,
                run_name = NA,
                id_userID = NA,
                cores = NULL,
                exe_method = "matlab" # Options: "matlab", "octave", "mcr"
){

  # --- Engine Version Validation ---
  if (tolower(exe_method) == "octave") {
    octave_ver <- tryCatch({
      suppressWarnings(system2("octave-cli", args = "--version", stdout = TRUE, stderr = TRUE))[1]
    }, error = function(e) NULL)
    if (!is.null(octave_ver)) {
      ver_num <- regmatches(octave_ver, regexpr("[0-9]+\\.[0-9]+", octave_ver))
      if (length(ver_num) > 0 && as.numeric(ver_num) < 8.0) {
        warning(sprintf(
          "GNU Octave %s detected. Version >= 8.0 is required for reliable execution.\n",
          ver_num), "  Known issues with Octave < 8: function scoping bugs, pkg compatibility.\n",
          "  Please upgrade: https://octave.org/download", immediate. = TRUE)
      }
    }
  }
  # change the config file ----
  # Read config.txt line-by-line. IMPORTANT: use readLines(), NOT read.table().
  # config.txt holds "key=value" lines, several of which are absolute install
  # paths. If that path contains spaces (e.g. "C:/Users/Name/New folder/..."),
  # read.table's default whitespace separator splits those lines into multiple
  # columns and then fails on the first space-free line (StartTime) with
  # "line 9 did not have N elements". readLines/writeLines are space-safe.
  cfg_file_path <- paste0(patch, "runs/", site_name, "_", run_name, "/", site_name,"_", run_name, "_", "config.txt")
  config_lines <- readLines(cfg_file_path)

  # Ensure OutputPath exists in config — updating line 12 (OutputPath)
  config_path_out <- paste0(patch,"output/", site_name, "_", run_name, "_", format(Sys.time(), "%Y%b%d_%H%M"), "/")
  config_lines[[12]] <- paste0("OutputPath=", config_path_out)

  # Create the output directory now, from R, BEFORE the engine runs. The Octave
  # build does not reliably create OutputPath itself, so the model produced no
  # output and the run_metadata.json write below then failed with
  # "cannot open the connection". Creating it here guarantees both the engine
  # and the metadata write have a destination (no-op if the engine also makes it).
  dir.create(config_path_out, recursive = TRUE, showWarnings = FALSE)

  writeLines(config_lines, cfg_file_path)
  
  # create path for the model to find the new input directory ----
  CFG = paste0(patch, "runs/", site_name, "_", run_name, "/", site_name,"_", run_name, "_", "config.txt")
  
  start_time <- Sys.time()
  
  if (tolower(exe_method) == "octave") {
    # Octave Execution Block
    src_dir <- paste0(patch, "src/")
    
    # Check if src directory exists
    if (!dir.exists(src_dir)) {
      message(paste("Error: Source directory not found at:", src_dir))
      return()
    }
    
    # Auto-detect octave-cli executable
    octave_exe <- NULL
    if (.Platform$OS.type == "windows") {
      # Check common Windows install locations
      win_octave_dirs <- list.files("C:/Program Files/GNU Octave", full.names = TRUE)
      for (d in rev(win_octave_dirs)) {
        candidate <- file.path(d, "mingw64", "bin", "octave-cli.exe")
        if (file.exists(candidate)) { octave_exe <- candidate; break }
      }
      if (is.null(octave_exe)) {
        # Fall back to PATH
        octave_check <- suppressWarnings(system("where octave-cli", intern = TRUE))
        if (length(octave_check) > 0 && nchar(octave_check[1]) > 0) {
          octave_exe <- octave_check[1]
        }
      }
    } else {
      # Unix: check PATH
      octave_check <- suppressWarnings(system("which octave-cli 2>/dev/null || which octave 2>/dev/null", intern = TRUE))
      if (length(octave_check) > 0 && nchar(octave_check[1]) > 0) {
        octave_exe <- octave_check[1]
      } else {
        octave_exe <- "octave"
      }
    }
    
    if (is.null(octave_exe) || !file.exists(octave_exe)) {
      stop("GNU Octave not found. Please install Octave or add it to your PATH.")
    }
    message(paste("Using Octave at:", octave_exe))
    
    # Redirect engine stdout/stderr to log files inside the per-run runs/ dir.
    # Inheriting the parent's stdout (stdout="") deadlocks Octave on Windows
    # when R was launched with no console attached (background / nohup style).
    run_dir <- paste0(patch, "runs/", site_name, "_", run_name, "/")
    stdout_log <- paste0(run_dir, "engine_stdout.log")
    stderr_log <- paste0(run_dir, "engine_stderr.log")

    # Construct platform-appropriate command
    if (.Platform$OS.type == "windows") {
      # Windows: use setwd + system2 to avoid nested quoting nightmares
      old_wd <- getwd()
      setwd(normalizePath(src_dir))
      octave_eval <- sprintf("CFG='%s'; STEMMUS_SCOPE; exit",
                             normalizePath(CFG, winslash="/"))
      message(paste("Running Octave from:", getwd()))
      message(paste("Eval:", octave_eval))
      message(paste("Octave stdout -> ", stdout_log))
      system2(normalizePath(octave_exe),
              args = c("--no-gui", "--silent", "--eval", shQuote(octave_eval)),
              stdout = stdout_log, stderr = stderr_log)
      setwd(old_wd)
    } else {
      # Unix: use cd && trap HUP && octave, redirect to log files
      octave_eval <- sprintf("CFG='%s'; STEMMUS_SCOPE; exit", CFG)
      cmd <- sprintf("cd '%s' && trap '' HUP && '%s' --no-gui --silent --eval \"%s\" > '%s' 2> '%s'",
                     src_dir, octave_exe, octave_eval, stdout_log, stderr_log)
      message(paste("Running Octave with command:", cmd))
      system(cmd)
    }
    
  } else if (tolower(exe_method) == "mcr") {
    # =========================================================================
    # MATLAB Runtime (MCR) Execution Block
    # =========================================================================
    # Runs a pre-compiled STEMMUS_SCOPE standalone binary.
    # Requires: MATLAB Runtime (free) + compiled binary from compile_stemmus_scope.m
    # Does NOT require a MATLAB license.
    
    mcr_exe <- NULL
    
    # Search for compiled binary in standard locations
    if (.Platform$OS.type == "windows") {
      candidates <- c(
        paste0(patch, "src/STEMMUS_SCOPE_exe/STEMMUS_SCOPE_exe.exe"),
        paste0(patch, "bin/STEMMUS_SCOPE_exe.exe"),
        Sys.getenv("STEMMUS_SCOPE_EXE", unset = "")
      )
      # Also check system PATH
      path_check <- suppressWarnings(system("where STEMMUS_SCOPE_exe 2>NUL", intern = TRUE))
      if (length(path_check) > 0 && nchar(path_check[1]) > 0) {
        candidates <- c(candidates, path_check[1])
      }
    } else {
      candidates <- c(
        paste0(patch, "src/STEMMUS_SCOPE_exe/run_STEMMUS_SCOPE_exe.sh"),
        paste0(patch, "bin/run_STEMMUS_SCOPE_exe.sh"),
        Sys.getenv("STEMMUS_SCOPE_EXE", unset = "")
      )
      # Also check system PATH
      path_check <- suppressWarnings(system("which STEMMUS_SCOPE_exe 2>/dev/null || which run_STEMMUS_SCOPE_exe.sh 2>/dev/null", intern = TRUE))
      if (length(path_check) > 0 && nchar(path_check[1]) > 0) {
        candidates <- c(candidates, path_check[1])
      }
    }
    
    # Find the first valid candidate
    for (cand in candidates) {
      if (nchar(cand) > 0 && file.exists(cand)) {
        mcr_exe <- cand
        break
      }
    }
    
    if (is.null(mcr_exe)) {
      stop("Compiled STEMMUS_SCOPE binary not found.\n",
           "Searched locations:\n",
           paste("  -", candidates[nchar(candidates) > 0], collapse = "\n"), "\n\n",
           "To use MATLAB Runtime mode, you need the compiled binary.\n",
           "Options:\n",
           "  1. Compile it yourself (requires MATLAB + MATLAB Compiler, one-time):\n",
           "     >> cd('", paste0(patch, "src/"), "')\n",
           "     >> compile_stemmus_scope\n",
           "  2. Download pre-compiled binary from project releases.\n",
           "  3. Use exe_method='octave' instead (free, no compilation needed).\n",
           "  4. Set STEMMUS_SCOPE_EXE environment variable to the binary path.")
    }
    
    message(paste("Using compiled STEMMUS_SCOPE at:", mcr_exe))
    
    # Build the execution command
    if (.Platform$OS.type == "windows") {
      # On Windows, the compiled .exe takes the config file as its argument
      full_cmd <- sprintf('"%s" "%s"', normalizePath(mcr_exe), normalizePath(CFG))
    } else {
      # On Unix, the shell launcher script takes MCR_ROOT as first arg, then config
      # Auto-detect MCR root or use environment variable
      mcr_root <- Sys.getenv("MCR_ROOT", unset = "")
      if (nchar(mcr_root) == 0) {
        # Try common MCR install locations
        mcr_dirs <- c(
          list.files("/usr/local/MATLAB/MATLAB_Runtime", full.names = TRUE),
          list.files("/opt/MATLAB/MATLAB_Runtime", full.names = TRUE),
          list.files("/Applications", pattern = "^MATLAB_Runtime", full.names = TRUE)
        )
        if (length(mcr_dirs) > 0) {
          mcr_root <- mcr_dirs[length(mcr_dirs)]  # Use latest version
        } else {
          stop("MATLAB Runtime not found.\n",
               "Install it (free) from: https://www.mathworks.com/products/compiler/matlab-runtime.html\n",
               "Then either:\n",
               "  1. Set MCR_ROOT environment variable to the install path, or\n",
               "  2. Install to /usr/local/MATLAB/MATLAB_Runtime/")
        }
      }
      message(paste("Using MATLAB Runtime at:", mcr_root))
      full_cmd <- sprintf('"%s" "%s" "%s"', mcr_exe, mcr_root, CFG)
    }
    
    message(paste("Running MATLAB Runtime with command:", full_cmd))
    system(full_cmd)
    
  } else {
    # =========================================================================
    # MATLAB Execution Block
    # =========================================================================
    # Step 1: Auto-detect MATLAB path (machine-agnostic)
    matlab_path <- NULL
    
    # Check common locations based on OS
    if (.Platform$OS.type == "unix") {
      # macOS: Check /Applications for MATLAB
      mac_apps <- list.files("/Applications", pattern = "^MATLAB_R", full.names = TRUE)
      if (length(mac_apps) > 0) {
        # Use the latest version found
        matlab_path <- paste0(mac_apps[length(mac_apps)], "/bin/matlab")
      }
      # Linux: Check /usr/local/MATLAB
      if (is.null(matlab_path) && dir.exists("/usr/local/MATLAB")) {
        linux_dirs <- list.files("/usr/local/MATLAB", pattern = "^R", full.names = TRUE)
        if (length(linux_dirs) > 0) {
          matlab_path <- paste0(linux_dirs[length(linux_dirs)], "/bin/matlab")
        }
      }
      # Fall back to system PATH
      if (is.null(matlab_path)) {
        matlab_check <- suppressWarnings(system("which matlab", intern = TRUE))
        if (length(matlab_check) > 0 && nchar(matlab_check[1]) > 0) {
          matlab_path <- matlab_check[1]
        }
      }
    } else {
      # Windows: Check Program Files
      win_paths <- c(
        list.files("C:/Program Files/MATLAB", pattern = "^R", full.names = TRUE),
        list.files("C:/Program Files (x86)/MATLAB", pattern = "^R", full.names = TRUE)
      )
      if (length(win_paths) > 0) {
        matlab_path <- paste0(win_paths[length(win_paths)], "/bin/matlab.exe")
      }
      # Fall back to system PATH
      if (is.null(matlab_path)) {
        matlab_check <- suppressWarnings(system("where matlab", intern = TRUE))
        if (length(matlab_check) > 0 && nchar(matlab_check[1]) > 0) {
          matlab_path <- matlab_check[1]
        }
      }
    }
    
    # Check if MATLAB was found
    if (is.null(matlab_path) || !file.exists(matlab_path)) {
      stop("MATLAB not found. Please ensure MATLAB is installed and either:\n",
           " 1. Add MATLAB to your system PATH, or\n",
           " 2. Set MATLAB_PATH environment variable to the matlab executable path.\n\n",
           "Alternatives (no license required):\n",
           " 3. Use exe_method='octave' (free, runs .m files directly)\n",
           " 4. Use exe_method='mcr'   (free, requires pre-compiled binary)")
    }
    
    message(paste("Using MATLAB at:", matlab_path))
    
    # Step 2: Navigate to src/ directory (like Octave does)
    src_dir <- paste0(patch, "src/")
    if (!dir.exists(src_dir)) {
      stop(paste("Error: Source directory not found at:", src_dir))
    }
    
    # Step 3: Build and execute command
    # MATLAB needs to cd to src/ first, then run STEMMUS_SCOPE
    # Use -batch (R2021a+): headless, no desktop, exits automatically on completion or error
    if(missing(cores) || is.null(cores)){
      matlab_cmd <- sprintf("cd('%s'); CFG='%s'; STEMMUS_SCOPE;", src_dir, CFG)
    } else {
      matlab_cmd <- sprintf("cd('%s'); parpool(%d); CFG='%s'; STEMMUS_SCOPE;", src_dir, cores, CFG)
    }

    # -batch: implies -nodesktop -nosplash -nodisplay, exits on completion/error
    full_cmd <- sprintf('"%s" -batch "%s"', matlab_path, matlab_cmd)
    message(paste("Running MATLAB with command:", full_cmd))
    system(full_cmd)
  }
  
  # Save metadata log
  metadata <- list(
    site = site_name,
    run = run_name,
    engine = exe_method,
    r_version = R.version.string,
    timestamp = Sys.time(),
    wall_time_seconds = as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  )
  jsonlite::write_json(metadata, paste0(config_path_out, "run_metadata.json"), pretty = TRUE)

  return(print("Simulation initiated. Check terminal for details."))
}
