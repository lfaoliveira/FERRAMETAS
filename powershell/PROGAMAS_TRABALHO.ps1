# Check if winget is installed
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget is not installed. Please install App Installer from the Microsoft Store first."
    exit 1
}

Write-Host "Starting installation of required programs..." -ForegroundColor Green

# Array of programs to install
$programs = @(
    "Brave.Brave",
    "Microsoft.VisualStudioCode",
    "Git.Git",
    "Obsidian.Obsidian",
    "Docker.DockerDesktop",
    "RARLab.WinRAR",
    "OpenJS.NodeJS",
    "Postman.Postman",
    "beekeeper-studio.beekeeper-studio",
    "Anaconda.Miniconda3",
    "jdx.mise",
    "twpayne.chezmoi"
)



# Install each program
foreach ($program in $programs) {
    Write-Host "Installing $program..." -ForegroundColor Yellow
    winget install -e --id $program --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$program installed successfully." -ForegroundColor Green
    }
    else {
        Write-Host "Failed to install $program." -ForegroundColor Red
    }
}

Write-Host "Installation process completed!" -ForegroundColor Green