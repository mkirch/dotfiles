#==============================================================================
# ZSHRC FOR MACOS, USING OH-MY-ZSH
#==============================================================================

#==============================================================================
# GENERAL PATH CONFIGURATIONS
#==============================================================================
# Use a function to append to PATH
prepend_to_path() {
    for p in "$@"; do
        [[ ":$PATH:" != *":$p:"* ]] && PATH="$p:$PATH"
    done
}

prepend_to_path \
    "/usr/bin" \
    "/bin" \
    "/usr/local/bin" \
    "/usr/sbin" \
    "/sbin" \
    "$HOME/.local/bin" \
    "$HOME/.mint/bin" \
    "/opt/homebrew/bin" \
    "/opt/homebrew/sbin" \
    "/opt/homebrew/bin/ffmpeg" \
    "/opt/homebrew/opt/coreutils/libexec/gnubin" \
    "/Library/Apple/usr/bin" \
    "$HOME/Library/Application Support/fnm"
# Export necessary variables
export FPATH="/opt/homebrew/share/zsh/site-functions:${FPATH}"
export NVM_DIR="$HOME/.nvm"
export PYENV_ROOT="$HOME/.pyenv"
export ZSH="$HOME/.oh-my-zsh"
export DOTLOC="$HOME/dotfiles"
export TESSDATA_PREFIX="$HOME/Developer/docprocessing/tessdata_best/"
export LLDB_EXEC="/opt/homebrew/opt/llvm/bin/lldb-vscode"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export MANPATH="/usr/local/man:$MANPATH"
export ARCHFLAGS="-arch arm64"
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
[[ -d $PYENV_ROOT/bin ]] && PATH="$PYENV_ROOT/bin:$PATH"

#==============================================================================
# Completions
#==============================================================================
fpath=($HOME/.zsh/completions $fpath)
autoload -Uz compinit
compinit

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 
[ -s "$NVM_DIR/zsh_completion" ] && \. "$NVM_DIR/zsh_completion" 
if type pyenv > /dev/null; then
  eval "$(pyenv init --path)"
fi
if type pyenv-virtualenv-init > /dev/null; then
  eval "$(pyenv virtualenv-init -)"
fi
if type cilium > /dev/null; then
  eval "$(cilium completion zsh)"
fi
if type kubectl > /dev/null; then
  eval "$(kubectl completion zsh)"
fi

#==============================================================================
# FZF
#==============================================================================
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#==============================================================================
# Evals
#==============================================================================
eval "$(wezterm shell-completion --shell zsh)"
eval "$(brew shellenv)"
eval "$(zoxide init zsh)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
#==============================================================================
# OH-MY-ZSH: OMZ
#==============================================================================
ZSH_THEME="random"
ZSH_THEME_RANDOM_QUIET=true
VSCODE=code-insiders

plugins=(
  1password alias-finder aliases azure brew cp docker docker-compose dotenv
  emoji emoji-clock extract eza fd fig fzf gcloud gh git git-lfs github
  gitignore helm history httpie kubectl kubectx macos man npm nvm pip
  pre-commit python rust stripe sudo swiftpm thefuck urltools vscode wd
  web-search xcode zsh-interactive-cd zoxide
)
source $ZSH/oh-my-zsh.sh
source "$HOME/.config/op/plugins.sh"

#==============================================================================
# Aliases
#==============================================================================
alias fd="fd-find"
alias zshconfig="nvim ~/.zshrc"
alias ohmyzsh="nvim ~/.oh-my-zsh"
alias nvplug="nvim ~/.config/nvim/lua/plugins/"
alias nvlua="nvim ~/.config/nvim/init.lua"
alias nz="nvim ~/.zshrc"
alias nvomz="nvim ~/.oh-my-zsh/"
alias nw="nvim ~/.config/wezterm/wezterm.lua"
alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
alias find='fd'
alias rgz='rg -zi'
alias du='dust'
alias tm='hyperfine'
alias cloc='tokei'
alias ps='procs'
alias top='btm -g -a -c -n -r 250 --enable_gpu_memory --mem_as_value \
  --color gruvbox --enable_cache_memory --network_use_bytes --network_use_log \
  --hide_table_gap --process_command --default_time_value 30000 \
  --show_table_scroll_position'
alias htop='btm --enable_gpu_memory -g -a --mem_as_value --color gruvbox \
  -r 250 --network_use_bytes --network_use_log --enable_cache_memory \
  --hide_table_gap --default_time_value 30000 --process_command \
  -c --show_table_scroll_position -n --basic'
alias l='eza -lH --hyperlink --no-quotes -w=80 --no-user --no-permissions \
  --no-time --no-git --icons --group-directories-first --git-ignore'
alias ll='eza -laHh --icons --git-ignore --time-style=relative --git --git-repos --group-directories-first'
alias lt='eza -Tah --icons --git-ignore --group-directories-first'
alias llt='eza -laT --icons --git-ignore --group-directories-first'
alias batp='bat --style plain'
alias om='openai api models.list'
alias oai='curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '
alias oaicli='openai api chat.completions.create -m gpt-4-vision-preview \
  -n 1 -M 512 -P 1.00 -t 0.7 --stop "" --stream -g user '
