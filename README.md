# Windows Bootstrap Architecture

A robust, profile-based bootstrap system for provisioning Windows machines using **WinGet**, **Mise**, and **Chezmoi**.

## 📋 Overview

This architecture separates concerns across three tools:

| Tool | Responsibility |
|------|-----------------|
| **WinGet** | Install Windows GUI applications and CLIs |
| **Mise** | Manage runtimes, versions, and development tools |
| **Chezmoi** | Apply and sync configuration files (dotfiles) |

## 🔄 Initialization Flow

```
Clean Machine
    ↓
[init.ps1] ← START HERE
    ├─ Check prerequisites (WinGet)
    ├─ Install Git
    ├─ Configure Git (name, email)
    ├─ Authenticate (GitHub/GitLab PAT)
    ├─ Clone lfaoliveira/FERRAMENTAS
    └─ Execute [bootstrap.ps1]
           ↓
    [bootstrap.ps1]
           ├─ Install WinGet packages (profile-based)
           ├─ Configure Mise tools
           ├─ Initialize Chezmoi
           └─ Set environment variables
                  ↓
           Ready for Development ✅
```

## 🎯 Profiles

### `work`
- Development-focused tools only
- Suitable for: work laptops, restricted machines
- Includes: VS Code, Git, Docker, Node.js, Python, etc.

### `full`
- Development + Personal applications
- Suitable for: personal laptops, desktops
- Includes: all work tools + gaming, media, creative apps

## 📂 Repository Structure

```
├── init.ps1                     # ⭐ Start here! Initializes clean machines
├── bootstrap.ps1                # Main orchestration script
├── README.md                    # This file
├── .gitignore                   # Git ignore rules
├── packages/
│   ├── winget-work.json        # Work profile packages
│   ├── winget-personal.json    # Personal/full profile packages
│   └── mise.toml               # Runtime and tool versions
└── chezmoi/
    ├── README.md               # Chezmoi documentation
    ├── dot_config/             # ~/.config files
    ├── dot_gitconfig           # ~/.gitconfig
    ├── dot_powershell/         # PowerShell profiles
    └── ...                     # Other dotfiles (prefix with dot_)
```

## 🚀 Quick Start

### Prerequisites

