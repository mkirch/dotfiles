#!/usr/bin/env bash
# Minimal bash config (zsh is primary)

[[ $- != *i* ]] && return

export PATH="$HOME/.local/bin:$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

command -v mise &>/dev/null && eval "$(mise activate bash)"
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
[[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
