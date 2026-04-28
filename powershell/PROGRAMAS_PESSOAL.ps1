# Check if winget is installed
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget is not installed. Please install App Installer from the Microsoft Store first."
    exit 1
}

# Set execution policy to allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Host "Starting installation of required programs..." -ForegroundColor Green

# Array of programs to install
$programs = @(
    "Brave.Brave",
    "Microsoft.VisualStudioCode",
    "Valve.Steam",
    "Spotify.Spotify",
    "Git.Git",
    "Docker.DockerDesktop",
    "Discord.Discord",
    "RARLab.WinRAR",
    "Obsidian.Obsidian",
    "OpenJS.NodeJS",
    "Anaconda.Miniconda3",
    "astral-sh.uv", #UV
    "JetBrains.IntelliJIDEA.Community",
    "beekeeper-studio.beekeeper-studio",
    "jdx.mise"
    
)
# Lista de programas opcionais
$optionalPrograms = @(
    "EpicGames.EpicGamesLauncher"
    "VideoLAN.VLC"
    
)

Write-Host "`nProgramas opcionais disponíveis:" -ForegroundColor Cyan
Write-Host "------------------------------" -ForegroundColor Cyan
$optionalPrograms | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
Write-Host "------------------------------" -ForegroundColor Cyan

$installOptional = Read-Host "`nDeseja instalar a lista de programas opcionais? (S/N)"
if ($installOptional -eq "S" -or $installOptional -eq "s") {
    $programs += $optionalPrograms
    Write-Host "Programas opcionais adicionados à instalação." -ForegroundColor Green
}
else {
    Write-Host "Programas opcionais serão ignorados." -ForegroundColor Yellow
}
    
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