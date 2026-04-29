# Installation Guide

Quick start guide for setting up a new Windows machine with FERRAMENTAS.

## ⚡ TL;DR - One Line Setup

```powershell
# Open PowerShell as Administrator and run:
irm https://raw.githubusercontent.com/lfaoliveira/FERRAMENTAS/main/init.ps1 | iex -ArgumentList @('-Profile','work')
```

Or manually:

```powershell
cd $env:USERPROFILE
curl -o init.ps1 https://raw.githubusercontent.com/lfaoliveira/FERRAMENTAS/main/init.ps1
.\init.ps1 -Profile work
```

---

## 📋 Prerequisites

- **Windows 10/11** (any edition)
- **App Installer** (WinGet) - Usually pre-installed
  - If missing: [Download from Microsoft Store](https://www.microsoft.com/store/apps/9NBLGGH4NNS1)
- **Git** - For cloning the repository
- **Administrator access** (required for installations)
- **Internet connection** (for downloads)

---

## 🚀 Step-by-Step Installation

### 1. Open PowerShell as Administrator

```
Windows Key → Type "PowerShell" → Right-click → "Run as administrator"
```

### 2. Run the Initializer

**For a work/development machine:**
```powershell
.\init.ps1 -Profile work
```

**For a personal/full machine:**
```powershell
.\init.ps1 -Profile full
```

### 3. Wait for Installation

The script will:
- ✅ Verify prerequisites (WinGet, Mise)
- ✅ Execute Mise bootstrap tasks
- ✅ Install WinGet packages (profile-specific)
- ✅ Install development tools (Python, Go, Node.js, etc)
- ✅ Initialize Chezmoi dotfile manager

This can take **30-60 minutes** depending on your internet speed.

### 4. Restart Terminal

After completion, close and reopen PowerShell for environment changes to take effect.

---

## 🎯 Choose Your Profile

### `work` Profile

**Best for:** Work laptops, restricted environments, development-focused

**Includes:**
- Brave Browser
- VS Code
- Git & GitHub CLI
- Docker Desktop
- Node.js & Python
- Postman (API testing)
- Beekeeper Studio (database)
- Mise (tool manager)
- Chezmoi (dotfiles)

**Install time:** ~20 minutes

### `full` Profile

**Best for:** Personal laptops, desktops, development + entertainment

**Includes:** Everything from `work` +
- Steam (gaming)
- Spotify (music)
- Discord (communication)
- JetBrains IntelliJ IDEA Community
- UV (Python package manager)
- Epic Games Launcher
- VLC Media Player

**Install time:** ~45 minutes

---

## ✅ Verify Installation

After restarting your terminal, verify everything works:

```powershell
# Check Git
git --version

# Check Mise
mise --version
mise versions

# Check Chezmoi
chezmoi --version
```

---

## 🔄 Apply Dotfile Configurations

After bootstrap completes, apply your dotfile configurations:

```powershell
# See what would change
chezmoi diff

# Apply all configurations
chezmoi apply

# Or edit and apply specific files
chezmoi edit ~/.gitconfig
```

---

## 🛠️ Switching Profiles

If you initially chose `work` but want the `full` profile:

```powershell
# Set the new profile
$env:BOOTSTRAP_PROFILE = 'personal'
[System.Environment]::SetEnvironmentVariable('BOOTSTRAP_PROFILE', 'personal', 'User')

# Run only the packages task to install additional apps
mise run bootstrap:packages
```

This will install only the additional applications needed for the full profile.

---

## 🐛 Troubleshooting

### Script won't execute

**Error:** "PowerShell cannot execute script because execution policy is..."

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
.\init.ps1 -Profile work
```

### WinGet installation fails

**Error:** "Failed to install [package]"

**Solutions:**
```powershell
# Update WinGet
winget upgrade Microsoft.AppInstaller

# Clear WinGet cache
winget cache

# Try installation again
mise run bootstrap:packages
```

### Mise tasks fail

**Error:** "mise: command not found" or task execution errors

**Solutions:**
1. Ensure Mise is installed: `winget install jdx.mise`
2. Restart PowerShell after installing Mise
3. Verify you're in the FERRAMENTAS directory: `Get-Location`
4. Check task syntax: `mise run help`

### Mise tools not found after restart

**Solution:** Restart PowerShell again. Sometimes the PATH takes a moment to update.

### Chezmoi not initializing

**Error:** "chezmoi: command not found"

**Solutions:**
1. Chezmoi is installed via WinGet (`mise run bootstrap:packages`)
2. Restart PowerShell after installation
3. Manually initialize: `chezmoi init --apply=false`

### Permission denied errors

**Solution:** Ensure you're running PowerShell as Administrator:
```
Windows Key → Type "PowerShell" → Right-click → "Run as administrator"
```

---

## 📞 Support

For issues or questions:
- Check: https://github.com/lfaoliveira/FERRAMENTAS/issues
- WinGet Help: https://github.com/microsoft/winget-cli
- Mise Docs: https://mise.jdx.dev
- Chezmoi Guide: https://www.chezmoi.io/quick-start/
- Git Help: https://git-scm.com/book/en/v2

---

## 🎉 You're Ready!

Your machine is now fully bootstrapped. Start developing! 🚀
