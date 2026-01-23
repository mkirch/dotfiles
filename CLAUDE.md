# CLAUDE.md - AI Assistant Guide for @mkirch/dotfiles

This document provides context for AI assistants working with this dotfiles repository.

## Repository Overview

This is a personal dotfiles repository for configuring a modern development environment. It includes configuration for:

- **Shell**: Zsh with Znap plugin manager and Powerlevel10k prompt
- **Editor**: Neovim with LazyVim distribution
- **Terminal**: Ghostty (macOS)
- **Tooling**: uv (Python), fnm (Node.js), fzf, zoxide, and more

**Repository URL**: https://github.com/mkirch/dotfiles
**License**: MIT

## Directory Structure

```
dotfiles/
├── zsh/                    # Z shell configuration
│   ├── .zshenv             # Environment variables (all zsh processes)
│   ├── .zshrc              # Interactive shell setup
│   └── .zsh_aliases.example # Template for private aliases
├── p10k/                   # Powerlevel10k prompt theme
│   └── .p10k.zsh           # Prompt customization
├── nvim/                   # Neovim configuration (LazyVim-based)
│   ├── init.lua            # Entry point
│   ├── lazyvim.json        # LazyVim extras configuration
│   └── lua/
│       ├── config/         # Core config (options, keymaps, autocmds)
│       └── plugins/        # Plugin configurations
├── ghostty/                # Ghostty terminal config
│   └── config              # Terminal settings
├── scripts/                # Automation scripts
│   ├── update.sh           # Sync configs to $HOME
│   ├── fonts.sh            # Nerd Font installation
│   └── whisper_transcription.sh # Media transcription
├── fnm/                    # Fast Node Manager install script
├── .env.example            # Environment variable template
├── .gitignore              # Comprehensive ignore patterns
└── README.md               # User documentation
```

## Key Concepts

### Auto-Detection Pattern

The repository uses smart auto-detection for `DOTLOC` (dotfiles location). The `.zshenv` walks up the directory tree looking for `.env.example` and `scripts/update.sh` to determine the repo root. This allows running scripts from anywhere within the repository.

### Environment Variables

Configuration is personalized via environment variables in `.env` (copied to `~/.dotfiles.env` by `update.sh`):

| Variable | Purpose |
|----------|---------|
| `DOTLOC` | Repository path (auto-detected) |
| `DEV_HOME` | Root for personal projects (default: `$HOME/Developer`) |
| `WHISPER_CPP_DIR` | whisper.cpp build location |
| `CURSOR_USER_DATA_DIR` | Cursor IDE profile directory |
| `CLAUDE_BINARY` | Path to local Claude CLI |

### Private Configuration

These files are gitignored and should never be committed:
- `.env` / `~/.dotfiles.env` - Personal environment variables
- `zsh/.zsh_aliases` - Personal shell aliases
- `cursor/` - Cursor IDE profiles

## Development Workflow

### Making Configuration Changes

1. Edit files in the dotfiles repository (not in `$HOME`)
2. Run `./scripts/update.sh` to sync changes to the system
3. For shell changes, run `exec zsh -l` or open a new terminal

The `dup` alias combines these: `$DOTLOC/scripts/update.sh && exec zsh -l`

### Script Purposes

| Script | Purpose |
|--------|---------|
| `update.sh` | Copies all configs to `$HOME` locations (requires `rsync`) |
| `fonts.sh` | Installs Nerd Fonts (`--install`) or patches fonts (`--patch`) |
| `whisper_transcription.sh` | Transcribes audio/video using whisper.cpp |

### Sync Targets

`update.sh` copies files to these locations:
- `.env` → `~/.dotfiles.env`
- `zsh/.zshenv` → `~/.zshenv`
- `zsh/.zshrc` → `~/.zshrc`
- `p10k/.p10k.zsh` → `~/.p10k.zsh`
- `nvim/` → `~/.config/nvim/` (full directory sync)
- `ghostty/config` → `~/Library/Application Support/com.mitchellh.ghostty/config`

## Code Conventions

### Shell Scripts

