#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Bootstrap Initializer - Prepares clean machines for bootstrap
    
.DESCRIPTION
    Initializer script for clean Windows machines. Verifies prerequisites and runs the bootstrap script.
    
    This script should be run from the FERRAMENTAS directory on a clean machine.
    
.PARAMETER Perfil
    Bootstrap profile to install: 'work' or 'personal'
    Default: 'work'
    
.EXAMPLE
    .\init.ps1 -Profile work
    
.EXAMPLE
    .\init.ps1 -Profile full
#>

param(
    [ValidateSet('work', 'personal')]
    [string]$Perfil,
    [switch]$Verbose
)

$colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'Cyan'
    Header  = 'Magenta'
    Input   = 'White'
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

Write-Header "Windows Bootstrap Initializer"

# Ask user for profile if not provided
if ([string]::IsNullOrWhiteSpace($Perfil)) {
    Write-Info "Select installation profile:"
    Write-Info ""
    Write-Host "  1. work    - Development tools only (recommended for work machines)" -ForegroundColor $colors.Info
    Write-Host "  2. personal    - Development + Personal apps (games, media, etc)" -ForegroundColor $colors.Info
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1 or 2)"
    
    if ($choice -eq '1') {
        $Perfil = 'work'
    }
    elseif ($choice -eq '2') {
        $Perfil = 'personal'
    }
    else {
        Write-Error "Invalid choice. Please run the script again."
        exit 1
    }
}

Write-Info "Profile: $Perfil"
Write-Info "Starting initialization process..."

# Get script directory
$scriptDir = (Get-Location).Path
Write-Info "Script directory: $scriptDir"

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

Write-Header "Checking Prerequisites"

# Check Windows version
$osVersion = [System.Environment]::OSVersion.Version
Write-Info "Windows version: $osVersion"

# Check execution policy
$execPolicy = Get-ExecutionPolicy -Scope CurrentUser
Write-Info "Current execution policy: $execPolicy"

if ($execPolicy -eq 'Restricted') {
    Write-Warning "Setting execution policy to RemoteSigned..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Success "Execution policy updated"
}

# Check WinGet
if (-not (Test-CommandExists winget)) {
    Write-Error "WinGet is not installed or not in PATH"
    Write-Info "Please install App Installer:"
    #Instalando usando comando recomendado pela microsoft
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}
Write-Success "WinGet is installed"

# Check Mise
if (-not (Test-CommandExists mise)) {
    Write-Warning "Mise is not installed yet. It will be installed via WinGet during bootstrap."
}
else {
    Write-Success "Mise is installed"
}

# ============================================================================
# VERIFY BOOTSTRAP SCRIPT
# ============================================================================

Write-Header "Verifying Bootstrap Script"

$bootstrapPath = Join-Path -Path $scriptDir -ChildPath "bootstrap.ps1"

if (-not (Test-Path $bootstrapPath)) {
    Write-Error "bootstrap.ps1 not found in current directory"
    Write-Error "Expected at: $bootstrapPath"
    exit 1
}

Write-Success "bootstrap.ps1 found"

# ============================================================================
# RUN BOOTSTRAP
# ============================================================================

Write-Header "Running Bootstrap Tasks"

Write-Info "Starting Mise bootstrap tasks with profile: $Perfil"
Write-Info ""

# Verify Mise is available
if (-not (Test-CommandExists mise)) {
    Write-Error "Mise is required to run bootstrap tasks"
    Write-Error "Please install Mise via WinGet first: "
    winget install jdx.mise
    if (-not ($LASTEXITCODE -eq 0) ) {
        Write-Error "Erro ao instalar Mise"
        exit 1;
    }
}

Write-Success "Mise is available"
Write-Info ""

try {
    # Set profile environment variable
    $PerfilEnv = if ($Perfil -eq 'work') { 'work' } else { 'personal' }
    [System.Environment]::SetEnvironmentVariable('BOOTSTRAP_PROFILE', $PerfilEnv, 'User')
    $env:BOOTSTRAP_PROFILE = $PerfilEnv
    
    Write-Success "Profile variable set: BOOTSTRAP_PROFILE=$PerfilEnv"
    Write-Info ""
    
    # Run Mise bootstrap task from project root
    Push-Location $scriptDir
    mise install
    mise run bootstrap
    
    Pop-Location
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Bootstrap completed successfully"
    }
    else {
        Write-Warning "Bootstrap exited with code: $LASTEXITCODE"
    }
}
catch {
    Write-Error "Bootstrap execution error: $_"
    exit 1
}

# ============================================================================
# COMPLETION
# ============================================================================

Write-Header "Initialization Complete"
Write-Success "Setup completed successfully!"
Write-Info ""
Write-Info "Next steps:"
Write-Info "1. Restart your terminal for environment changes to take effect"
Write-Info "2. Review bootstrap.ps1 and customize as needed"
Write-Info "3. Check Mise tools: mise versions"
Write-Info "4. Apply Chezmoi configurations: chezmoi apply"
Write-Info ""
Write-Info "For issues, check:"
Write-Info "  - Mise: https://mise.jdx.dev"
Write-Info "  - Chezmoi: https://www.chezmoi.io"
Write-Info "  - Git: https://git-scm.com/doc"
Write-Info ""
