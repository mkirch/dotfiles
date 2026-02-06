# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository for macOS using symlink-based management. Configuration files live in this repo and are symlinked to their expected system locations.

## Commands

### Primary Management (use `dot` command)

```bash
dot sync       # Full refresh: re-link + mise + brew + claude
dot update     # Re-link all repo configs to system locations
dot bootstrap  # Fresh machine setup (links + mise + brew + claude)
dot migrate    # Copy existing system configs into repo, then link
dot linkall    # Apply symlinks only (repo → system)
dot mise       # Install mise tools from mise/config.toml
dot brew       # Install Homebrew packages from Brewfile
dot claude     # Install/update Claude Code via native installer
dot fonts [--install|--patch]  # Install Nerd Fonts or patch SF Mono
```

### Shell Aliases

```bash
nz     # Edit zsh/.zshrc in nvim
ndot   # Edit zsh/.zshenv in nvim
rz     # Reload shell: exec zsh -l
```

## Architecture

### Symlink Strategy

`scripts/dot.sh` is the central management script that creates symlinks from this repo to system locations:

| Repo Path | System Path |
|-----------|-------------|
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/.zshenv` | `~/.zshenv` |
| `zsh/.zprofile` | `~/.zprofile` |
| `p10k/.p10k.zsh` | `~/.p10k.zsh` |
| `nvim/` | `~/.config/nvim` |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| `navi/cheats/` | `~/.local/share/navi/cheats` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `bash/.bashrc` | `~/.bashrc` |
| `scripts/dot.sh` | `~/bin/dot` |

Existing files are backed up to `backup/<timestamp>/` before linking.

### Shell Configuration

- **zsh/.zshenv**: Minimal environment loaded for ALL zsh processes (PATH, exports, telemetry opt-outs)
- **zsh/.zshrc**: Interactive shell setup with Znap plugin manager and Powerlevel10k prompt
- **zsh/.zsh_aliases**: Private aliases file (gitignored) - copy from `.zsh_aliases.example`

Key environment variables (set in `$DOTLOC/.env`):
- `DOTLOC`: Path to this repo (auto-detected)
- `DEV_HOME`: Development root (default: `~/Developer`)

### Tool Management

**mise** (`mise/config.toml`): Manages Node.js, pnpm, gh CLI, terraform, and modern CLI tools (fd, bat, fzf, ripgrep, zoxide, eza, etc.)

See [`docs/mise-backend-selection.md`](docs/mise-backend-selection.md) for backend selection guide. Priority: `aqua` (checksums) → `cargo` (source) → `github` (lockfile) → language-specific (`npm`/`pipx`/`gem`)

**Homebrew** (`Brewfile`): System packages, casks, fonts, and VS Code extensions

### Neovim

LazyVim-based configuration in `nvim/`:
- `nvim/lazyvim.json`: Enabled LazyVim extras (language support, AI, UI)
- `nvim/lua/config/`: Options, keymaps, autocmds
- `nvim/lua/plugins/`: Custom plugin configurations

### Private/Gitignored Files

- `zsh/.zsh_aliases` - Personal aliases
- `.env` - Machine-specific environment variables (sourced by .zshenv)
- `backup/` - Automatic backups of replaced configs
- `cursor/` profiles - Cursor editor user data

## Python Workflow

Uses `uv` exclusively (direct `pip` is blocked by shell function):
- `uv add` / `uv sync` for project dependencies
- `uv tool run` for ruff, mypy, pytest
- `py <script>` runs `uv run python`
- `pyinit` scaffolds new uv projects
