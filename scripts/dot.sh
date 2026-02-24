#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Platform detection
###############################################################################
detect_platform() {
  case "$(uname -s)" in
    Darwin)              PLATFORM="macos" ;;
    Linux)
      if grep -qsi microsoft /proc/version 2>/dev/null; then
        PLATFORM="wsl"
      else
        PLATFORM="linux"
      fi ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
    *)                    PLATFORM="unknown" ;;
  esac
  export PLATFORM
}
detect_platform

###############################################################################
# Resolve DOTLOC and XDG directories
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTLOC="${DOTLOC:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
export DOTLOC

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

###############################################################################
# Logging / flags
###############################################################################
DRY_RUN="${DRY_RUN:-0}"

log()  { printf '%s\n' "[dotfiles] $*"; }
warn() { printf '%s\n' "[dotfiles:WARN] $*" >&2; }

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
  if [[ -d "$1" ]]; then return; fi
  if [[ "$DRY_RUN" == "1" ]]; then
    log "(dry-run) would create directory: $1"
  else
    mkdir -p "$1"
  fi
}

###############################################################################
# Backup original file (only if not a symlink)
# Uses a single backup directory per invocation to avoid timestamp scatter
###############################################################################
_BACKUP_DIR=""
backup() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    if [[ -z "$_BACKUP_DIR" ]]; then
      _BACKUP_DIR="$DOTLOC/backup/$(date +%Y-%m-%d_%H-%M-%S)"
    fi
    if [[ "$DRY_RUN" == "1" ]]; then
      log "(dry-run) would back up: $target → $_BACKUP_DIR/"
    else
      mkdir -p "$_BACKUP_DIR"
      log "Backing up: $target → $_BACKUP_DIR/"
      mv "$target" "$_BACKUP_DIR/"
    fi
  fi
}

###############################################################################
# Symlink helper
###############################################################################
link() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    warn "Source missing, skipping: $src"
    return
  fi

  backup "$dest"

  if [[ "$DRY_RUN" == "1" ]]; then
    log "(dry-run) would link: $dest → $src"
    return
  fi
  ensure_dir "$(dirname "$dest")"
  # Remove existing symlink or directory — ln -sf on macOS creates a link
  # *inside* an existing directory instead of replacing it
  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -d "$dest" && -d "$src" ]]; then
    rm -rf "$dest"
  fi
  ln -snf "$src" "$dest"
  log "Linked: $dest → $src"
}

###############################################################################
# Platform-specific path helpers
###############################################################################
ghostty_config_dir() {
  case "$PLATFORM" in
    macos) echo "$HOME/Library/Application Support/com.mitchellh.ghostty" ;;
    *)     echo "$XDG_CONFIG_HOME/ghostty" ;;
  esac
}

###############################################################################
# LINKALL — symlink repo → system (core function)
###############################################################################
linkall() {
  sep
  log "Applying symlinks from repo → system  [platform=$PLATFORM]"
  sep

  # Zsh suite
  link "$DOTLOC/zsh/.zshrc"     "$HOME/.zshrc"
  link "$DOTLOC/zsh/.zshenv"    "$HOME/.zshenv"
  link "$DOTLOC/zsh/.zprofile"  "$HOME/.zprofile"
  link "$DOTLOC/p10k/.p10k.zsh" "$HOME/.p10k.zsh"

  # Completion cache dir (lives in repo, used by zsh)
  ensure_dir "$DOTLOC/.zsh/.zcompcache"

  # Neovim
  ensure_dir "$XDG_CONFIG_HOME"
  link "$DOTLOC/nvim" "$XDG_CONFIG_HOME/nvim"

  # Ghostty (platform-aware path)
  local ghostty_dir
  ghostty_dir="$(ghostty_config_dir)"
  ensure_dir "$ghostty_dir"
  link "$DOTLOC/ghostty/config" "$ghostty_dir/config"

  # Navi cheatsheets
  ensure_dir "$XDG_DATA_HOME/navi"
  link "$DOTLOC/navi/cheats" "$XDG_DATA_HOME/navi/cheats"

  # Mise global config
  ensure_dir "$XDG_CONFIG_HOME/mise"
  link "$DOTLOC/mise/config.toml" "$XDG_CONFIG_HOME/mise/config.toml"

  # Bash (minimal config for non-zsh shells)
  link "$DOTLOC/bash/.bashrc" "$HOME/.bashrc"

  # Make scripts available globally
  ensure_dir "$HOME/bin"
  link "$DOTLOC/scripts/dot.sh"  "$HOME/bin/dot"
  link "$DOTLOC/scripts/ytdl.sh" "$HOME/bin/ytdl"
  link "$DOTLOC/scripts/wh.sh"   "$HOME/bin/wh"

  sep
  log "All symlinks applied successfully"
}

