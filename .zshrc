#==============================================================================
# ZSHRC FOR MACOS, USING OH-MY-ZSH
#==============================================================================#==============================================================================
# GENERAL PATH CONFIGURATIONS
#==============================================================================
export PATH="/usr/bin:/bin:/usr/local/bin:/usr/sbin:/sbin:$PATH"
export PATH="/Users/$USER/.local/bin:$PATH"
export PATH="/Library/Apple/usr/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="/Users/$USER/.mint/bin:$PATH"
export PATH="/opt/homebrew/bin/ffmpeg:$PATH"
export LLDB_EXEC="/opt/homebrew/opt/llvm/bin/lldb-vscode"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export PYENV_ROOT="$HOME/.pyenv"
export TESSDATA_PREFIX="/Users/$USER/Developer/docprocessing/tessdata_best/"
export ZSH="$HOME/.oh-my-zsh"
export MANPATH="/usr/local/man:$MANPATH"
export ARCHFLAGS="-arch arm64"
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
export PATH="/Users/$USER/Library/Application Support/fnm:$PATH"

#==============================================================================
# GOOGLE CLOUD SDK
#==============================================================================
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
#==============================================================================
# PYTHON
#==============================================================================
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#==============================================================================
# FZF
#==============================================================================
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
#==============================================================================
# Evals
#==============================================================================
eval "$(pyenv init -)"
eval "`fnm env`"
eval "$(thefuck --alias)"
eval "$(brew shellenv)"
eval "$(zoxide init zsh)"
eval "$( wezterm shell-completion --shell zsh)"
#==============================================================================
# OH-MY-ZSH: OMZ
#==============================================================================
ZSH_THEME="random" # set by `omz`

plugins=(git git-lfs brew xcode man gcloud dotenv azure aws cp macos 
    gh github history npm fnm oc swiftpm rust 1password brew fd 
    fzf thefuck pyenv python macos emoji emoji-clock aliases alias-finder
    wd pip python sudo fig pre-commit vscode web-search gitignore docker
    docker-compose urltools httpie zoxide
    )
source $ZSH/oh-my-zsh.sh
source /Users/$USER/.config/op/plugins.sh
#==============================================================================
# Aliases
#==============================================================================
alias zshconfig="nvim ~/.zshrc"
alias ohmyzsh="nvim ~/.oh-my-zsh"
alias nvplug="nvim ~/.config/nvim/lua/plugins/"
alias nvlua="nvim ~/.config/nvim/init.lua"
alias nz="nvim ~/.zshrc"
alias nvomz="nvim ~/.oh-my-zsh/"
alias nw="nvim ~/.config/wezterm/wezterm.lua"
alias find='fd'
alias rgz='rg -zi'
alias du='dust'
alias tm='hyperfine'
alias cloc='tokei'
alias ps='procs'
alias top='btm -g -a -c -n -r 250 --enable_gpu_memory --mem_as_value \
  --color gruvbox --enable_cache_memory --network_use_bytes \ 
  --network_use_log  --hide_table_gap --process_command \
  --default_time_value 30000  --show_table_scroll_position'
alias htop='btm --enable_gpu_memory -g -a --mem_as_value --color gruvbox \
  -r 250 --network_use_bytes --network_use_log --enable_cache_memory \
  --hide_table_gap --default_time_value 30000 --process_command \
  -c --show_table_scroll_position -n --basic'
alias l='eza -G --icons --group-directories-first'
alias lg='eza -l --icons --git-ignore --group-directories-first --git'
alias ll='eza -l --all --all --group-directories-first --git'
alias lt='eza -T --git-ignore --level=2 --group-directories-first'
alias llt='eza -lT --git-ignore --level=2 --group-directories-first'
alias lT='eza -T --git-ignore --level=4 --group-directories-first'
alias batp='bat --style plain'
alias om='openai api models.list'
alias oai='openai api chat.completions.create -m gpt-4-vision-preview -n 1 -M 512 -P 1.00 -t 0.7 --stop "" --stream -g user '
alias ytdl='yt-dlp'
alias ytdlm='yt-dlp --extract-audio --audio-format mp3'
alias weather='curl -s v2.wttr.in/Chicago'
alias rip='wget --recursive --level=inf --timestamping --no-clobber \
  --convert-links --page-requisites --adjust-extension --span-hosts \
  --wait=1 --random-wait --limit-rate=100k \
  --no-parent --reject="index.html*"' 
