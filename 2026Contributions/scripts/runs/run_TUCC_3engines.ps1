# ═══════════════════════════════════════════════════════════════════════════════
# run_TUCC_3engines.ps1 — Run TUCC 2-year simulation on all 3 engines sequentially
# ═══════════════════════════════════════════════════════════════════════════════
# ORDER: Octave → MATLAB → MCR  (as requested)
# Each engine runs the full 17,544-timestep (2yr) simulation.
# Output dirs are saved to 2026Contributions/logs/ for the validation script.
# ═══════════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Continue"
$R = "C:\Program Files\R\R-4.5.3\bin\Rscript.exe"
$root = "c:\Users\armanshirzad\Repos\rSTEMMUS_SCOPE"

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TUCC 2-Year Simulation — 3 Engines Sequential"        -ForegroundColor Cyan
Write-Host "  Order: Octave → MATLAB → MCR"                         -ForegroundColor Cyan
Write-Host "  Start: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"     -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan

# ── Engine 1: Octave ──────────────────────────────────────────────────────────
Write-Host "`n[1/3] Starting OCTAVE..." -ForegroundColor Green
$t0 = Get-Date
& $R "2026Contributions/scripts/runs/run_TUCC_2yr_OCTAVE.R" 2>&1 | Tee-Object -FilePath "2026Contributions/logs/TUCC_2yr_OCTAVE.log"
$elapsed = (Get-Date) - $t0
Write-Host "[1/3] OCTAVE finished in $($elapsed.TotalMinutes.ToString('F1')) min" -ForegroundColor Green

# ── Engine 2: MATLAB ──────────────────────────────────────────────────────────
Write-Host "`n[2/3] Starting MATLAB..." -ForegroundColor Yellow
$t0 = Get-Date
& $R "2026Contributions/scripts/runs/run_TUCC_2yr_MATLAB.R" 2>&1 | Tee-Object -FilePath "2026Contributions/logs/TUCC_2yr_MATLAB.log"
$elapsed = (Get-Date) - $t0
Write-Host "[2/3] MATLAB finished in $($elapsed.TotalMinutes.ToString('F1')) min" -ForegroundColor Yellow

# ── Engine 3: MCR ─────────────────────────────────────────────────────────────
Write-Host "`n[3/3] Starting MCR..." -ForegroundColor Magenta
$t0 = Get-Date
& $R "2026Contributions/scripts/runs/run_TUCC_2yr_MCR.R" 2>&1 | Tee-Object -FilePath "2026Contributions/logs/TUCC_2yr_MCR.log"
$elapsed = (Get-Date) - $t0
Write-Host "[3/3] MCR finished in $($elapsed.TotalMinutes.ToString('F1')) min" -ForegroundColor Magenta

Write-Host "`n════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  All 3 engines complete!"                                -ForegroundColor Cyan
Write-Host "  End: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"        -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
