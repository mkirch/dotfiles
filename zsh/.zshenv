#------------------------------------------------------------------------------
# ~/.zshenv — minimal, fast, for ALL zsh invocations
#------------------------------------------------------------------------------

# Auto-detect DOTLOC FIRST (before sourcing env file) so variables can use it.
# Walk up from current directory looking for .env.example (marker file for this repo).
if [[ -z "${DOTLOC:-}" ]]; then
  _dotfiles_search_dir="${PWD:-$HOME}"
  while [[ "${_dotfiles_search_dir}" != "/" ]]; do
    if [[ -f "${_dotfiles_search_dir}/.env.example" ]] && [[ -f "${_dotfiles_search_dir}/scripts/update.sh" ]]; then
      DOTLOC="${_dotfiles_search_dir}"
      break
    fi
    _dotfiles_search_dir="$(dirname "${_dotfiles_search_dir}")"
  done
  unset _dotfiles_search_dir
fi

: "${DOTLOC:=$HOME/.dotfiles}"
export DOTLOC

# Load optional environment overrides (can override DOTLOC if needed).
DOTFILES_ENV_FILE="${DOTFILES_ENV_FILE:-$HOME/.dotfiles.env}"
if [[ -f "${DOTFILES_ENV_FILE}" ]]; then
  set -a
  source "${DOTFILES_ENV_FILE}"
  set +a
fi

# Re-export DOTLOC in case it was overridden by env file
export DOTLOC

: "${DEV_HOME:=$HOME/Developer}"
export DEV_HOME

# 1. Disable core dumps everywhere
limit coredumpsize 0

# 2. Telemetry opt‑outs
export FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT=1
export HOMEBREW_NO_ANALYTICS=1
export NEXT_TELEMETRY_DISABLED=1

# 3. Core environment
export TESSDATA_PREFIX="${TESSDATA_PREFIX:-$DEV_HOME/docprocessing/tessdata_best/}"
export LLDB_EXEC="/opt/homebrew/opt/llvm/bin/lldb-vscode"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export ARCHFLAGS="-arch arm64"

# 4. PATH — use unique array, keep inherited pieces if any
typeset -gaU path

path=(
  "$DEV_HOME/dl/scripts/bin"
  "$HOME/bin"
  "$HOME/.local/bin"
  "/opt/homebrew/opt/coreutils/libexec/gnubin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/local/bin"
  "/Library/Apple/usr/bin"
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
  $path
)

# 5. MANPATH
export MANPATH="/usr/local/man:${MANPATH:-/usr/share/man}"

# 6. Cargo environment (cheap check)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