###############################################################################
# MIGRATE — copy EXISTING configs FROM system → repo, then link
# Skips files that are already symlinks (i.e. previously managed by dot)
###############################################################################
migrate() {
  sep
  log "MIGRATING system configs → repo  [platform=$PLATFORM]"
  sep

  if [[ "$DRY_RUN" == "1" ]]; then
    for f in .zshrc .zshenv .zprofile; do
      [[ -f "$HOME/$f" && ! -L "$HOME/$f" ]] && log "(dry-run) would copy: $HOME/$f → $DOTLOC/zsh/$f"
    done
    [[ -f "$HOME/.p10k.zsh" && ! -L "$HOME/.p10k.zsh" ]] && log "(dry-run) would copy: $HOME/.p10k.zsh → $DOTLOC/p10k/.p10k.zsh"
    [[ -d "$XDG_CONFIG_HOME/nvim" && ! -L "$XDG_CONFIG_HOME/nvim" ]] && log "(dry-run) would copy: $XDG_CONFIG_HOME/nvim → $DOTLOC/nvim"
    ghostty_cfg="$(ghostty_config_dir)/config"
    [[ -e "$ghostty_cfg" && ! -L "$ghostty_cfg" ]] && log "(dry-run) would copy: $ghostty_cfg → $DOTLOC/ghostty/config"
    [[ -d "$XDG_DATA_HOME/navi/cheats" && ! -L "$XDG_DATA_HOME/navi/cheats" ]] && log "(dry-run) would copy: $XDG_DATA_HOME/navi/cheats → $DOTLOC/navi/"
    [[ -f "$XDG_CONFIG_HOME/mise/config.toml" && ! -L "$XDG_CONFIG_HOME/mise/config.toml" ]] && log "(dry-run) would copy: $XDG_CONFIG_HOME/mise/config.toml → $DOTLOC/mise/config.toml"
    sep
    log "(dry-run) then would apply symlinks:"
    sep
    linkall
    return
  fi

  ensure_dir "$DOTLOC/zsh"
  ensure_dir "$DOTLOC/p10k"
  ensure_dir "$DOTLOC/nvim"
  ensure_dir "$DOTLOC/ghostty"
  ensure_dir "$DOTLOC/navi/cheats"
  ensure_dir "$DOTLOC/mise"

  # Zsh suite — only copy real files, not our own symlinks
  for f in .zshrc .zshenv .zprofile; do
    [[ -f "$HOME/$f" && ! -L "$HOME/$f" ]] && cp "$HOME/$f" "$DOTLOC/zsh/$f"
  done
  [[ -f "$HOME/.p10k.zsh" && ! -L "$HOME/.p10k.zsh" ]] && \
    cp "$HOME/.p10k.zsh" "$DOTLOC/p10k/.p10k.zsh"

  # Neovim
  if [[ -d "$XDG_CONFIG_HOME/nvim" && ! -L "$XDG_CONFIG_HOME/nvim" ]]; then
    rm -rf "${DOTLOC:?}/nvim"
    cp -R "$XDG_CONFIG_HOME/nvim" "$DOTLOC/nvim"
    log "Migrated Neovim config → $DOTLOC/nvim"
  fi

  # Ghostty (platform-aware, file not directory)
  local ghostty_cfg
  ghostty_cfg="$(ghostty_config_dir)/config"
  if [[ -e "$ghostty_cfg" && ! -L "$ghostty_cfg" ]]; then
    ensure_dir "$DOTLOC/ghostty"
    cp "$ghostty_cfg" "$DOTLOC/ghostty/config"
    log "Migrated Ghostty config → $DOTLOC/ghostty/config"
  fi

  # Navi cheatsheets
  if [[ -d "$XDG_DATA_HOME/navi/cheats" && ! -L "$XDG_DATA_HOME/navi/cheats" ]]; then
    cp -R "$XDG_DATA_HOME/navi/cheats" "$DOTLOC/navi/"
    log "Migrated Navi cheats → $DOTLOC/navi/cheats"
  fi

  # Mise
  if [[ -f "$XDG_CONFIG_HOME/mise/config.toml" && ! -L "$XDG_CONFIG_HOME/mise/config.toml" ]]; then
    cp "$XDG_CONFIG_HOME/mise/config.toml" "$DOTLOC/mise/config.toml"
    log "Migrated mise config → $DOTLOC/mise/config.toml"
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

  if [[ "$DRY_RUN" == "1" ]]; then
    if ! command -v mise >/dev/null 2>&1; then
      log "(dry-run) would install mise via curl | sh"
    else
      log "(dry-run) would run: mise trust + mise install --yes"
    fi
    return
  fi

  if ! command -v mise >/dev/null 2>&1; then
    log "mise not found. Installing via official installer..."
    curl -fsSL https://mise.run | sh
  fi

  mise trust "$XDG_CONFIG_HOME/mise/config.toml" 2>/dev/null || true
  mise trust "$DOTLOC/mise/config.toml" 2>/dev/null || true
  mise install --yes

  sep
  log "mise setup complete"
}

