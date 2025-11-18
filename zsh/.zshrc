#==============================================================================
# ~/.zshrc — Znap + Powerlevel10k, optimized
#==============================================================================

#------------------------------------------------------------------------------
# 0. Powerlevel10k instant prompt (keep at top)
#------------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#------------------------------------------------------------------------------
# 0a. Load environment variables from ~/.dotfiles.env
#------------------------------------------------------------------------------
DOTFILES_ENV_FILE="${DOTFILES_ENV_FILE:-$HOME/.dotfiles.env}"
if [[ -f "${DOTFILES_ENV_FILE}" ]]; then
  set -a
  source "${DOTFILES_ENV_FILE}"
  set +a
fi

# Set defaults for Cursor-related variables (used by aliases below)
CURSOR_APP_NAME="${CURSOR_APP_NAME:-Cursor}"
CURSOR_USER_DATA_DIR="${CURSOR_USER_DATA_DIR:-$HOME/.local/share/cursor/profile}"
CURSOR_EXTENSIONS_DIR="${CURSOR_EXTENSIONS_DIR:-${CURSOR_USER_DATA_DIR}/Extensions}"

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
# If you want global shared history, re-add:
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
# Suppress compinit verbose output for instant prompt compatibility (removed -w flag)
zstyle '*:compinit' arguments -D -i -u -C

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

# Ensure compinit is called (znap may have already called it, but ensure it's done)
# This ensures all completion functions are loaded
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit -D -i -u -C
else
  compinit -D -i -u
fi

# QoL plugins
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting

# zoxide
(( $+commands[zoxide] )) && znap eval zoxide 'zoxide init zsh'

# fzf — use Homebrew scripts, no binary calls
if [[ -r "/opt/homebrew/opt/fzf/shell/completion.zsh" ]]; then
  source "/opt/homebrew/opt/fzf/shell/completion.zsh"
fi
if [[ -r "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" ]]; then
  source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
fi

# 1Password CLI
if (( $+commands[op] )); then
  znap eval op 'op completion zsh'
  compdef _op op
  [[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"
fi

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

#------------------------------------------------------------------------------
# 6. Extra PATH / language toolchain (interactive-only)
#------------------------------------------------------------------------------
export PNPM_HOME="$HOME/Library/pnpm"
[[ -d "$PNPM_HOME" ]] && path=("$PNPM_HOME" $path)
[[ -d "$HOME/Library/pnpm/nodejs/22.13.1/bin" ]] && path=("$HOME/Library/pnpm/nodejs/22.13.1/bin" $path)

[[ -f "$HOME/completion-for-pnpm.zsh" ]] && source "$HOME/completion-for-pnpm.zsh"

#------------------------------------------------------------------------------
# 7. Aliases
#------------------------------------------------------------------------------
alias bfg='java -jar "$DOTLOC/bfg.jar"'
alias find='fd'
alias rgz='rg -zi'
alias du='dust'
alias tm='hyperfine'
alias cloc='tokei'
alias ps='procs'

alias top='btm -g -a -c -n -r 250 --enable_gpu_memory --mem_as_value \
  --color gruvbox --enable_cache_memory --network_use_bytes --network_use_log \
  --hide_table_gap --process_command --default_time_value=30000 \
  --show_table_scroll_position'

alias htop='btm --enable_gpu_memory -g -a --mem_as_value --color gruvbox \
  -r 250 --network_use_bytes --network_use_log --enable_cache_memory \
  --hide_table_gap --default_time_value=30000 --process_command \
  -c --show_table_scroll_position -n --basic'

alias l='eza -lah --hyperlink --no-quotes -w=80 --no-user --no-permissions \
  --no-time --icons --group-directories-first --git-ignore'

alias ll='eza -lah --icons=always --time-style=relative --no-user --git --git-repos --group-directories-first -O'

alias lt='eza -Tah --icons --git-ignore --group-directories-first'
alias llt='eza -laT --icons --git-ignore --group-directories-first'

alias batp='bat --style plain'



alias ytdlm='yt-dlp --extract-audio --audio-format mp3'
alias weather='curl -s v2.wttr.in/Chicago'

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

alias pipup='python -m venv .venv && source .venv/bin/activate && \
  python -m pip install -U pip && \
  python -m pip install -U -r requirements.txt'

alias uvup="source .venv/bin/activate && uv sync"

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
  --user-data-dir=\"${CURSOR_USER_DATA_DIR}\" \
  --extensions-dir=\"${CURSOR_EXTENSIONS_DIR}\""

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
claude() {
  if [[ -z "${CLAUDE_BINARY:-}" ]]; then
    echo "Error: CLAUDE_BINARY is not set." >&2
    echo "Set it in ~/.dotfiles.env (see .env.example) or export it in your shell." >&2
    return 1
  fi
  "${CLAUDE_BINARY}" "$@"
}

ytdl() {
  yt-dlp "$1" \
    --downloader aria2c \
    --downloader-args "-x 16 -s 16 -k 1M" \
    --embed-thumbnail \
    --embed-subs \
    --embed-chapters \
    --embed-metadata
}


#------------------------------------------------------------------------------
# 9. Editor
#------------------------------------------------------------------------------
# Set EDITOR to actual executable path (not alias) so it works in subshells
# Programs like git commit, sudo -e run editors in subshells where aliases aren't available
export EDITOR="/Applications/${CURSOR_APP_NAME}.app/Contents/MacOS/Cursor"
export VISUAL="$EDITOR"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
