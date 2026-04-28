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
- **Administrator access** (required for installations)
- **Internet connection** (for downloads and Git access)

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

### 3. Provide Information When Prompted

The script will ask for:

1. **Git Name** - Your full name (for commits)
   ```
   Enter your name for Git config
   ```

2. **Git Email** - Your email address
   ```
   Enter your email for Git config
   ```

3. **Browser Open** - Opens GitHub/GitLab token creation page
   ```
   Open token creation page in browser? (Y/n)
   ```

4. **Personal Access Token (PAT)** - Copy-paste from GitHub/GitLab
   ```
   Paste your Personal Access Token: ••••••••••••••••
   ```

### 4. Wait for Installation

The script will:
- ✅ Install Git
- ✅ Clone the FERRAMENTAS repository
- ✅ Install all applications (WinGet)
- ✅ Install development tools (Mise)
- ✅ Initialize dotfile manager (Chezmoi)

This can take **30-60 minutes** depending on your internet speed.

### 5. Restart Terminal

After completion, close and reopen PowerShell for environment changes to take effect.

---

## 🔑 Getting a Personal Access Token (PAT)

### GitHub

1. Visit: https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give it a name: `FERRAMENTAS Bootstrap`
4. Select scopes:
   - ✅ `repo` (full control of private repositories)
   - ✅ `workflow` (update GitHub Action workflows)
5. Click **"Generate token"**
6. **Copy** the token immediately (you won't see it again)
7. Paste into the script when prompted

### GitLab

1. Visit: https://gitlab.com/-/user_settings/personal_access_tokens
2. Click **"Create new token"**
3. Give it a name: `FERRAMENTAS Bootstrap`
4. Select scopes:
   - ✅ `api` (read/write API)
   - ✅ `read_repository` (read repository)
   - ✅ `write_repository` (write repository)
5. Set expiration (optional but recommended)
6. Click **"Create personal access token"**
7. **Copy** the token
8. Paste into the script when prompted

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
cd ~/FERRAMENTAS
.\bootstrap.ps1 -Profile full
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
.\init.ps1 -Profile work
```

### Git clone fails

**Error:** "fatal: repository not found" or "Authentication failed"

**Solutions:**
1. Verify PAT is correct (no extra spaces)
2. Verify you're using the right Git platform (GitHub vs GitLab)
3. Check your internet connection
4. Try running again - sometimes transient failures occur

### Mise tools not found after restart

**Solution:** Restart PowerShell again. Sometimes the PATH takes a moment to update.

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
