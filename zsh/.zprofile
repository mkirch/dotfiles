#------------------------------------------------------------------------------
# ~/.zprofile — login shell initialization
#------------------------------------------------------------------------------

# Private env already loaded by .zshenv from $DOTLOC/.env

# Toolchains that should NOT apply to non-interactive shells
# This avoids slowing uv, systemd-user units, scripts, etc.

# Cargo
[[ -f "$HOME/.cargo/env" ]]
# pnpm/node special installs
# export PNPM_HOME="$HOME/Library/pnpm"
# [[ -d "$PNPM_HOME" ]] && path=("$PNPM_HOME" $path)
# [[ -d "$HOME/Library/pnpm/nodejs/22.13.1/bin" ]] && path=("$HOME/Library/pnpm/nodejs/22.13.1/bin" $path)

