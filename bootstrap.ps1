#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Bootstrap Script - Chezmoi + Mise + WinGet
    
.DESCRIPTION
    Provisions Windows machines with development tools using WinGet, Mise, and Chezmoi.
    Supports two profiles: 'work' and 'full' (personal).
    
.PARAMETER Profile
    Bootstrap profile to install: 'work' or 'full'
    - work: development tools only
    - full: development + personal applications
    
.PARAMETER SkipWinget
    Skip WinGet package installation
    
.PARAMETER SkipMise
    Skip Mise setup
    
.PARAMETER SkipChezmoi
    Skip Chezmoi initialization
    
.EXAMPLE
    .\bootstrap.ps1 -Profile work
    
.EXAMPLE
    .\bootstrap.ps1 -Profile full -SkipWinget
#>

param(
    [ValidateSet('work', 'full')]
    [string]$Profile = 'work',
    
    [switch]$SkipWinget,
    [switch]$SkipMise,
    [switch]$SkipChezmoi,
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

Write-Header "Windows Bootstrap - Profile: $Profile"
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

Write-Header "Checking Prerequisites"

# Check Windows version
$osVersion = [System.Environment]::OSVersion.Version
Write-Info "Windows version: $osVersion"

# Check execution policy
$execPolicy = Get-ExecutionPolicy -Scope CurrentUser
Write-Info "Current execution policy: $execPolicy"

if ($execPolicy -eq 'Restricted') {
    Write-Warning "Setting execution policy to RemoteSigned for CurrentUser..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Success "Execution policy updated"
}

# Check WinGet
if (-not (Test-CommandExists winget)) {
    Write-Error "WinGet is not installed or not in PATH"
    Write-Info "Please install App Installer from Microsoft Store first"
    Write-Info "https://www.microsoft.com/store/apps/9NBLGGH4NNS1"
    exit 1
}
Write-Success "WinGet found"

# ============================================================================
# WINGET INSTALLATION
# ============================================================================

if (-not $SkipWinget) {
    Write-Header "Installing WinGet Packages - Profile: $Profile"
    
    $wingetFile = Join-Path $packageDir "winget-$Profile.json"
    
    if (-not (Test-Path $wingetFile)) {
        Write-Error "WinGet configuration not found: $wingetFile"
        exit 1
    }
    
    Write-Info "Using configuration: $wingetFile"
    
    # Import packages from JSON
    Write-Info "Importing packages from WinGet configuration..."
    
    try {
        winget import --import-file $wingetFile --accept-source-agreements --accept-package-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "WinGet packages installed successfully"
        }
        else {
            Write-Warning "WinGet installation completed with warnings (exit code: $LASTEXITCODE)"
        }
    }
    catch {
        Write-Error "Failed to import WinGet packages: $_"
        if (-not $VerbosePreference) {
            Write-Info "Run with -Verbose for more details"
        }
    }
}
else {
    Write-Info "Skipping WinGet installation (--SkipWinget)"
}

# ============================================================================
# MISE SETUP
# ============================================================================

if (-not $SkipMise) {
    Write-Header "Setting up Mise"
    
    # Check if Mise is installed
    if (-not (Test-CommandExists mise)) {
        Write-Warning "Mise not found. Install WinGet packages first or check installation."
    }
    else {
        Write-Success "Mise found"
        
        $miseConfig = Join-Path $packageDir "mise.toml"
        
        if (Test-Path $miseConfig) {
            Write-Info "Using Mise configuration: $miseConfig"
            
            # Copy mise.toml to user config directory
            $miseConfigDir = "$env:USERPROFILE\.config\mise"
            
            if (-not (Test-Path $miseConfigDir)) {
                New-Item -ItemType Directory -Path $miseConfigDir -Force | Out-Null
                Write-Info "Created Mise config directory"
            }
            
            Copy-Item $miseConfig -Destination (Join-Path $miseConfigDir "config.toml") -Force
            Write-Success "Mise configuration installed"
            
            # Install tools defined in mise.toml
            Write-Info "Installing Mise tools (this may take a while)..."
            
            try {
                Push-Location $miseConfigDir
                mise install --yes 2>&1 | ForEach-Object { Write-Info $_ }
                Pop-Location
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Mise tools installed"
                }
                else {
                    Write-Warning "Mise installation completed with status: $LASTEXITCODE"
                }
            }
            catch {
                Write-Warning "Mise tool installation encountered an issue: $_"
            }
        }
        else {
            Write-Warning "Mise configuration not found: $miseConfig"
        }
    }
}
else {
    Write-Info "Skipping Mise setup (--SkipMise)"
}

# ============================================================================
# CHEZMOI SETUP
# ============================================================================

if (-not $SkipChezmoi) {
    Write-Header "Initializing Chezmoi"
    
    # Check if Chezmoi is installed
    if (-not (Test-CommandExists chezmoi)) {
        Write-Warning "Chezmoi not found. Install WinGet packages first."
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
}
else {
    Write-Info "Skipping Chezmoi setup (--SkipChezmoi)"
}

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

Write-Header "Environment Configuration"

# Set profile environment variable
$profileEnv = if ($Profile -eq 'work') { 'work' } else { 'personal' }
[System.Environment]::SetEnvironmentVariable('BOOTSTRAP_PROFILE', $profileEnv, 'User')
Write-Success "Profile variable set: BOOTSTRAP_PROFILE=$profileEnv"

# ============================================================================
# COMPLETION
# ============================================================================

Write-Header "Bootstrap Complete"
Write-Success "All components installed for profile: $Profile"
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
