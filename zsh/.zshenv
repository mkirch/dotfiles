#------------------------------------------------------------------------------
# ~/.zshenv — minimal, fast, loaded by ALL zsh invocations
#------------------------------------------------------------------------------
limit coredumpsize 0

: "${DOTLOC:=$HOME/Developer/dotfiles}"
export DOTLOC

: "${DEV_HOME:=$HOME/Developer}"
export DEV_HOME

# Source machine-specific config (gitignored)
[[ -f "$DOTLOC/.env" ]] && source "$DOTLOC/.env"

# Telemetry opt-outs
export FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT=1
export HOMEBREW_NO_ANALYTICS=1
export NEXT_TELEMETRY_DISABLED=1
export AZURE_DEV_COLLECT_TELEMETRY=no

# Build flags (Apple Silicon)
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export ARCHFLAGS="-arch arm64"

typeset -gaU path
path=(
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
# zsh keeps PATH in sync with $path automatically; this just marks it exported
export PATH
export MANPATH="/opt/homebrew/share/man:/usr/local/man:/usr/share/man"
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
