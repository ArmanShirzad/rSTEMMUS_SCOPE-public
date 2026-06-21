## ═══════════════════════════════════════════════════════════════════════════
## run_all_sequential.ps1
## ═══════════════════════════════════════════════════════════════════════════
## Sequential pipeline: Octave → MATLAB → Validation Plots
## With progress bar, failover support, and timestamped output
## Date: 2026-04-20
## ═══════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Continue"
$REPO = "C:\Users\armanshirzad\Repos\rSTEMMUS_SCOPE"
$RSCRIPT = "C:\Program Files\R\R-4.5.3\bin\Rscript.exe"
$OCTAVE_BIN = "C:\Program Files\GNU Octave\Octave-11.1.0"
$OUTPUT_BASE = "$REPO\rSTEMMUS_SCOPE\output"
$TOTAL_TS = 17544
$LOG_DIR = "$REPO\2026Contributions"

# ── Fix 1: Add Octave's unzip to PATH so xlsread works ──────────────────
$env:PATH = "$OCTAVE_BIN\usr\bin;$OCTAVE_BIN\mingw64\bin;$env:PATH"
Write-Host "✓ Added Octave usr/bin to PATH (unzip.exe now available)" -ForegroundColor Green
& unzip -v 2>$null | Select-Object -First 1

# ── Helper: Progress Monitor ────────────────────────────────────────────
function Watch-Simulation {
    param(
        [string]$Engine,
        [string]$DirPattern,
        [System.Diagnostics.Process]$Process
    )
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  MONITORING: $Engine simulation" -ForegroundColor Cyan
    Write-Host "  Looking for: $DirPattern" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $lastTs = 0
    $stallCount = 0
    $startTime = Get-Date
    
    while (-not $Process.HasExited) {
        $dir = Get-ChildItem -Path $OUTPUT_BASE -Directory -Filter $DirPattern -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        $ts = 0
        $method = "waiting..."
        
        if ($dir) {
            # Try Sim_Theta.csv first (most reliable)
            $csvFile = Join-Path $dir.FullName "Sim_Theta.csv"
            $binFile = Join-Path $dir.FullName "aerodyn.bin"
            
            if (Test-Path $csvFile) {
                try {
                    $reader = [System.IO.File]::OpenText($csvFile)
                    $lines = 0
                    while ($reader.ReadLine() -ne $null) { $lines++ }
                    $reader.Close()
                    $ts = [math]::Max(0, $lines - 3)
                    $method = "Sim_Theta.csv"
                } catch { $method = "csv locked" }
            } elseif (Test-Path $binFile) {
                try {
                    $bytes = (Get-Item $binFile).Length
                    $ts = [math]::Floor($bytes / 72)
                    $method = "aerodyn.bin"
                } catch { $method = "bin locked" }
            }
        }
        
        $pct = if ($TOTAL_TS -gt 0) { [math]::Round(($ts / $TOTAL_TS) * 100, 1) } else { 0 }
        $elapsed = (Get-Date) - $startTime
        $elapsedStr = "{0:hh\:mm\:ss}" -f $elapsed
        
        # ETA calculation
        $etaStr = "calculating..."
        if ($ts -gt 100 -and $pct -gt 0) {
            $totalSeconds = $elapsed.TotalSeconds / ($pct / 100)
            $remainSeconds = $totalSeconds - $elapsed.TotalSeconds
            $eta = [TimeSpan]::FromSeconds([math]::Max(0, $remainSeconds))
            $etaStr = "{0:hh\:mm\:ss}" -f $eta
        }
        
        # Progress bar
        $bars = [math]::Floor($pct / 2)
        $spaces = 50 - $bars
        $bar = "[" + ("█" * $bars) + ("░" * $spaces) + "]"
        
        # Stall detection
        if ($ts -eq $lastTs -and $ts -gt 0) {
            $stallCount++
        } else {
            $stallCount = 0
        }
        $lastTs = $ts
        
        $stallWarning = ""
        if ($stallCount -ge 10) {
            $stallWarning = " ⚠ STALLED for $([math]::Round($stallCount * 30 / 60, 1)) min"
        }
        
        Write-Host "`r$Engine | $bar $pct% | $ts/$TOTAL_TS | Elapsed: $elapsedStr | ETA: $etaStr | via $method$stallWarning    " -NoNewline
        
        Start-Sleep -Seconds 30
    }
    
    # Final status
    $exitCode = $Process.ExitCode
    $elapsed = (Get-Date) - $startTime
    $elapsedStr = "{0:hh\:mm\:ss}" -f $elapsed
    
    Write-Host ""
    if ($exitCode -eq 0) {
        Write-Host "✅ $Engine COMPLETED in $elapsedStr (exit code 0)" -ForegroundColor Green
    } else {
        Write-Host "❌ $Engine FAILED (exit code $exitCode) after $elapsedStr" -ForegroundColor Red
    }
    
    return $exitCode
}

# ══════════════════════════════════════════════════════════════════════════
# PHASE 1: OCTAVE
# ══════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  PHASE 1/3: OCTAVE 2-Year Simulation with Soil Properties  ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

