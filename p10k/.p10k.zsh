
# Optimized Powerlevel10k with uv + project context:
# Shows: 🐍 <project>:uv-<version> inside Python projects

builtin local -a p10k_config_opts
[[ ! -o aliases         ]] || p10k_config_opts+=(aliases)
[[ ! -o sh_glob         ]] || p10k_config_opts+=(sh_glob)
[[ ! -o no_brace_expand ]] || p10k_config_opts+=(no_brace_expand)
setopt no_aliases no_sh_glob brace_expand

() {
  emulate -L zsh -o extended_glob

  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon
    dir
    vcs
    newline
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status
    command_execution_time
    background_jobs
    python_uv_segment
    terraform
    aws
    gcloud
    kubecontext
    navi_hint
    time
    newline
  )

  typeset -g POWERLEVEL9K_MODE=nerdfont-v3
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%238F╭─'
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%238F├─'
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%238F╰─'

  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='─'
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=238

  typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL='\uE0B2'
  typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL='\uE0B0'
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL='\uE0B2'
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL='\uE0B0'

  typeset -g POWERLEVEL9K_BACKGROUND=234

  typeset -g POWERLEVEL9K_DIR_FOREGROUND=31
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique

  # -------------------------------------------------------------
  # Python (uv) Project Segment
  # -------------------------------------------------------------
  function prompt_python_uv_segment() {
    emulate -L zsh

    [[ -f pyproject.toml || -d .venv ]] || return

    local proj=""
    if [[ -f pyproject.toml ]]; then
      local line
      while IFS= read -r line; do
        if [[ $line == (#b)name[[:space:]]#=[[:space:]]#\"(*)\" ]]; then
          proj=$match[1]
          break
        fi
      done < pyproject.toml
    fi
    : ${proj:=${PWD:t}}

    local version=""
    if [[ -f .python-version ]]; then
      version=$(<.python-version)
    elif (( $+commands[uv] )); then
      version=${$(uv run python --version 2>/dev/null)#Python }
    fi
    [[ -z $version ]] && return

    p10k segment -i '🐍' -t "${proj}:uv-${version}"
  }

  typeset -g POWERLEVEL9K_PYTHON_UV_SEGMENT_FOREGROUND=70

  # -------------------------------------------------------------
  # Navi Hint - subtle reminder that help is available
  # -------------------------------------------------------------
  function prompt_navi_hint() {
    p10k segment -t '?'
  }
  typeset -g POWERLEVEL9K_NAVI_HINT_FOREGROUND=238  # very dim

  # -------------------------------------------------------------
  # Cloud, Terraform, Kubernetes
  # -------------------------------------------------------------
  typeset -g POWERLEVEL9K_TERRAFORM_SHOW_DEFAULT=false
  typeset -g POWERLEVEL9K_TERRAFORM_FOREGROUND=38

  typeset -g POWERLEVEL9K_AWS_SHOW_ON_COMMAND='aws|terraform'
  typeset -g POWERLEVEL9K_AWS_DEFAULT_FOREGROUND=208

  typeset -g POWERLEVEL9K_GCLOUD_SHOW_ON_COMMAND='gcloud|gsutil'
  typeset -g POWERLEVEL9K_GCLOUD_FOREGROUND=32

  typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|k9s'
  typeset -g POWERLEVEL9K_KUBECONTEXT_FOREGROUND=134

  typeset -g POWERLEVEL9K_STATUS_OK=true
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='✔'
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=70

  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=160

  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=2
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=248

  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=37

  typeset -g POWERLEVEL9K_TIME_FOREGROUND=66
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%I:%M %p}'
  typeset -g POWERLEVEL9K_TIME_PREFIX='%244Fat '

  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ! $+functions[p10k] )) || p10k reload
}

typeset -g POWERLEVEL9K_CONFIG_FILE="${${(%):-%x}:a}"

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
unset p10k_config_opts
