#==============================================================================
# ~/.zshrc — Znap + Powerlevel10k, optimized
#==============================================================================

#------------------------------------------------------------------------------
# 0. Powerlevel10k instant prompt (keep at top)
#------------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[[ $- != *i* ]] && return

#------------------------------------------------------------------------------
# 1. Shell options / history
#------------------------------------------------------------------------------
setopt prompt_subst
setopt auto_cd
setopt interactive_comments

HISTFILE="$HOME/.zsh_history"
HISTSIZE=500000
SAVEHIST=500000
setopt hist_ignore_space hist_reduce_blanks inc_append_history extended_history
setopt hist_ignore_all_dups hist_find_no_dups hist_verify 
#If you want global shared history, re-add:
# setopt share_history

typeset -U fpath

#------------------------------------------------------------------------------
# 2. Completion search paths
#------------------------------------------------------------------------------
# Add Homebrew completions early (before znap/compinit)
if type brew &>/dev/null; then
  fpath=(
    "$(brew --prefix)/share/zsh/site-functions"
    $fpath
  )
fi

fpath=(
  "$HOME/.stripe"
  "$HOME/.zsh/completions"
  "$HOME/.zfunc"
  "$HOME/.docker/completions"
  $fpath
)

#------------------------------------------------------------------------------
# 3. Znap plugin manager bootstrap
#------------------------------------------------------------------------------
if [[ ! -r "$HOME/.zsh/plugins/znap/znap.zsh" ]]; then
  mkdir -p "$HOME/.zsh/plugins"
  git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git \
    "$HOME/.zsh/plugins/znap"
fi

source "$HOME/.zsh/plugins/znap/znap.zsh"

zstyle ':znap:*' repos-dir "$HOME/.zsh/plugins"

#------------------------------------------------------------------------------
# 4. Prompt theme (Powerlevel10k via Znap)
#------------------------------------------------------------------------------
znap prompt romkatv/powerlevel10k
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

#------------------------------------------------------------------------------
# 5. Plugins, completions, and tool initialization
#------------------------------------------------------------------------------
# Extra completions
znap source zsh-users/zsh-completions

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Ensure compinit is called
autoload -Uz compinit
compinit -D -i -u

# QoL plugins
znap source zsh-users/zsh-autosuggestions

# zoxide
(( $+commands[zoxide] )) && znap eval zoxide 'zoxide init zsh'

# mise
(( $+commands[mise] )) && znap eval mise 'mise activate zsh'
(( $+commands[mise] )) && znap fpath _mise 'mise completion zsh'

# fzf — use Homebrew scripts, no binary calls
if [[ -r "/opt/homebrew/opt/fzf/shell/completion.zsh" ]]; then
  source "/opt/homebrew/opt/fzf/shell/completion.zsh"
fi
if [[ -r "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" ]]; then
  source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
fi

# navi — interactive cheatsheet (Cmd+/ in Ghostty, or type ?)
if (( $+commands[navi] )); then
  eval "$(navi widget zsh)"
  alias '?'=navi
  alias how=navi
  alias '??'='navi --tldr'      # search tldr-pages
  alias 'how?'='navi --cheatsh' # search cheat.sh
fi

# Nudge towards navi on failed commands
command_not_found_handler() {
  echo "zsh: command not found: $1"
  echo "💡 Stuck? Cmd+/ or type ?"
  return 127
}

