#Requires -Version 5.1

<#
.SYNOPSIS
    Windows Bootstrap Script - Chezmoi Setup

.DESCRIPTION
    Sets up Chezmoi for Windows machines.
    Installs Chezmoi if not present and initializes the repository.

.EXAMPLE
    .\chezmoi.ps1
#>

param(
    [switch]$Verbose
)

# ============================================================================
# INITIALIZATION
# ============================================================================

Write-Host "`n" + ("=" * 80) -ForegroundColor Magenta
Write-Host "Windows Bootstrap - Chezmoi Setup" -ForegroundColor Magenta
Write-Host ("=" * 80) -ForegroundColor Magenta
Write-Host "Starting Chezmoi setup process..." -ForegroundColor Cyan

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# ============================================================================
# INITIALIZATION
# ============================================================================

Write-Header "Windows Bootstrap - Chezmoi Setup"
Write-Info "Starting Chezmoi setup process..."

# Verify script location
$scriptDir = Split-Path -Parent $PSCommandPath

# ============================================================================
# CHEZMOI SETUP
# ============================================================================

Write-Header "Initializing Chezmoi"
    
# Check if Chezmoi is installed
if (-not (Test-CommandExists chezmoi)) {
    Write-Host "Chezmoi not found. Installing..." -ForegroundColor Cyan
        
    try {
        winget install --id twpayne.chezmoi --accept-source-agreements --accept-package-agreements
        Write-Host "✓ Chezmoi installed" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Chezmoi installation failed: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "✓ Chezmoi found" -ForegroundColor Green
        
    $chezmoiDir = Join-Path $scriptDir "chezmoi"
        
    if (Test-Path $chezmoiDir) {
        Write-Host "Chezmoi dotfiles directory: $chezmoiDir" -ForegroundColor Cyan
        Write-Host "To apply configurations, run: chezmoi apply" -ForegroundColor Cyan
    }
    else {
        Write-Host "⚠ Chezmoi directory not found. Create it with your dotfiles at: $chezmoiDir" -ForegroundColor Yellow
    }
        
    # Initialize chezmoi with git if not already done
    if (-not (Test-Path "$env:USERPROFILE\.local\share\chezmoi\.git")) {
        Write-Host "Initializing Chezmoi repository..." -ForegroundColor Cyan
        try {
            chezmoi init --apply=false 2>&1 | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }
            Write-Host "✓ Chezmoi initialized" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠ Chezmoi initialization: $_" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "✓ Chezmoi already initialized" -ForegroundColor Green
    }
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Magenta
Write-Host "Chezmoi Setup Complete" -ForegroundColor Magenta
Write-Host ("=" * 80) -ForegroundColor Magenta
Write-Host "✓ Chezmoi setup completed successfully!" -ForegroundColor Green
Write-Host "" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart your terminal for environment changes to take effect" -ForegroundColor Cyan
Write-Host "2. Review and customize Chezmoi dotfiles: $((Join-Path $scriptDir 'chezmoi'))" -ForegroundColor Cyan
Write-Host "3. Run 'chezmoi apply' to apply your dotfile configurations" -ForegroundColor Cyan
Write-Host "4. Check Mise tools: mise versions" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan