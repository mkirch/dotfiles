#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Resolve DOTLOC (dotfiles repo root)
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTLOC="${DOTLOC:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
export DOTLOC

###############################################################################
# Logging
###############################################################################
log() { printf '%s\n' "[dotfiles] $*"; }

err() {
  printf '%s\n' "[dotfiles:ERROR] $*" >&2
  exit 1
}

sep() {
  printf '%s\n' "----------------------------------------------------------"
}

###############################################################################
# Dir ensure
###############################################################################
ensure_dir() {
  [[ -d "$1" ]] || mkdir -p "$1"
}

###############################################################################
# Backup original file (only if not a symlink)
###############################################################################
backup() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    local backup_dir="$DOTLOC/backup/$(date +%Y-%m-%d_%H-%M-%S)"
    mkdir -p "$backup_dir"
    log "Backing up: $target → $backup_dir/"
    mv "$target" "$backup_dir/"
  fi
}

###############################################################################
# Symlink helper
###############################################################################
link() {
  local src="$1"
  local dest="$2"

  backup "$dest"
  ensure_dir "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  log "Linked: $dest → $src"
}

###############################################################################
# LINKALL — symlink repo → system (core function)
###############################################################################
linkall() {
  sep
  log "Applying symlinks from repo → system"
  sep

  # Zsh suite
  link "$DOTLOC/zsh/.zshrc" "$HOME/.zshrc"
  link "$DOTLOC/zsh/.zshenv" "$HOME/.zshenv"
  link "$DOTLOC/zsh/.zprofile" "$HOME/.zprofile"
  link "$DOTLOC/p10k/.p10k.zsh" "$HOME/.p10k.zsh"

  # Completion cache dir (lives in repo, used by zsh)
  ensure_dir "$DOTLOC/.zsh/.zcompcache"

  # Neovim
  ensure_dir "$HOME/.config"
  link "$DOTLOC/nvim" "$HOME/.config/nvim"

  # Ghostty
  ensure_dir "$HOME/Library/Application Support/com.mitchellh.ghostty"
  link "$DOTLOC/ghostty/config" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

  # Navi cheatsheets
  ensure_dir "$HOME/.local/share/navi"
  link "$DOTLOC/navi/cheats" "$HOME/.local/share/navi/cheats"

  # Mise global config
  ensure_dir "$HOME/.config/mise"
  link "$DOTLOC/mise/config.toml" "$HOME/.config/mise/config.toml"

  # Bash (minimal config for non-zsh shells)
  link "$DOTLOC/bash/.bashrc" "$HOME/.bashrc"

  # Make scripts available globally
  ensure_dir "$HOME/bin"
  link "$DOTLOC/scripts/dot.sh" "$HOME/bin/dot"
  link "$DOTLOC/scripts/ytdl.sh" "$HOME/bin/ytdl"
  link "$DOTLOC/scripts/wh.sh" "$HOME/bin/wh"

  sep
  log "All symlinks applied successfully"
}

