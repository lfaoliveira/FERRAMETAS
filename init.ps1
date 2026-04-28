#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Bootstrap Initializer - Prepares clean machines for bootstrap
    
.DESCRIPTION
    First-run script for clean Windows machines. Installs Git, authenticates with GitHub/GitLab,
    clones the FERRAMENTAS repository, and runs the bootstrap script.
    
    This script should be downloaded and run first on a clean machine.
    
.PARAMETER Profile
    Bootstrap profile to install: 'work' or 'full'
    Default: 'work'
    
.PARAMETER GitPlatform
    Git hosting platform: 'github' or 'gitlab'
    Default: 'github'
    
.EXAMPLE
    .\init.ps1 -Profile work
    
.EXAMPLE
    .\init.ps1 -Profile full -GitPlatform gitlab
#>

param(
    [ValidateSet('work', 'full')]
    [string]$Profile = 'work',
    
    [ValidateSet('github', 'gitlab')]
    [string]$GitPlatform = 'github',
    
    [switch]$Verbose
)

# Color scheme
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

function Get-SecureInput {
    param(
        [string]$Prompt,
        [switch]$AsSecureString = $false
    )
    
    if ($AsSecureString) {
        return Read-Host -Prompt $Prompt -AsSecureString
    }
    else {
        return Read-Host -Prompt $Prompt
    }
}

function Convert-SecureStringToPlainText {
    param([System.Security.SecureString]$SecureString)
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($SecureString)
    $result = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr)
    return $result
}

# ============================================================================
# INITIALIZATION
# ============================================================================

Write-Header "Windows Bootstrap Initializer"
Write-Info "Profile: $Profile"
Write-Info "Git Platform: $GitPlatform"
Write-Info "Starting initialization process..."

# Get home directory
$homeDir = $env:USERPROFILE
Write-Info "Home directory: $homeDir"

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
    Write-Error "WinGet is not installed. Please install App Installer from Microsoft Store first."
    Write-Info "Download: https://www.microsoft.com/store/apps/9NBLGGH4NNS1"
    exit 1
}
Write-Success "WinGet is installed"

# ============================================================================
# GIT INSTALLATION
# ============================================================================

Write-Header "Installing Git"

if (Test-CommandExists git) {
    Write-Success "Git is already installed"
    git --version
}
else {
    Write-Info "Installing Git via WinGet..."
    
    try {
        winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Git installed successfully"
            
            # Refresh PATH
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            
            # Verify installation
            if (Test-CommandExists git) {
                git --version
                Write-Success "Git verified"
            }
            else {
                Write-Warning "Git not in PATH yet. Restart terminal after script completion."
            }
        }
        else {
            Write-Error "Failed to install Git (exit code: $LASTEXITCODE)"
            exit 1
        }
    }
    catch {
        Write-Error "Git installation error: $_"
        exit 1
    }
}

# ============================================================================
# GIT AUTHENTICATION
# ============================================================================

Write-Header "Git Authentication Setup"

Write-Info "Configuring Git credentials..."

# Get Git user info
$gitName = Read-Host "Enter your name for Git config"
$gitEmail = Read-Host "Enter your email for Git config"

try {
    git config --global user.name $gitName
    git config --global user.email $gitEmail
    Write-Success "Git user configured: $gitName <$gitEmail>"
}
catch {
    Write-Error "Failed to configure Git user: $_"
    exit 1
}

# ============================================================================
# PERSONAL ACCESS TOKEN (PAT)
# ============================================================================

Write-Header "$GitPlatform PAT Setup"

Write-Info "For secure authentication, provide a Personal Access Token (PAT)"
Write-Info ""

if ($GitPlatform -eq 'github') {
    Write-Info "Create a token at: https://github.com/settings/tokens"
    Write-Info "Required scopes: repo, workflow"
    $tokenUrl = "https://github.com/settings/tokens"
}
else {
    Write-Info "Create a token at: https://gitlab.com/-/user_settings/personal_access_tokens"
    Write-Info "Required scopes: api, read_repository, write_repository"
    $tokenUrl = "https://gitlab.com/-/user_settings/personal_access_tokens"
}

Write-Info ""
$openToken = Read-Host "Open token creation page in browser? (Y/n)"

if ($openToken -ne 'n' -and $openToken -ne 'N') {
    Write-Info "Opening browser..."
    Start-Process $tokenUrl
    Write-Info "Creating token... (Waiting for your input)"
}