- Windows 10/11
- App Installer (WinGet) - [Microsoft Store](https://www.microsoft.com/store/apps/9NBLGGH4NNS1)
- Administrator/PowerShell access

### Installation

#### 🎯 For Clean Machines (Recommended)

Run the initializer script first. It handles everything:

```powershell
# Download and run init.ps1 on a clean machine
# This will:
#   1. Install Git
#   2. Request GitHub/GitLab PAT
#   3. Clone FERRAMENTAS repository
#   4. Run bootstrap automatically

.\init.ps1 -Profile work
.\init.ps1 -Profile full  # For personal machines
```

**With GitLab instead of GitHub:**
```powershell
.\init.ps1 -Profile work -GitPlatform gitlab
```

---

#### 🔄 For Existing FERRAMENTAS Directory

If you already have the FERRAMENTAS repository cloned:

#### 1️⃣ Work Profile

```powershell
# Run with administrator privileges
.\bootstrap.ps1 -Profile work
```

#### 2️⃣ Personal/Full Profile

```powershell
.\bootstrap.ps1 -Profile full
```

#### Optional: Skip specific tools

```powershell
# Skip WinGet installation
.\bootstrap.ps1 -Profile work -SkipWinget

# Skip Mise setup
.\bootstrap.ps1 -Profile full -SkipMise

# Skip Chezmoi initialization
.\bootstrap.ps1 -Profile work -SkipChezmoi
```

---

## 🔧 `init.ps1` - Initialization Script

The `init.ps1` script automates the entire setup process for clean machines.

### What it does

1. **Verifies prerequisites** - Checks Windows version and WinGet availability
2. **Installs Git** - Uses WinGet to install Git for Windows
3. **Configures Git** - Prompts for name and email
4. **GitHub/GitLab Authentication** - Collects Personal Access Token (PAT)
5. **Clones Repository** - Clones `lfaoliveira/FERRAMENTAS` to `~/FERRAMENTAS`
6. **Runs Bootstrap** - Automatically executes `bootstrap.ps1` with specified profile

### Usage

```powershell
# Default: work profile, GitHub
.\init.ps1

# Full profile with GitHub
.\init.ps1 -Profile full

# Work profile with GitLab
.\init.ps1 -Profile work -GitPlatform gitlab

# Full profile with GitLab
.\init.ps1 -Profile full -GitPlatform gitlab
```

### PAT (Personal Access Token) Setup

**GitHub:**
- Visit: https://github.com/settings/tokens
- Required scopes: `repo`, `workflow`
- Token will be prompted during script execution

**GitLab:**
- Visit: https://gitlab.com/-/user_settings/personal_access_tokens
- Required scopes: `api`, `read_repository`, `write_repository`
- Token will be prompted during script execution

### Security

- PAT is never stored in plain text on disk
- Credentials are cleared from memory after authentication
- Use GitHub/GitLab's credential helpers for subsequent operations

### Distribution

**To distribute `init.ps1` to clean machines:**

1. **Upload to your FERRAMENTAS repository** (root level)
2. **Host on a web server** or share via:
   ```powershell
   # Download and execute directly (if hosted online)
   $url = "https://your-server.com/init.ps1"
   Invoke-WebRequest -Uri $url -OutFile init.ps1
   .\init.ps1 -Profile work
   ```

3. **Create a shortcut** for users:
   ```powershell
   # Add to documentation
   Windows Key → PowerShell (Admin)
   Invoke-WebRequest https://raw.githubusercontent.com/lfaoliveira/FERRAMENTAS/main/init.ps1 -OutFile init.ps1
   .\init.ps1
   ```

## 📦 What Gets Installed

### All Profiles

**Core Tools:**
- Brave Browser
- Visual Studio Code
- Git
- Docker Desktop
- Node.js
- Python (Miniconda3)
- Mise (tool manager)
- Chezmoi (dotfile manager)

**Development Tools:**
- Obsidian (notes)
- Postman (API testing)
- Beekeeper Studio (database)
- WinRAR (compression)

### Personal/Full Profile Only

**Additional Tools:**
- Steam (gaming)
- Spotify (music)
- Discord (communication)
- JetBrains IntelliJ IDEA Community
- UV (Python package manager)
- Epic Games Launcher
- VLC Media Player

## 🛠️ Configuration

### WinGet Packages

Edit the JSON files to add/remove applications:

```json
{
  "PackageIdentifier": "Publisher.Package",
  "Version": "latest"
}
```

Find package IDs at: https://winget.run

### Mise Tools

Edit `packages/mise.toml` to manage runtimes and versions:

```toml
[tools]
python = "3.11"
go = "latest"
rust = "latest"
```

### Chezmoi Dotfiles

1. Place configuration files in the `chezmoi/` directory
2. Prefix hidden files/folders with `dot_`:
   - `dot_gitconfig` → `~/.gitconfig`
   - `dot_config/` → `~/.config/`
   - `dot_ssh/` → `~/.ssh/`

3. Apply configurations:
   ```powershell
   chezmoi apply
   ```

## 🔧 Advanced Usage

### Edit files with Chezmoi

```powershell
# Opens editor and applies changes automatically
chezmoi edit ~/.gitconfig
```

### Preview changes

```powershell
chezmoi diff
```

### Check installation status

```powershell
# WinGet packages
winget list

# Mise tools
mise versions

# Chezmoi status
chezmoi status
```

### Switch profiles

To switch from `work` to `full`:

```powershell
.\bootstrap.ps1 -Profile full
```

This will install the additional personal applications.

## 🔐 Security Notes

1. **Keep secrets out of Chezmoi**: Use environment variables or separate config files
2. **Sensitive files**: Store outside the repository (API keys, passwords, SSH keys)
3. **Execution policy**: The script sets RemoteSigned policy for CurrentUser scope
4. **Git in Chezmoi**: Chezmoi uses Git internally—ensure credentials are configured

## 📝 Customization

### For Work Machines

1. Edit `packages/winget-work.json`:
   - Add company tools/licenses
   - Remove unnecessary applications

2. Customize `chezmoi/` for work configurations:
   - Git config with work email
   - Work-specific VS Code settings
   - Corporate proxy settings

### For Personal Machines

1. Edit `packages/winget-personal.json`:
   - Add your preferred applications
   - Remove work-related tools

2. Customize `chezmoi/` with personal preferences:
   - Gaming configurations
   - Media player settings
   - Personal project templates

## 🐛 Troubleshooting

### WinGet fails to install

```powershell
# Ensure App Installer is updated
winget upgrade Microsoft.AppInstaller

# Clear WinGet cache
winget cache

# Retry bootstrap
.\bootstrap.ps1 -Profile work
```

### Mise tools not found

```powershell
# Refresh PATH
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

# Check installed tools
mise versions
```

### Chezmoi changes not applied

```powershell
# Check what would change
chezmoi diff

# Manually apply
chezmoi apply --verbose

# Check status
chezmoi status
```

## 📚 Resources

- **Mise**: https://mise.jdx.dev
- **Chezmoi**: https://www.chezmoi.io
- **WinGet**: https://github.com/microsoft/winget-cli
- **Windows Package Manager**: https://winget.run

## 📄 License

[Your License Here]

## 🤝 Contributing

To improve this bootstrap:

1. Test changes on a clean machine
2. Document additions in relevant sections
3. Keep profiles focused and minimal
4. Add to the appropriate profile (work/personal)

---

**Last Updated**: 2026-04-28