$octaveLog = "$LOG_DIR\2yr_soilprops_octave.log"
$octaveProcess = Start-Process -FilePath $RSCRIPT `
    -ArgumentList "-e `"exe_method <- 'octave'; source('2026Contributions/run_2yr_final_with_soilprops.R')`"" `
    -WorkingDirectory $REPO `
    -RedirectStandardOutput $octaveLog `
    -RedirectStandardError "$LOG_DIR\2yr_soilprops_octave_err.log" `
    -PassThru -NoNewWindow

$octaveExit = Watch-Simulation -Engine "OCTAVE" -DirPattern "*2yr_final_soilprops_OCTAVE*" -Process $octaveProcess

if ($octaveExit -ne 0) {
    Write-Host "❌ OCTAVE failed. Check log: $octaveLog" -ForegroundColor Red
    Write-Host "Last 20 lines of log:" -ForegroundColor Red
    Get-Content $octaveLog -Tail 20
    Write-Host ""
    Write-Host "Continuing to MATLAB anyway (failover)..." -ForegroundColor Yellow
}

# ══════════════════════════════════════════════════════════════════════════
# PHASE 2: MATLAB
# ══════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  PHASE 2/3: MATLAB 2-Year Simulation with Soil Properties  ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

$matlabLog = "$LOG_DIR\2yr_soilprops_matlab.log"
$matlabProcess = Start-Process -FilePath $RSCRIPT `
    -ArgumentList "-e `"exe_method <- 'matlab'; source('2026Contributions/run_2yr_final_with_soilprops.R')`"" `
    -WorkingDirectory $REPO `
    -RedirectStandardOutput $matlabLog `
    -RedirectStandardError "$LOG_DIR\2yr_soilprops_matlab_err.log" `
    -PassThru -NoNewWindow

$matlabExit = Watch-Simulation -Engine "MATLAB" -DirPattern "*2yr_final_soilprops_MATLAB*" -Process $matlabProcess

if ($matlabExit -ne 0) {
    Write-Host "❌ MATLAB failed. Check log: $matlabLog" -ForegroundColor Red
    Write-Host "Last 20 lines of log:" -ForegroundColor Red
    Get-Content $matlabLog -Tail 20
}

# ══════════════════════════════════════════════════════════════════════════
# PHASE 3: VALIDATION PLOTS
# ══════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  PHASE 3/3: Generating 3-Way Validation Plots              ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

# Find the actual output directories
$octaveDir = Get-ChildItem -Path $OUTPUT_BASE -Directory -Filter "*2yr_final_soilprops_OCTAVE*" |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
$matlabDir = Get-ChildItem -Path $OUTPUT_BASE -Directory -Filter "*2yr_final_soilprops_MATLAB*" |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1

$plotTimestamp = Get-Date -Format "yyyyMMdd_HHmm"
$plotDir = "$LOG_DIR\validation_plots\${plotTimestamp}_DE-STG_2yr_soilprops_3way"

if ($octaveDir -and $matlabDir) {
    Write-Host "Octave output: $($octaveDir.Name)" -ForegroundColor Cyan
    Write-Host "MATLAB output: $($matlabDir.Name)" -ForegroundColor Cyan
    Write-Host "Plot output:   $plotDir" -ForegroundColor Cyan
    
    # Check if plot_validation.R exists
    $plotScript = "$LOG_DIR\plot_validation.R"
    if (Test-Path $plotScript) {
        & $RSCRIPT -e "
            octave_dir <- '$($octaveDir.FullName -replace '\\','/')';
            matlab_dir <- '$($matlabDir.FullName -replace '\\','/')';
            plot_dir   <- '$($plotDir -replace '\\','/')';
            source('2026Contributions/plot_validation.R')
        "
        Write-Host "✅ Validation plots generated at: $plotDir" -ForegroundColor Green
    } else {
        Write-Host "⚠ plot_validation.R not found at $plotScript" -ForegroundColor Yellow
        Write-Host "  Octave dir: $($octaveDir.FullName)"
        Write-Host "  MATLAB dir: $($matlabDir.FullName)"
        Write-Host "  Run plot_validation.R manually with these paths."
    }
} else {
    Write-Host "⚠ Could not find output directories for validation." -ForegroundColor Yellow
    if (-not $octaveDir) { Write-Host "  Missing: Octave output" -ForegroundColor Red }
    if (-not $matlabDir) { Write-Host "  Missing: MATLAB output" -ForegroundColor Red }
}

# ══════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ══════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  PIPELINE COMPLETE                                         ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host "  Octave exit code: $octaveExit" -ForegroundColor $(if ($octaveExit -eq 0) {"Green"} else {"Red"})
Write-Host "  MATLAB exit code: $matlabExit" -ForegroundColor $(if ($matlabExit -eq 0) {"Green"} else {"Red"})
if ($octaveDir) { Write-Host "  Octave output:    $($octaveDir.Name)" -ForegroundColor Cyan }
if ($matlabDir) { Write-Host "  MATLAB output:    $($matlabDir.Name)" -ForegroundColor Cyan }
Write-Host "  Logs:             $LOG_DIR\2yr_soilprops_*.log" -ForegroundColor Cyan
Write-Host ""