###############################################################################
# BREW_INSTALL — add package(s) to Brewfile and install
###############################################################################
brew_install() {
  local type="brew"
  local pkgs=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cask) type="cask"; shift ;;
      -*)     warn "Unknown option: $1"; shift ;;
      *)      pkgs+=("$1"); shift ;;
    esac
  done

  if [[ ${#pkgs[@]} -eq 0 ]]; then
    err "Usage: dot brew install [--cask] <package> ..."
  fi

  _init_brew_env

  local brewfile="$DOTLOC/Brewfile"
  if [[ ! -f "$brewfile" ]]; then
    err "Brewfile not found at $brewfile"
  fi

  local changed=0
  for pkg in "${pkgs[@]}"; do
    # Check if already in Brewfile
    if grep -q "^${type} \"${pkg}\"" "$brewfile"; then
      log "Already in Brewfile: ${type} \"${pkg}\""
      continue
    fi

    if [[ "$DRY_RUN" == "1" ]]; then
      log "(dry-run) would add to Brewfile: ${type} \"${pkg}\""
      continue
    fi

    # Try to get package description
    local desc=""
    if command -v brew >/dev/null 2>&1; then
      desc=$(brew desc "$pkg" 2>/dev/null | sed "s/^[^:]*: //" || true)
    fi

    # Build entry lines
    local entry
    if [[ -n "$desc" ]]; then
      entry="# ${desc}
${type} \"${pkg}\""
    else
      entry="${type} \"${pkg}\""
    fi

    # Insert after the last line of the matching type for clean grouping
    local last_line
    last_line=$(grep -n "^${type} " "$brewfile" | tail -1 | cut -d: -f1)
    if [[ -n "$last_line" ]]; then
      local total
      total=$(wc -l < "$brewfile")
      {
        head -n "$last_line" "$brewfile"
        printf '%s\n' "$entry"
        if [[ "$last_line" -lt "$total" ]]; then
          tail -n +"$((last_line + 1))" "$brewfile"
        fi
      } > "$brewfile.tmp" && mv "$brewfile.tmp" "$brewfile"
    else
      printf '%s\n' "$entry" >> "$brewfile"
    fi

    log "Added to Brewfile: ${type} \"${pkg}\""
    ((changed++))
  done

  if [[ "$changed" -gt 0 ]]; then
    sep
    log "Running brew bundle to install"
    sep
    brew bundle --file="$brewfile" || err "brew bundle failed"
  elif [[ "$DRY_RUN" == "1" ]]; then
    log "(dry-run) would run: brew bundle --file=$brewfile"
  fi
}

###############################################################################
# BREW_SETUP — install Homebrew if missing, then bundle from Brewfile
###############################################################################
_init_brew_env() {
  if [[ "$PLATFORM" == "macos" ]]; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  elif [[ "$PLATFORM" == "linux" || "$PLATFORM" == "wsl" ]]; then
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  fi
}

brew_setup() {
  if [[ "$PLATFORM" == "windows" ]]; then
    warn "Homebrew is not supported natively on Windows; skipping"
    return
  fi

  sep
  log "Checking Homebrew"
  sep

  if [[ "$DRY_RUN" == "1" ]]; then
    command -v brew >/dev/null 2>&1 || _init_brew_env
    if ! command -v brew >/dev/null 2>&1; then
      log "(dry-run) would install Homebrew via curl | bash"
    else
      log "(dry-run) would run: brew bundle --file=$DOTLOC/Brewfile"
      [[ -f "$DOTLOC/Brewfile.local" ]] && log "(dry-run) would run: brew bundle --file=$DOTLOC/Brewfile.local"
    fi
    return
  fi

  command -v brew >/dev/null 2>&1 || _init_brew_env

  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew not found. Installing..."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ||
      err "Homebrew installation failed"

    _init_brew_env
  fi

  log "Homebrew: $(brew --prefix)"

  if [[ -f "$DOTLOC/Brewfile" ]]; then
    sep
    log "Running brew bundle with $DOTLOC/Brewfile"
    sep
    brew bundle --file="$DOTLOC/Brewfile" || err "brew bundle failed"
  else
    log "No Brewfile found at $DOTLOC/Brewfile"
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

  if [[ "$DRY_RUN" == "1" ]]; then
    if ! command -v claude >/dev/null 2>&1; then
      log "(dry-run) would install Claude Code via curl | bash"
    else
      log "(dry-run) would run: claude update"
    fi
    return
  fi

  if ! command -v claude >/dev/null 2>&1; then
    log "Claude Code not found. Installing via native installer..."
    curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed (non-fatal)"
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
  log "BOOTSTRAPPING new machine  [platform=$PLATFORM]"
  sep

  ensure_dir "$DOTLOC/zsh"
  ensure_dir "$DOTLOC/p10k"
  ensure_dir "$DOTLOC/nvim"
  ensure_dir "$DOTLOC/ghostty"
  ensure_dir "$DOTLOC/navi/cheats"
  ensure_dir "$DOTLOC/scripts"
  ensure_dir "$DOTLOC/.zsh"

  ensure_dir "$XDG_CONFIG_HOME"
  ensure_dir "$XDG_DATA_HOME/navi"
  ensure_dir "$(ghostty_config_dir)"

  linkall
  mise_setup
  brew_setup
  claude_setup
  navi_update

  sep
  log "Bootstrap complete — run: exec zsh -l"
}

###############################################################################
# UPDATE — pull latest + re-link repo → system
###############################################################################
update() {
  sep
  log "Updating dotfiles (repo → system)"
  sep

  if [[ "$DRY_RUN" == "1" ]]; then
    if git -C "$DOTLOC" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      log "(dry-run) would run: git pull --ff-only"
    fi
    linkall
    return
  fi

  if git -C "$DOTLOC" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Pulling latest changes..."
    git -C "$DOTLOC" pull --ff-only || warn "git pull failed; continuing with local state"
  fi

  linkall
  sep
  log "Update completed"
}

###############################################################################
# SYNC — update links + mise + brew (all-in-one refresh)
###############################################################################
sync() {
  sep
  log "Syncing dotfiles (full refresh)  [platform=$PLATFORM]"
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

  if [[ "$DRY_RUN" == "1" ]]; then
    log "(dry-run) would clone/pull community and tldr cheatsheets"
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    warn "git not found; skipping navi cheat update"
    return
  fi

  local cheats_dir="$DOTLOC/navi/cheats"

  _clone_or_pull() {
    local name="$1" url="$2"
    if [[ -d "$cheats_dir/$name/.git" ]]; then
      log "Pulling $name cheats..."
      git -C "$cheats_dir/$name" pull --ff-only || warn "Failed to pull $name cheats"
    else
      log "Cloning $name cheats..."
      rm -rf "${cheats_dir:?}/$name"
      git clone --depth 1 "$url" "$cheats_dir/$name"
    fi
  }

  _clone_or_pull community "https://github.com/denisidoro/cheats.git"
  _clone_or_pull tldr      "https://github.com/denisidoro/navi-tldr-pages.git"

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
  if [[ "$DRY_RUN" == "1" ]]; then
    log "(dry-run) would run: fonts.sh $*"
    return
  fi
  bash "$DOTLOC/scripts/fonts.sh" "$@"
}

###############################################################################
# HELP
###############################################################################
usage() {
  cat <<EOF
Usage: dot <command> [options]

Commands:
  sync              Full refresh: re-link + mise + brew + claude + navi
  update            Pull latest changes + re-link repo → system
  mise              Install mise (if needed) and run mise install
  brew              Install Homebrew (if needed) and run Brewfile
  brew install      Add package(s) to Brewfile and install them
                      dot brew install <pkg> [pkg...]
                      dot brew install --cask <pkg>
  claude            Install/update Claude Code via native installer
  navi              Clone/pull community navi cheatsheets
  bootstrap         Install dotfiles on a fresh machine
  migrate           Copy system configs → repo, then symlink everything
  linkall           Apply symlinks only (repo → system)
  fonts [...]       Pass through to scripts/fonts.sh
  help              Show this message

Options:
  --dry-run         Preview all changes; no installs, copies, or symlinks

Platform:  $PLATFORM
Dotfiles:  $DOTLOC
EOF
}

###############################################################################
# DISPATCHER
###############################################################################
args=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *)         args+=("$arg") ;;
  esac
done

cmd="${args[0]:-help}"

case "$cmd" in
sync)      sync ;;
bootstrap) bootstrap ;;
migrate)   migrate ;;
update)    update ;;
linkall)   linkall ;;
mise)      mise_setup ;;
brew)
  case "${args[1]:-}" in
    install) brew_install "${args[@]:2}" ;;
    *)       brew_setup ;;
  esac
  ;;
claude)    claude_setup ;;
navi)      navi_update ;;
fonts)     fonts "${args[@]:1}" ;;
help|--help|-h) usage ;;
*)         err "Unknown command: $cmd" ;;
esac
