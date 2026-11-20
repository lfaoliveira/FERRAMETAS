# Unico script PowerShell do setup: garante winget + mise + Python e entrega para o setup.py.
#
# Funciona de dois jeitos (sempre em PowerShell como Administrador):
#   irm https://raw.githubusercontent.com/lfaoliveira/FERRAMETAS/main/init.ps1 | iex
#   .\init.ps1 -Perfil work            # com o repo ja baixado
#
# Sem `exit` de proposito: rodando via iex, `exit` fecharia o PowerShell do usuario.
param([ValidateSet('work', 'personal')][string]$Perfil)

$Repo = 'lfaoliveira/FERRAMETAS'
$Destino = Join-Path $HOME 'FERRAMENTAS'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { throw 'Abra o PowerShell como Administrador e rode de novo.' }

function Sync-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

# 1. Repo: usa a pasta do script; via irm (sem arquivo local) baixa o zip - nao precisa de git
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'setup.py'))) {
    $Raiz = $PSScriptRoot
}
else {
    $Raiz = $Destino
    if (-not (Test-Path (Join-Path $Raiz 'setup.py'))) {
        Write-Host "Baixando $Repo para $Raiz ..." -ForegroundColor Cyan
        $zip = Join-Path $env:TEMP 'ferramentas.zip'
        $tmp = Join-Path $env:TEMP 'ferramentas-src'
        $ProgressPreference = 'SilentlyContinue'   # deixa o download ~10x mais rapido no PS 5.1
        Invoke-WebRequest "https://github.com/$Repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        Expand-Archive $zip $tmp -Force
        Move-Item (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName $Raiz
        Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Set-Location $Raiz

# 2. winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
    Sync-Path
}

# 3. mise
if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    winget install --id jdx.mise --exact --source winget --silent `
        --accept-package-agreements --accept-source-agreements --disable-interactivity
    Sync-Path
}

# 4. Python (so ele agora; o resto do mise.toml o setup.py instala em paralelo com o winget)
mise trust
mise install python
$python = mise which python
if (-not $python) { throw 'mise nao conseguiu instalar o Python.' }

# 5. Daqui pra frente e tudo Python
$argv = if ($Perfil) { @('--perfil', $Perfil) } else { @() }
& $python setup.py @argv
if ($LASTEXITCODE -ne 0) { Write-Warning "setup.py terminou com codigo $LASTEXITCODE" }