# Up/Down arrows: prefix-based history search (type partial command, then arrow)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# 1Password CLI
if (( $+commands[op] )); then
  znap eval op 'op completion zsh'
  compdef _op op
  [[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"
fi

# Twilio CLI
(( $+commands[twilio] )) && znap eval twilio 'twilio autocomplete:script zsh'

# uv / uvx completions (cached)
(( $+commands[uv]  )) && znap fpath _uv  'uv generate-shell-completion zsh'
(( $+commands[uvx] )) && znap fpath _uvx 'uvx --generate-shell-completion zsh'

# Codex completions (if available)
if (( $+commands[codex] )); then
  if codex completion zsh &>/dev/null; then
    znap fpath _codex 'codex completion zsh'
  fi
fi

# Extra custom completions
[[ -f "$HOME/.config/gk/gk_zsh_completions.zsh" ]] && source "$HOME/.config/gk/gk_zsh_completions.zsh"

# AWS CLI autocompletion
if (( $+commands[aws_completer] )); then
  autoload -Uz +X bashcompinit && bashcompinit
  complete -C aws_completer aws
fi

znap source zsh-users/zsh-syntax-highlighting
#------------------------------------------------------------------------------
# 6. Extra PATH / language toolchain (interactive-only)
#------------------------------------------------------------------------------
#export PNPM_HOME="$HOME/Library/pnpm"
#[[ -d "$PNPM_HOME" ]] && path=("$PNPM_HOME" $path)
#[[ -d "$HOME/Library/pnpm/nodejs/22.13.1/bin" ]] && path=("$HOME/Library/pnpm/nodejs/22.13.1/bin" $path)

#[[ -f "$HOME/completion-for-pnpm.zsh" ]] && source "$HOME/completion-for-pnpm.zsh"

#------------------------------------------------------------------------------
# 7. Aliases
#------------------------------------------------------------------------------
alias bfg='java -jar "$DOTLOC/bfg.jar"'
alias python=python3    # for your fingers, but this will now be uv's python3
alias find='fd'
alias rgz='rg -zi'
alias du='dust'
alias tm='hyperfine'
alias cloc='tokei'
alias ps='procs'
alias cl='claude'
alias cld='claude --debug'

alias top='btm -g -a -c -n -r 250 --enable_gpu_memory --mem_as_value \
  --color gruvbox --enable_cache_memory --network_use_bytes --network_use_log \
  --hide_table_gap --process_command --default_time_value=30000 \
  --show_table_scroll_position'

alias htop='btm --enable_gpu_memory -g -a --mem_as_value --color gruvbox \
  -r 250 --network_use_bytes --network_use_log --enable_cache_memory \
  --hide_table_gap --default_time_value=30000 --process_command \
  -c --show_table_scroll_position -n --basic'

alias l='eza -lah --hyperlink --no-quotes -w=80 --no-user --no-permissions \
  --no-time --icons --group-directories-first --git-ignore -I .DS_Store'

alias ll='eza -lah --icons=always --time-style=relative --no-user --git --git-repos --group-directories-first -I .DS_Store -O'
alias lt='eza -Tah --icons --git-ignore --group-directories-first -I .DS_Store'
alias llt='eza -laT --icons --git-ignore --group-directories-first -I .DS_Store'
alias batp='bat --style plain'


alias ytdlm='ytdl -a'                                  # audio-only mode
alias ytdlbg='ytdl "$(pbpaste)" &>/dev/null & disown'  # background download from clipboard
alias weather='curl -s v2.wttr.in'

alias rip='wget --recursive --level=inf --timestamping --no-clobber \
  --convert-links --page-requisites --adjust-extension --span-hosts \
  --wait=1 --random-wait --limit-rate=100k --no-parent --reject="index.html*"'

alias aria3d='aria2c -x 16 -s 16 -k 1M -j 16 --file-allocation=none \
  --retry-wait=5 --max-tries=0 --continue=true \
  --optimize-concurrent-downloads=true --summary-interval=0 \
  --max-connection-per-server=16 --min-split-size=1M --split=16 \
  --max-overall-download-limit=0 --max-download-limit=0 \
  --http-accept-gzip=true --stream-piece-selector=inorder \
  --uri-selector=adaptive --check-certificate=false'
alias nz='nvim "$DOTLOC/zsh/.zshrc"'
alias rz='exec zsh -l'
alias ndot='nvim "$DOTLOC/zsh/.zshenv"'
alias dup='$DOTLOC/scripts/update.sh && exec zsh -l'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; say cache flush completed successfully'
alias brewinstaller='brew install aria2 bat brotli ca-certificates cmake \
  coreutils dlib exiftool eza ffmpeg flac fontconfig freetype \
  gallery-dl gcc gettext gh git git-lfs go jq lame libmagic llvm \
  luajit mint msgpack mupdf ncurses neovim openblas openjdk \
  openjpeg openssl pandoc poppler pre-commit protobuf ranger \
  ripgrep ripgrep-all swiftformat swiftlint tesseract tesseract-lang \
  tree tree-sitter webp wget yt-dlp zlib zoxide zstd'
alias brewcaskinstaller='brew install --cask codex google-cloud-sdk mysqlworkbench stolendata-mpv'
alias wg_docs='wget --recursive --level=1 --span-hosts --tries=1 --no-directories \
  --no-parent --execute robots=off --directory-prefix=files \
  --accept=".pdf,.html,.rtf,.txt,.ppt,.pptx,.xls,.xlsx,.xml,.json,.doc,.docx" \
  --user-agent="Mozilla/5.0 (Windows NT 6.1; rv:5.0) Gecko/20100101 Firefox/5.0" \
  --adjust-extension --no-clobber --wait=1 --random-wait --limit-rate=1m \
  --show-progress'
alias wg='wget -r -l inf --https-only --execute robots=off -N -p \
  --user-agent="Mozilla/5.0 (Windows NT 6.1; rv:5.0) Gecko/20100101 Firefox/5.0" \
  --no-remove-listing --limit-rate=1m -t 2 -k -np -w 0.1 -E -nc \
  -a wget_running.txt -o wget.txt'
alias spoder='wg --spider'
alias ai='interpreter --local --auto_run --system'
alias runai='source "$DEV_HOME/Interpreter.venv/bin/activate" && \
  python -m pip install -U pip && \
  python -m pip install -U -r requirements.txt'
alias code='cursor'
alias curse="/Applications/${CURSOR_APP_NAME}.app/Contents/MacOS/Cursor \
  --user-data-dir=${CURSOR_USER_DATA_DIR:q} \
  --extensions-dir=${CURSOR_EXTENSIONS_DIR:q}"
alias ruff="uv tool run ruff"
alias mypy="uv tool run mypy"
alias pytest="uv tool run pytest"
alias ncodex="nvim ~/.codex/config.toml"
#------------------------------------------------------------------------------
# 7a. Private aliases (gitignored, not committed)
#------------------------------------------------------------------------------
if [[ -f "${DOTLOC}/zsh/.zsh_aliases" ]]; then
  source "${DOTLOC}/zsh/.zsh_aliases"
elif [[ -f "${DOTLOC}/.zsh_aliases" ]]; then
  source "${DOTLOC}/.zsh_aliases"
elif [[ -f "${HOME}/.zsh_aliases" ]]; then
  source "${HOME}/.zsh_aliases"
fi

#------------------------------------------------------------------------------
# 8. Functions
#------------------------------------------------------------------------------

# ---- yazi file manager with cd-on-exit ----
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ---- Python / uv strategy ----
# uv is the primary interface. Projects: uv add / uv sync / uv run.
# Global tools: uv tool. No direct pip usage.

# Nice helper for running python in project env
py() {
  uv run python "$@"
}

# Fast project scaffold
pyinit() {
  # uv-native init with sensible defaults
  uv init "$@"
  echo "uv project initialized. Use 'uv add' to manage deps."
}

# Guardrail against old habits
pip() {
  echo "Blocked: use 'uv add' / 'uv sync' or 'uv pip' explicitly if you REALLY must." >&2
  return 1
}
pip3() { pip "$@"; }

# wh command is provided by ~/bin/wh (scripts/wh.sh)
# Whisper transcription with pyannote diarization. Run 'wh' for usage.


# ytdl command is provided by ~/bin/ytdl (scripts/ytdl.sh)
# Run 'ytdl --help' for usage. Env vars: YTDL_DIR, YTDL_COOKIES_FILE, YTDL_COOKIES_FROM_BROWSER


#------------------------------------------------------------------------------
# 9. Editor
#------------------------------------------------------------------------------
# Set EDITOR to actual executable path (not alias) so it works in subshells
# Programs like git commit, sudo -e run editors in subshells where aliases aren't available
export EDITOR="/Applications/${CURSOR_APP_NAME}.app/Contents/MacOS/Cursor"
export VISUAL="$EDITOR"