# Get PAT
$pat = Get-SecureInput "Paste your Personal Access Token" -AsSecureString
$patPlain = Convert-SecureStringToPlainText $pat

if ([string]::IsNullOrWhiteSpace($patPlain)) {
    Write-Error "No PAT provided. Cannot continue without authentication."
    exit 1
}

# Configure Git credential helper
Write-Info "Configuring Git credential manager..."

try {
    if ($GitPlatform -eq 'github') {
        git config --global credential.https://github.com.username "lfaoliveira"
    }
    else {
        git config --global credential.https://gitlab.com.username "lfaoliveira"
    }
    
    Write-Success "Git credential helper configured"
}
catch {
    Write-Warning "Could not configure credential helper: $_"
}

# ============================================================================
# REPOSITORY CLONE
# ============================================================================

Write-Header "Cloning FERRAMENTAS Repository"

$ferramentasDir = Join-Path $homeDir "FERRAMENTAS"

if (Test-Path $ferramentasDir) {
    Write-Warning "FERRAMENTAS directory already exists at: $ferramentasDir"
    $overwrite = Read-Host "Overwrite existing directory? (y/N)"
    
    if ($overwrite -eq 'y' -or $overwrite -eq 'Y') {
        Write-Info "Removing existing directory..."
        Remove-Item $ferramentasDir -Recurse -Force
        Write-Success "Directory removed"
    }
    else {
        Write-Info "Using existing directory"
    }
}

if (-not (Test-Path $ferramentasDir)) {
    Write-Info "Cloning repository..."
    Write-Info "Repository: lfaoliveira/FERRAMENTAS"
    Write-Info "Destination: $ferramentasDir"
    
    try {
        $repoUrl = if ($GitPlatform -eq 'github') {
            "https://github.com/lfaoliveira/FERRAMENTAS.git"
        }
        else {
            "https://gitlab.com/lfaoliveira/FERRAMENTAS.git"
        }
        
        # Clone with PAT in URL (temporary)
        $urlWithAuth = $repoUrl -replace "https://", "https://lfaoliveira:$patPlain@"
        
        Push-Location $homeDir
        
        git clone $urlWithAuth FERRAMENTAS
        
        Pop-Location
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Repository cloned successfully"
        }
        else {
            Write-Error "Failed to clone repository (exit code: $LASTEXITCODE)"
            exit 1
        }
    }
    catch {
        Write-Error "Clone error: $_"
        exit 1
    }
}
else {
    Write-Success "Using existing FERRAMENTAS directory"
}

# ============================================================================
# VERIFY BOOTSTRAP SCRIPT
# ============================================================================

Write-Header "Verifying Bootstrap Script"

$bootstrapPath = Join-Path $ferramentasDir "bootstrap.ps1"

if (-not (Test-Path $bootstrapPath)) {
    Write-Error "bootstrap.ps1 not found in cloned repository"
    Write-Error "Expected at: $bootstrapPath"
    exit 1
}

Write-Success "bootstrap.ps1 found"

# ============================================================================
# RUN BOOTSTRAP
# ============================================================================

Write-Header "Running Bootstrap"

Write-Info "Changing to FERRAMENTAS directory..."
Push-Location $ferramentasDir

Write-Info "Starting bootstrap with profile: $Profile"
Write-Info ""

try {
    # Run bootstrap with same parameters
    & .\bootstrap.ps1 -Profile $Profile -Verbose:$Verbose
    
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
finally {
    Pop-Location
}

# ============================================================================
# CLEANUP
# ============================================================================

Write-Info "Clearing sensitive data from memory..."
[System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocAnsi($patPlain)
Remove-Variable patPlain, pat -Force -ErrorAction SilentlyContinue

# ============================================================================
# COMPLETION
# ============================================================================

Write-Header "Initialization Complete"
Write-Success "Setup completed successfully!"
Write-Info ""
Write-Info "Next steps:"
Write-Info "1. Restart your terminal for environment changes to take effect"
Write-Info "2. Review FERRAMENTAS/bootstrap.ps1 and customize as needed"
Write-Info "3. Check Mise tools: mise versions"
Write-Info "4. Apply Chezmoi configurations: chezmoi apply"
Write-Info ""
Write-Info "FERRAMENTAS directory: $ferramentasDir"
Write-Info ""
Write-Info "For issues, check:"
Write-Info "  - Mise: https://mise.jdx.dev"
Write-Info "  - Chezmoi: https://www.chezmoi.io"
Write-Info "  - Git: https://git-scm.com/doc"
Write-Info ""
