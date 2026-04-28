# Chezmoi Dotfiles

This directory contains your dotfile configurations managed by [Chezmoi](https://www.chezmoi.io).

## Structure

```
chezmoi/
├── README.md
├── dot_config/          # ~/.config/ files
│   ├── mise/
│   └── other_tools/
├── dot_gitconfig       # ~/.gitconfig
├── dot_powershell/     # PowerShell profile
├── dot_ssh/            # SSH configuration
└── ...                 # Other dotfiles
```

## How to use

1. Add or modify files in this directory
2. Prefix directories and files with `dot_` to represent hidden `.` files
3. Run `chezmoi apply` to apply changes to your home directory
4. Use `chezmoi edit` to edit files with automatic application

## Examples

- `dot_gitconfig` → `~/.gitconfig`
- `dot_ssh/dot_config` → `~/.ssh/config`
- `dot_config/mise` → `~/.config/mise`

## Commands

```powershell
# Apply all configurations
chezmoi apply

# Edit a file and apply changes
chezmoi edit ~/.gitconfig

# Show what would change
chezmoi diff

# Check status
chezmoi status

# Update from repository
chezmoi update
```

## Notes

- Customize based on your needs (work vs personal profile)
- Keep sensitive data (API keys, passwords) outside version control
- Consider using Chezmoi templates for machine-specific configurations
