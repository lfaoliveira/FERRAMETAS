#Requires -Version 5.1

<#
.SYNOPSIS
    Windows Bootstrap Script - Chezmoi + Mise + WinGet
    
.DESCRIPTION
    Provisions Windows machines with development tools using WinGet, Mise, and Chezmoi.
    Supports two profiles: 'work' and 'personal' (personal).
    
.PARAMETER Perfil
    Bootstrap profile to install: 'work' or 'personal'
    - work: development tools only
    - personal: development + personal applications
    
.EXAMPLE
    .\bootstrap.ps1 -Profile work
    
.EXAMPLE
    .\bootstrap.ps1 -Profile personal
#>

param(
    [ValidateSet('work', 'personal')]
    [string]$Perfil = $env:BOOTSTRAP_PROFILE,
    [switch]$Verbose
)

# Color scheme for output
$colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'Cyan'
    Header  = 'Magenta'
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host "`n" + ("=" * 80) -ForegroundColor $colors.Header
    Write-Host $Message -ForegroundColor $colors.Header
    Write-Host ("=" * 80) -ForegroundColor $colors.Header
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $colors.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $colors.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $colors.Error
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $colors.Info
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# ============================================================================
# INITIALIZATION
# ============================================================================

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell `
        -Verb RunAs `
        -Wait `
        -ArgumentList @(
        '-NoProfile',
        '-NoExit',
        '-ExecutionPolicy', 'Bypass',        
        '-File', $PSCommandPath,
        '-Perfil', $Perfil
    )
    
    exit $LASTEXITCODE
}

if ([string]::IsNullOrWhiteSpace($Perfil)) {
    throw 'PERFIL VAZIO!'
}


Write-Header "Windows Bootstrap - Profile: $Perfil"
Write-Info "Starting bootstrap process..."
Write-Info "Script directory: $(Split-Path -Parent $PSCommandPath)"

# Verify script location and package files exist
$scriptDir = Split-Path -Parent $PSCommandPath
$packageDir = Join-Path $scriptDir "packages"

if (-not (Test-Path $packageDir)) {
    Write-Error "Package directory not found at: $packageDir"
    exit 1
}

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================
$error = 0
$errorMsg = ""
Write-Header "Running Boostrapping"

# ============================================================================
# INSTALACAO WINGET
# ============================================================================

$wingetFile = Join-Path $packageDir "winget-$Perfil.json"

if (-not (Test-Path $wingetFile)) {
    throw "Winget package file not found: $wingetFile"
}
try {
    winget import `
        --import-file $wingetFile `
        --accept-source-agreements `
        --accept-package-agreements
}
catch {
    $error = 1
    $errorMsg = "Erro ao instalar pacotes do winget"
    Write-Error $errorMsg
}


# ============================================================================
# CHEZMOI SETUP
# ============================================================================

Write-Header "Initializing Chezmoi"
    
# Check if Chezmoi is installed
if (-not (Test-CommandExists chezmoi)) {
    Write-Info "Chezmoi not found. Installing..."
        
    try {
        winget install --id twpayne.chezmoi --accept-source-agreements --accept-package-agreements
        Write-Success "Chezmoi installed"
    }
    catch {
        Write-Error "Chezmoi installation failed: $_"
        $error = 1
        $errorMsg = "Erro ao instalar chezmoi"
        Write-Error $errorMsg
    }
}
else {
    Write-Success "Chezmoi found"
        
    $chezmoiDir = Join-Path $scriptDir "chezmoi"
        
    if (Test-Path $chezmoiDir) {
        Write-Info "Chezmoi dotfiles directory: $chezmoiDir"
        Write-Info "To apply configurations, run: chezmoi apply"
    }
    else {
        Write-Warning "Chezmoi directory not found. Create it with your dotfiles at: $chezmoiDir"
    }
        
    # Initialize chezmoi with git if not already done
    if (-not (Test-Path "$env:USERPROFILE\.local\share\chezmoi\.git")) {
        Write-Info "Initializing Chezmoi repository..."
        try {
            chezmoi init --apply=false 2>&1 | ForEach-Object { Write-Info $_ }
            Write-Success "Chezmoi initialized"
        }
        catch {
            Write-Warning "Chezmoi initialization: $_"
        }
    }
    else {
        Write-Success "Chezmoi already initialized"
    }
}



# ============================================================================
# COMPLETION
# ============================================================================

Write-Header "Bootstrap Complete"
Write-Success "All components installed for profile: $Perfil"
Write-Info ""
Write-Info "Next steps:"
Write-Info "1. Restart your terminal for environment changes to take effect"
Write-Info "2. Review and customize Chezmoi dotfiles: $((Join-Path $scriptDir 'chezmoi'))"
Write-Info "3. Run 'chezmoi apply' to apply your dotfile configurations"
Write-Info "4. Check Mise tools: mise versions"
Write-Info ""
Write-Info "For more information:"
Write-Info "  - Mise: https://mise.jdx.dev"
Write-Info "  - Chezmoi: https://www.chezmoi.io"
Write-Info ""
