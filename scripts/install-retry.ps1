#Requires -Version 5.1

param(
    [string]$Manifest
)

function Install-WingetWithRetry {
    param(
        [string]$Package
    )

    $ProgressPreference = 'SilentlyContinue'
    $maxRetries = 5
    $delay = 5

    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        winget install `
            --id $Package `
            -e `
            --accept-package-agreements `
            --accept-source-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] $Package"
            return 0
        }

        Write-Host "[FAIL] $Package attempt $attempt"

        if ($attempt -lt $maxRetries) {
            Start-Sleep -Seconds $delay
            $delay *= 2
        }
    }

    return 1
}

$json = Get-Content $Manifest -Raw | ConvertFrom-Json

$packages = @(
    $json.Sources |
    ForEach-Object { $_.Packages } |
    ForEach-Object { $_.PackageIdentifier }
)

if ($packages.Count -eq 0) {
    Write-Host "No packages found in manifest."
    exit 0
}

$installJobInitScript = {
    function Install-WingetWithRetry {
        param(
            [string]$Package
        )
        Write-Host "PACOTE" $Package

        $ProgressPreference = 'SilentlyContinue'
        $maxRetries = 5
        $delay = 5

        for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
            winget install `
                --id $Package `
                -e `
                --accept-package-agreements `
                --accept-source-agreements

            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] $Package"
                return 0
            }

            Write-Host "[FAIL] $Package attempt $attempt"

            if ($attempt -lt $maxRetries) {
                Start-Sleep -Seconds $delay
                $delay *= 2
            }
        }

        return 1
    }
}

$installJobScript = {
    param(
        [string]$Package
    )

    Install-WingetWithRetry -Package $Package
}

$maxParallelJobs = 8

for ($offset = 0; $offset -lt $packages.Count; $offset += $maxParallelJobs) {
    $batchEnd = [Math]::Min($offset + $maxParallelJobs - 1, $packages.Count - 1)
    $batch = $packages[$offset..$batchEnd]

    $jobs = foreach ($pkg in $batch) {
        Start-Job `
            -Name $pkg `
            -InitializationScript $installJobInitScript `
            -ScriptBlock $installJobScript `
            -ArgumentList $pkg
    }

    Wait-Job $jobs | Out-Null
    $jobs | Receive-Job

    $failedJobs = $jobs | Where-Object { $_.State -ne 'Completed' }

    if ($failedJobs.Count -gt 0) {
        Write-Error "$($failedJobs.Count) packages failed"
        $jobs | Remove-Job -Force
        exit 1
    }

    $jobs | Remove-Job -Force
}