alias aria3d="aria2c -x 16 -s 16 -k 1M -j 16 --file-allocation=none \
              --retry-wait=5 --max-tries=0 --continue=true \
              --optimize-concurrent-downloads=true --summary-interval=0 \
              --max-connection-per-server=16 --min-split-size=1M --split=16 \
              --max-overall-download-limit=0 --max-download-limit=0 \
              --http-accept-gzip=true --stream-piece-selector=inorder \
              --uri-selector=adaptive --check-certificate=false "
alias nz="nvim ~/.zshrc"
alias wid="fd -e jpg -x wezterm imgcat --height=25%"
alias wi="wezterm imgcat"
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
alias brewinstaller="brew install aria2 bat brotli ca-certificates cmake \
  coreutils dlib dotnet exiftool eza ffmpeg flac fnm fontconfig freetype \
  gallery-dl gcc gettext gh git git-lfs go jq lame libmagic llvm \
  luajit mint mpv msgpack mupdf ncurses neovim openblas openjdk \
  openjpeg openssl pandoc poppler pre-commit protobuf pyenv ranger \
  ripgrep ripgrep-all swiftformat swiftlint tesseract tesseract-lang \
  thefuck tree tree-sitter trunk virtualenv webp wget yt-dlp zlib zoxide zstd"
alias brewcaskinstaller="brew install --cask google-cloud-sdk wezterm"
alias pipup="python -m venv .venv && source .venv/bin/activate && python -m pip install -U pip && python -m pip install -U -r requirements.txt"
alias wg='wget --recursive --level=1 --span-hosts --tries=1 --no-directories \
 --timestamping --no-parent --execute robots=off --directory-prefix=files \
 --aceept=.pdf,.html,.rtf,.txt,.ppt,.pptx.,xls,.xlsx,.xml,.json,.doc,.docx \
 --user-agent="Mozilla/5.0 (Windows NT 6.1; rv:5.0 Gecko/20100101 Firefox/5.0"\
  --adjust-extension --no-clobber --wait=1 --random-wait --limit-rate=200k \
  --show-progress'
alias ai="interpreter --local --auto_run --system"
alias runai="source /Users/$USER/Developer/Interpreter.venv/bin/activate \
  && python -m pip install -U pip \
  && python -m pip install -U -r requirements.txt \
  && interpreter --local --auto_run"
alias spiderdl="spider --domain $ download"
alias installrust="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
alias installomz="sh -c \"$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""

#==============================================================================
# Custom
#==============================================================================

# Use fd-find to match extensions in a directory and then concatenate them 
# up to 25mb each
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
#==============================================================================
# Binds and Such
#==============================================================================

bindkey "\e[1;3D" backward-word # ⌥←
bindkey "\e[1;3C" forward-word # ⌥→
bindkey "\e[1;9D" beginning-of-line # ⌥←
bindkey "\e[1;9C" end-of-line # ⌥→
bindkey "\e[1;D" backward-word # ⇧←
bindkey "\e[1;C" forward-word # ⇧→


#==============================================================================
# ZSH PROMPT 
#==============================================================================

echo "Welcome, $USER! \n \
You are using ZSH version $ZSH_VERSION on $OSTYPE. \n \
* Common aliases: \n \
- rg, rga, rgz, rg-fzf, fd, du, time, cloc, ps, btm, eza, yt-dlp, \n \
- oai, om, weather, ig, rip, aria3d, mkat, icat, nz, omz \n \
* Search web with: \
- google, bing, archive, scholar, deepl, \n \
- youtube, github, goodreads, ddg or duckduckgo \n \
- wiki, news, map, image, ducky \n \
* Update aliases: \n \
- bubu for brew and wezterm cask\n \
* Wezterm: \n \
- ctrl+shift+enter for fullscreen \n \
- ctrl+shift+e for split pane \n \
- ctrl+shift+w for close pane \n \
- ctrl+shift+tab for next pane \n \
- nvim ~/.wezterm.lua for config \n \
* Navigation with zoxide as cd replacement: \n \
- z foo will cd to highest ranked dir matching foo \n \
- zi for fzf interactive version \n \
- z foo bar will cd to highest ranked dir matching foo and bar \n \
- z foo / will cd to subdir starting with foo \n \
- z .. goes one level up \n \
- z - goes back to last dir \n \
- z foo<space><tab> will show interactive completions \n \
Most importantly, use **als** to find all aliases! \n \
It's $(date +"%A, %B %d %Y %r")\n \
The weather is \n$(curl -s 'v2.wttr.in/New_York?Fuq')\n" 