alias ytdl='yt-dlp'
alias ytdlm='yt-dlp --extract-audio --audio-format mp3'
alias weather='curl -s v2.wttr.in/Chicago'
alias rip='wget --recursive --level=inf --timestamping --no-clobber \
  --convert-links --page-requisites --adjust-extension --span-hosts \
  --wait=1 --random-wait --limit-rate=100k --no-parent --reject="index.html*"'
alias aria3d="aria2c -x 16 -s 16 -k 1M -j 16 --file-allocation=none \
              --retry-wait=5 --max-tries=0 --continue=true \
              --optimize-concurrent-downloads=true --summary-interval=0 \
              --max-connection-per-server=16 --min-split-size=1M --split=16 \
              --max-overall-download-limit=0 --max-download-limit=0 \
              --http-accept-gzip=true --stream-piece-selector=inorder \
              --uri-selector=adaptive --check-certificate=false "
alias nz="nvim $DOTLOC/.zshrc"
alias dupdate="$DOTLOC/update.sh"
alias domz="dupdate && omz reload"
alias dup="dupdate && omz reload"
alias zup="dupdate && omz reload"

alias wid="fd -e jpg -x wezterm imgcat --height=25%"
alias wi="wezterm imgcat"
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
alias brewinstaller="brew install aria2 bat brotli ca-certificates cmake \
  coreutils dlib dotnet exiftool eza ffmpeg flac fnm fontconfig freetype \
  gallery-dl gcc gettext gh git git-lfs go jq lame libmagic llvm \
  luajit mint msgpack mupdf ncurses neovim openblas openjdk \
  openjpeg openssl pandoc poppler pre-commit protobuf pyenv ranger \
  ripgrep ripgrep-all swiftformat swiftlint tesseract tesseract-lang \
  thefuck tree tree-sitter trunk virtualenv webp wget yt-dlp zlib zoxide zstd"
alias brewcaskinstaller="brew install --cask google-cloud-sdk wezterm"
alias pipup="python -m venv .venv && source .venv/bin/activate && python -m \
  pip install -U pip && python -m pip install -U -r requirements.txt"
alias wg='wget --recursive --level=1 --span-hosts --tries=1 --no-directories \
  --no-parent --execute robots=off --directory-prefix=files \
 --accept=.pdf,.html,.rtf,.txt,.ppt,.pptx.,xls,.xlsx,.xml,.json,.doc,.docx \
 --user-agent="Mozilla/5.0 (Windows NT 6.1; rv:5.0 Gecko/20100101 Firefox/5.0"\
  --adjust-extension --no-clobber --wait=1 --random-wait --limit-rate=200k \
  --show-progress'
alias ai="interpreter --local --auto_run --system"
alias runai="source $HOME/Developer/Interpreter.venv/bin/activate && \
  python -m pip install -U pip && python -m pip install -U -r requirements.txt && ohmyzsh/ohmyzsh/master/tools/install.sh)\""
alias code="code-insiders"
alias k="kubectl"
alias akcred="az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME"
alias akgup="az aks get-upgrades --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME"
alias akupgrade="az aks upgrade --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --kubernetes-version $AKS_KUBERNETES_VERSION"
alias aknls="az aks nodepool list --resource-group $AKS_RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME"
alias aknshow="az aks nodepool show --resource-group $AKS_RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME"
alias akdash="az aks browse --resource-group $AKS_RESOURCE_GROUP -n $AKS_CLUSTER_NAME"
alias akstart="az aks start --resource-group $AKS_RESOURCE_GROUP -n $AKS_CLUSTER_NAME"
alias akstop="az aks stop -g $AKS_RESOURCE_GROUP -n $AKS_CLUSTER_NAME"
alias akls="az aks list -g $AKS_RESOURCE_GROUP"
alias akshow="az aks show -g $AKS_RESOURCE_GROUP -n $AKS_CLUSTER_NAME"
alias akgv="az aks get-versions"
alias ak="az aks"

#==============================================================================
# DOTENV
#==============================================================================
[ -f "$DOTLOC/.env" ] && source "$DOTLOC/.env"

#==============================================================================
# Custom Functions
#==============================================================================

# Concatenate matched files up to 25MB each
mkat() {
    fd -e md . . | xargs -I {} cat {} | head -c 25M | bat --style plain
}

# FZF with RG-ALL
rga-fzf() {
    RG_PREFIX="rga --files-with-matches"
    local file
    file="$(
        FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
            fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
                --phony -q "$1" \
                --bind "change:reload:$RG_PREFIX {q}" \
                --preview-window="70%:wrap"
    )" &&
    echo "opening $file" &&
    xdg-open "$file"
}

whisper() {
    $DOTLOC/scripts/whisper_transcription.sh "$@"
}

#==============================================================================
# Binds and Such
#==============================================================================

bindkey "\e[1;3D" backward-word # ⌥←
bindkey "\e[1;3C" forward-word  # ⌥→
bindkey "\e[1;9D" beginning-of-line # ⌥←
bindkey "\e[1;9C" end-of-line   # ⌥→
bindkey "\e[1;D" backward-word  # ⇧←
bindkey "\e[1;C" forward-word   # ⇧→
