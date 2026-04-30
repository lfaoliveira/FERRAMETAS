#Requires -Version 5.1

<#
.SYNOPSIS
    Windows Bootstrap Script - WinGet Packages

.DESCRIPTION
    Installs WinGet packages based on profile.
    Supports two profiles: 'work' and 'personal'.

.PARAMETER Perfil
    Bootstrap profile to install: 'work' or 'personal'
    - work: development tools only
    - personal: development + personal applications

.EXAMPLE
    .\winget.ps1 -Profile work

.EXAMPLE
    .\winget.ps1 -Profile personal
#>

param(
    [ValidateSet('work', 'personal')]
    [string]$Perfil = $env:BOOTSTRAP_PROFILE
)

# ============================================================================
# INITIALIZATION
# ============================================================================

if ([string]::IsNullOrWhiteSpace($Perfil)) {
    $Perfil = 'personal'
}

Write-Host ("`n" + ("=" * 80)) -ForegroundColor Magenta
Write-Host "Windows Bootstrap - WinGet Packages - Profile: $Perfil" -ForegroundColor Magenta
Write-Host ("=" * 80) -ForegroundColor Magenta
Write-Host "ℹ Starting WinGet installation process..." -ForegroundColor Cyan

$scriptDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
# O mesmo que "./../packages"
$packageDir = Join-Path $scriptDir "packages"

# Verify script location and package files exist
if (-not (Test-Path $packageDir)) {
    Write-Host "✗ Package directory not found at: $packageDir" -ForegroundColor Red
    exit 1
}

# ============================================================================
# INSTALACAO WINGET
# ============================================================================

function Install-WingetFile {
    param(
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "✗ Winget package file not found: $FilePath" -ForegroundColor Red
        exit 1
    }

    Write-Host "ℹ Installing packages from $FilePath" -ForegroundColor Cyan

    try {
        winget import --import-file $FilePath --accept-source-agreements --accept-package-agreements
        Write-Host "✓ Installed: $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ WinGet installation failed: $_" -ForegroundColor Red
        exit 1
    }
}

if ($Perfil -eq 'work') {
    $wingetFile = Join-Path $packageDir "winget-work.json"
    Install-WingetFile -FilePath $wingetFile
}
else {
    $wingetFile = Join-Path $packageDir "winget-work.json"
    Install-WingetFile -FilePath $wingetFile

    $wingetFile = Join-Path $packageDir "winget-personal.json"
    Install-WingetFile -FilePath $wingetFile
}

Write-Host ("`n" + ("=" * 80)) -ForegroundColor Magenta
Write-Host "WinGet Installation Complete" -ForegroundColor Magenta
Write-Host ("=" * 80) -ForegroundColor Magenta
Write-Host "✓ All WinGet packages installed for profile $Perfil" -ForegroundColor Green
Write-Host "Next steps" -ForegroundColor Cyan
Write-Host "1. Review and customize Chezmoi dotfiles $((Join-Path $scriptDir 'chezmoi'))" -ForegroundColor Cyan
Write-Host "2. Run 'chezmoi apply' to apply your dotfile configurations" -ForegroundColor Cyan
Write-Host "3. Check Mise tools mise versions" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan