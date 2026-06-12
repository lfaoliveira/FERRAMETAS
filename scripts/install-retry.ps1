#Requires -Version 5.1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8


# --- Config ---
$MAX_PARALLEL = 8
$MAX_RETRIES = 5

$perfil = if ($env:BOOTSTRAP_PROFILE) { $env:BOOTSTRAP_PROFILE } else { 'personal' }
Write-Host "Perfil: $perfil"

#deve buscar em ./../packages pelos arquivos JSON
$packageDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSCommandPath)) "packages"
Write-Host "Package Dir: $packageDir"
# --- Load packages ---
$manifestFiles = @("winget-work.json")
if ($perfil -ne 'work') { 
    $manifestFiles += "winget-personal.json" 
}

$packages = $manifestFiles |
ForEach-Object { Get-Content (Join-Path $packageDir $_) -Raw | ConvertFrom-Json } |
ForEach-Object { $_.Sources.Packages.PackageIdentifier }

if (!$packages) { Write-Host "No packages found."; }

# --- Install job (runs in parallel) ---
$jobScript = {
    param([string]$pkg)
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8

    $ProgressPreference = 'SilentlyContinue'
    $delay = 2

    foreach ($attempt in 1..$using:MAX_RETRIES) {
        winget install --id $pkg -e --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] $pkg"
            return
        }

        Write-Host "[FAIL] $pkg (attempt $attempt of $using:MAX_RETRIES)"

        if ($attempt -lt $using:MAX_RETRIES) {
            Start-Sleep $delay
            $delay *= 2
        }
    }
}

# --- Run in batches ---
$totalFailed = 0

for ($i = 0; $i -lt $packages.Count; $i += $MAX_PARALLEL) {
    $batch = $packages[$i .. ([Math]::Min($i + $MAX_PARALLEL - 1, $packages.Count - 1))]
    $jobs = $batch | ForEach-Object { Start-Job -ScriptBlock $jobScript -ArgumentList $_ }
    Wait-Job $jobs | Out-Null
    $jobs | Receive-Job

    $totalFailed += ($jobs | Where-Object State -NE Completed).Count
    $jobs | Remove-Job -Force
}

# --- Result ---
if ($totalFailed -gt 0) {
    Write-Error "$totalFailed package(s) failed to install"
    
}
Read-Host "DIGITE"