###############################################################################
# MIGRATE — copy EXISTING configs FROM system → repo, then link
###############################################################################
migrate() {
  sep
  log "MIGRATING system configs → repo"
  sep

  ensure_dir "$DOTLOC/zsh"
  ensure_dir "$DOTLOC/p10k"
  ensure_dir "$DOTLOC/nvim"
  ensure_dir "$DOTLOC/ghostty"
  ensure_dir "$DOTLOC/navi/cheats"

  # Zsh suite
  [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$DOTLOC/zsh/.zshrc"
  [[ -f "$HOME/.zshenv" ]] && cp "$HOME/.zshenv" "$DOTLOC/zsh/.zshenv"
  [[ -f "$HOME/.zprofile" ]] && cp "$HOME/.zprofile" "$DOTLOC/zsh/.zprofile"
  [[ -f "$HOME/.p10k.zsh" ]] && cp "$HOME/.p10k.zsh" "$DOTLOC/p10k/.p10k.zsh"

  # Neovim
  if [[ -d "$HOME/.config/nvim" ]]; then
    rm -rf "$DOTLOC/nvim"
    cp -R "$HOME/.config/nvim" "$DOTLOC/nvim"
    log "Migrated Neovim config → $DOTLOC/nvim"
  fi

  # Ghostty
  local GHOSTTY_HOME="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  if [[ -d "$GHOSTTY_HOME" ]]; then
    rm -rf "$DOTLOC/ghostty/config"
    ensure_dir "$DOTLOC/ghostty"
    cp -R "$GHOSTTY_HOME" "$DOTLOC/ghostty/config"
    log "Migrated Ghostty config → $DOTLOC/ghostty/config"
  fi

  sep
  log "Migration complete — now linking"
  sep

  linkall
}

###############################################################################
# MISE_SETUP — trust config and install tools
###############################################################################
mise_setup() {
  sep
  log "Setting up mise"
  sep

  if ! command -v mise >/dev/null 2>&1; then
    log "mise not found. Installing via official installer..."
    curl https://mise.run | sh
  fi

  # Trust both the symlink target and the source file
  mise trust "$HOME/.config/mise/config.toml" 2>/dev/null || true
  mise trust "$DOTLOC/mise/config.toml" 2>/dev/null || true
  mise install

  sep
  log "mise setup complete"
}

###############################################################################
# BREW_SETUP — install Homebrew if missing, then bundle from Brewfile
###############################################################################
brew_setup() {
  sep
  log "Checking Homebrew"
  sep

  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew not found. Installing..."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ||
      err "Homebrew installation failed"

    log "Homebrew installed at: $(command -v brew)"
  else
    log "Homebrew already installed at: $(command -v brew)"
  fi

  if [[ -f "$DOTLOC/Brewfile" ]]; then
    sep
    log "Running brew bundle with $DOTLOC/Brewfile"
    sep
    brew bundle --file="$DOTLOC/Brewfile" || err "brew bundle failed"
  else
    log "No Brewfile found at $DOTLOC/Brewfile"
    log "You can create one later with:"
    log "  brew bundle dump --describe --file=\"$DOTLOC/Brewfile\""
  fi

  if [[ -f "$DOTLOC/Brewfile.local" ]]; then
    sep
    log "Running brew bundle with $DOTLOC/Brewfile.local"
    sep
    brew bundle --file="$DOTLOC/Brewfile.local" || err "brew bundle (local) failed"
  fi
}

###############################################################################
# CLAUDE_SETUP — install/update Claude Code via native installer
###############################################################################
claude_setup() {
  sep
  log "Checking Claude Code"
  sep

  if ! command -v claude >/dev/null 2>&1; then
    log "Claude Code not found. Installing via native installer..."
    curl -fsSL https://claude.ai/install.sh | bash
  else
    log "Claude Code found. Checking for updates..."
    claude update || true
  fi

  sep
  log "Claude Code setup complete"
}

###############################################################################
# BOOTSTRAP — fresh machine initialization
###############################################################################
bootstrap() {
  sep
  log "BOOTSTRAPPING new machine"
  sep

  ensure_dir "$DOTLOC/zsh"
  ensure_dir "$DOTLOC/p10k"
  ensure_dir "$DOTLOC/nvim"
  ensure_dir "$DOTLOC/ghostty"
  ensure_dir "$DOTLOC/navi/cheats"
  ensure_dir "$DOTLOC/scripts"
  ensure_dir "$DOTLOC/.zsh"

  ensure_dir "$HOME/.config"
  ensure_dir "$HOME/.local/share/navi"
  ensure_dir "$HOME/Library/Application Support/com.mitchellh.ghostty"

  # Link dotfiles into place
  linkall

  # Install mise and tools
  mise_setup

  # Install Homebrew and packages
  brew_setup

  # Install Claude Code
  claude_setup

  # Community navi cheatsheets
  navi_update

  sep
  log "Bootstrap complete — run: exec zsh -l"
}

###############################################################################
# UPDATE — re-link repo → system
###############################################################################
update() {
  sep
  log "Updating dotfiles (repo → system)"
  sep
  linkall
  sep
  log "Update completed"
}

###############################################################################
# SYNC — update links + mise + brew (all-in-one refresh)
###############################################################################
sync() {
  sep
  log "Syncing dotfiles (full refresh)"
  sep
  linkall
  mise_setup
  brew_setup
  claude_setup
  navi_update
  sep
  log "Sync complete — run: exec zsh -l"
}

###############################################################################
# NAVI — clone/pull community cheatsheets (gitignored)
###############################################################################
navi_update() {
  sep
  log "Updating navi community cheatsheets"
  sep

  local cheats_dir="$DOTLOC/navi/cheats"

  clone_or_pull() {
    local name="$1" url="$2"
    if [[ -d "$cheats_dir/$name/.git" ]]; then
      log "Pulling $name cheats..."
      git -C "$cheats_dir/$name" pull --ff-only
    else
      log "Cloning $name cheats..."
      rm -rf "$cheats_dir/$name"
      git clone --depth 1 "$url" "$cheats_dir/$name"
    fi
  }

  clone_or_pull community "https://github.com/denisidoro/cheats.git"
  clone_or_pull tldr      "https://github.com/denisidoro/navi-tldr-pages.git"

  sep
  log "Navi cheats updated"
}

###############################################################################
# FONTS — wrap fonts.sh if present
###############################################################################
fonts() {
  if [[ ! -f "$DOTLOC/scripts/fonts.sh" ]]; then
    err "fonts.sh not found at $DOTLOC/scripts/fonts.sh"
  fi
  bash "$DOTLOC/scripts/fonts.sh" "${@:1}"
}

###############################################################################
# HELP
###############################################################################
usage() {
  cat <<EOF
Usage: dot.sh <command>

Commands:
  sync              Full refresh: re-link + mise + brew + claude + navi
  update            Re-link all repo → system
  mise              Install mise (if needed) and run mise install
  brew              Install Homebrew (if needed) and run Brewfile
  claude            Install/update Claude Code via native installer
  navi              Clone/pull community navi cheatsheets
  bootstrap         Install dotfiles on a fresh machine
  migrate           Copy system configs → repo, then symlink everything
  linkall           Apply symlinks only (repo → system)
  fonts [...]       Pass through to scripts/fonts.sh
  help              Show this message

Dotfiles root: $DOTLOC
EOF
}

###############################################################################
# DISPATCHER
###############################################################################
cmd="${1:-help}"

case "$cmd" in
sync) sync ;;
bootstrap) bootstrap ;;
migrate) migrate ;;
update) update ;;
linkall) linkall ;;
mise) mise_setup ;;
brew) brew_setup ;;
claude) claude_setup ;;
navi) navi_update ;;
fonts) fonts "${@:2}" ;;
help | --help | -h) usage ;;
*) err "Unknown command: $cmd" ;;
esac