- Use `set -euo pipefail` for safety
- Include `usage()` functions for user-facing scripts
- Use `log()` helper for consistent output formatting
- Check for required commands with `require_cmd()`

### Zsh Configuration

- Structure: `.zshenv` (minimal, all shells) → `.zshrc` (interactive only)
- Load order in `.zshrc`:
  1. Powerlevel10k instant prompt
  2. Environment file sourcing
  3. Shell options and history
  4. Completion paths
  5. Znap plugin manager
  6. Plugins and tools
  7. PATH additions
  8. Aliases
  9. Functions
  10. Editor settings

### Neovim (LazyVim)

- Entry: `init.lua` requires `config.lazy`
- Options: `lua/config/options.lua`
- Keymaps: `lua/config/keymaps.lua`
- Autocmds: `lua/config/autocmds.lua`
- Plugins: `lua/plugins/*.lua`

LazyVim extras enabled (see `lazyvim.json`):
- Languages: Python, TypeScript, Rust, Docker, SQL, Terraform, and more
- Tools: fzf, telescope, ESLint, Biome
- UI: alpha, edgy, mini-animate

### Lua Formatting

Uses StyLua with configuration in `nvim/stylua.toml`.

## Tool Aliases

The configuration replaces standard tools with modern alternatives:

| Alias | Replacement | Purpose |
|-------|-------------|---------|
| `find` | `fd` | Fast file finder |
| `du` | `dust` | Disk usage |
| `ps` | `procs` | Process viewer |
| `cloc` | `tokei` | Line counter |
| `tm` | `hyperfine` | Benchmarking |
| `top/htop` | `btm` | System monitor |
| `l/ll/lt` | `eza` | Enhanced ls |

## AI Assistant Guidelines

### When Modifying This Repository

1. **Edit source files** in the repository, not copies in `$HOME`
2. **Test changes** by running `./scripts/update.sh`
3. **Preserve patterns**: Maintain the auto-detection logic in `.zshenv`
4. **Keep private files private**: Never add content to `.env`, `.zsh_aliases`, or `cursor/`
5. **Update templates**: If adding new private config, update `.example` files

### Common Tasks

**Adding a new alias**:
- Add to `zsh/.zshrc` in the aliases section (lines 152-246)
- For private aliases, instruct user to add to `zsh/.zsh_aliases`

**Adding a new Neovim plugin**:
- Create or edit files in `nvim/lua/plugins/`
- Follow LazyVim plugin spec format

**Adding a new tool initialization**:
- Add to `zsh/.zshrc` section 5 (Plugins, completions, tool init)
- Use `znap eval` for lazy loading when possible

**Modifying PATH**:
- Core PATH is in `zsh/.zshenv`
- Interactive-only PATH additions in `zsh/.zshrc` section 6

### Platform Notes

- Primary target: **macOS** (Homebrew paths, Ghostty config location)
- Secondary: **Linux** (basic compatibility, no Ghostty on Linux)
- Ghostty config uses macOS path: `~/Library/Application Support/com.mitchellh.ghostty/config`

### Dependencies

Scripts assume these tools are available:
- `rsync` (required by `update.sh`)
- `git` (for Znap bootstrap)
- `brew` (optional, for completions and fonts)
- `ffmpeg` (for `whisper_transcription.sh`)

## Testing Changes

1. After shell config changes: `source ~/.zshrc` or `exec zsh -l`
2. After Neovim changes: Restart Neovim (`:Lazy sync` for plugin updates)
3. After script changes: Run the script with `--help` or test flags if available

## Commit Style

Recent commits use short, descriptive messages. The repository history shows informal commit messages with occasional emoji usage.

## Quick Reference

```bash
# Edit shell config
nvim "$DOTLOC/zsh/.zshrc"     # or use 'nz' alias

# Sync all configs
./scripts/update.sh            # or use 'dup' alias

# Install fonts
./scripts/fonts.sh --install   # Nerd Fonts via Homebrew
./scripts/fonts.sh --patch     # Patch SF Mono

# Check Neovim health
nvim +checkhealth
```
