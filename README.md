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
Clean Machine (with WinGet + Git)
    ↓
[init.ps1] ← START HERE
    ├─ Verify prerequisites (WinGet, Mise)
    └─ Execute Mise tasks
           ↓
    [mise run bootstrap]
           ├─ bootstrap:check     - Verify WinGet installed
           ├─ bootstrap:packages  - Install WinGet packages (profile-specific)
           ├─ bootstrap:tools     - Install Mise tools (python, go, node, etc)
           └─ bootstrap:chezmoi   - Initialize Chezmoi dotfile manager
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
├── init.ps1                     # ⭐ Start here! Entry point for bootstrap
├── mise.toml                    # Mise tasks and tool configuration
├── README.md                    # This file
├── INSTALL.md                   # Detailed installation guide
├── bootstrap.ps1                # [Legacy] Standalone bootstrap script
├── .gitignore                   # Git ignore rules
├── packages/
│   ├── winget-work.json        # Work profile WinGet packages
│   ├── winget-personal.json    # Personal/full profile packages
│   └── mise.toml               # Runtime version management (deprecated)
└── chezmoi/
    ├── README.md               # Chezmoi documentation
    ├── dot_config/             # ~/.config files
    ├── dot_gitconfig           # ~/.gitconfig
    ├── dot_powershell/         # PowerShell profiles
    └── ...                     # Other dotfiles (prefix with dot_)
```

**Note:** `bootstrap.ps1` is kept for backward compatibility but is now executed via Mise tasks in `mise.toml`

## 🚀 Quick Start

### Prerequisites
- Windows 10/11
- Administrator/PowerShell access

### Installation

#### 🎯 For Clean Machines (Recommended)

Run the initializer script first:

```powershell
.\init.ps1
```

The script will:
1. ✅ Execute `mise run bootstrap` to install everything
2. ✅ Set up environment variables

---

#### 🔄 For Existing FERRAMENTAS Directory

If you already have the FERRAMENTAS repository cloned, run tasks directly:

```powershell
# Run complete bootstrap with Mise tasks
mise run bootstrap

# Or run individual tasks
mise run bootstrap:check        # Verify prerequisites
mise run bootstrap:packages     # Install WinGet packages
mise run bootstrap:tools        # Install Mise tools
mise run bootstrap:chezmoi      # Initialize Chezmoi
```

---

## 🔧 Using Mise Tasks

All bootstrap operations are managed through Mise tasks defined in `mise.toml`.

### Available Tasks

```powershell
# Main bootstrap task (runs all subtasks)
mise run bootstrap

# Utility tasks
mise run versions              # Show installed versions
mise run status                # Show bootstrap status
mise run help                  # Show task help
```

### Task Details

**bootstrap:check**
- Verifies Windows version
- Checks execution policy
- Validates WinGet and Mise installation

**bootstrap:packages**
- Installs Windows applications via WinGet
- Uses `packages/winget-${BOOTSTRAP_PROFILE}.json`
- Supports `work` and `personal` profiles

**bootstrap:tools**
- Installs development tools via Mise
- Installs: Python, Node.js, Go, Java, Task runner
- Configured in `packages/mise.toml`

**bootstrap:chezmoi**
- Initializes Chezmoi dotfile manager
- Sets up git repository in `~/.local/share/chezmoi/`
- Prepares to apply configurations from `./chezmoi/`

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
