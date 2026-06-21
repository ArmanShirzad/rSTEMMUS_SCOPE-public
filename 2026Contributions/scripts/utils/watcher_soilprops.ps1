while ($true) {
    Clear-Host
    Write-Host "Monitoring 2-Year Octave Run with Soil Properties..."
    Write-Host "--------------------------------------------------------"

    # Find the newest directory for the current simulation
    $out_path = "C:\Users\armanshirzad\Repos\rSTEMMUS_SCOPE\rSTEMMUS_SCOPE\output"
    $latest_dir = Get-ChildItem -Path $out_path -Directory -Filter "*2yr_final_soilprops_OCTAVE*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($latest_dir) {
        Write-Host "Output Directory: $($latest_dir.Name)"

        $csv_file = Join-Path $latest_dir.FullName "Sim_Theta.csv"
        $bin_file = Join-Path $latest_dir.FullName "aerodyn.bin"

        $ts = 0

        if (Test-Path $csv_file) {
            # Fast way to count lines in PowerShell without loading the whole file
            $reader = [System.IO.File]::OpenText($csv_file)
            $lines = 0
            while ($reader.ReadLine() -ne $null) { $lines++ }
            $reader.Close()
            
            # Usually 3 header lines
            $ts = [math]::Max(0, $lines - 3)
            Write-Host "Tracking via Sim_Theta.csv"
        } elseif (Test-Path $bin_file) {
            $bytes = (Get-Item $bin_file).Length
            $ts = [math]::Floor($bytes / 72)
            Write-Host "Tracking via aerodyn.bin"
        } else {
            Write-Host "Waiting for output files to be created..."
        }

        $total = 17544
        $pct = [math]::Round(($ts / $total) * 100, 2)
        Write-Host ""
        Write-Host "Progress: $ts / $total timesteps ($pct %)"
        
        # Simple progress bar
        $bars = [math]::Floor($pct / 2)
        $spaces = 50 - $bars
        $bar = "[" + ("#" * $bars) + ("-" * $spaces) + "]"
        Write-Host $bar

        $fluxes_done = Join-Path $latest_dir.FullName "fluxes.csv"
        if (Test-Path $fluxes_done -and $ts -ge $total) {
            Write-Host "✅ Simulation Complete!" -ForegroundColor Green
            break
        }
    } else {
        Write-Host "Waiting for initialization... directory not found yet."
    }

    Start-Sleep -Seconds 30
}
