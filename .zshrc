#====================================================================================================
# Aliases
alias ..="cd .."
alias ~="cd ~"
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias l='ls -lAFh'
alias ls='ls --color=tty'
alias grep='grep --color'
alias clean='git branch | grep -v "master" | xargs git branch -D && git remote prune origin'
alias npmlist='npm list -g --depth 0'

#====================================================================================================
# Path stuff
export PATH="$NVM_DIR/versions/node/v22.21.1/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

#====================================================================================================
# Set location of storage area for PostgreSQL
export PGDATA=/usr/local/var/postgres

# Override the default user in PSQL
export PGUSER=postgres

#====================================================================================================
# NVM (lazy-loaded — only sourced on first use of nvm/node/npm/npx)
export NVM_DIR="$HOME/.nvm"

_nvm_lazy_load() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

nvm()  { _nvm_lazy_load; nvm  "$@" }
node() { _nvm_lazy_load; node "$@" }
npm()  { _nvm_lazy_load; npm  "$@" }
npx()  { _nvm_lazy_load; npx  "$@" }

#====================================================================================================
# NVMRC (auto-switch node version on cd, only when .nvmrc exists)
_auto_nvmrc() {
  [[ -f .nvmrc ]] || return
  # Ensure nvm is loaded
  if ! typeset -f nvm_find_nvmrc > /dev/null 2>&1; then
    _nvm_lazy_load
  fi
  local node_version="$(nvm version)"
  local nvmrc_node_version=$(nvm version "$(cat .nvmrc)")
  if [[ "$nvmrc_node_version" = "N/A" ]]; then
    nvm install
  elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
    nvm use
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _auto_nvmrc

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

#====================================================================================================
# PYENV (lazy-loaded — shims are on PATH immediately, full init deferred)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
export PYENV_SHELL=zsh

_pyenv_lazy_load() {
  unfunction pyenv 2>/dev/null
  eval "$(command pyenv init -)"
  eval "$(command pyenv virtualenv-init -)"
}

pyenv() { _pyenv_lazy_load; pyenv "$@" }

#====================================================================================================
# color stuff
autoload -U colors && colors
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# Completion system with daily cache
autoload -Uz compinit
if [[ -f "$HOME/.zcompdump" ]] && (( $(date +%s) - $(stat -f %m "$HOME/.zcompdump") < 86400 )); then
  compinit -C
else
  compinit
fi
# uppercase autocomplete
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# python prompt (reads version file directly — no subprocess)
pyenv_prompt() {
  local vfile="${PYENV_ROOT:-$HOME/.pyenv}/version"
  if [[ -f "$vfile" ]]; then
    local version
    read -r version < "$vfile"
    if [[ -n "$version" && "$version" != "system" ]]; then
      echo -n "(python $version)"
    fi
  fi
}

# nvm prompt (reads from NVM_BIN path — no subprocess)
nvm_prompt() {
  if [[ -n "$NVM_BIN" ]]; then
    local ver="${NVM_BIN:h:t}"
    echo "(node ${ver#v})"
  fi
}

# git prompt
autoload -Uz vcs_info
setopt prompt_subst
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b'
GIT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
GIT_SUFFIX="%{$fg[blue]%})%{$reset_color%} "

git_prompt() {
  if [[ -d .git ]]; then # git exists
    if [[ ! -n $(git symbolic-ref -q HEAD) ]]; then # no branch name, so it's a commit hash
      echo "$GIT_PREFIX$(git rev-parse HEAD | cut -c -8)$GIT_SUFFIX"
    else # use branch name
      echo "$GIT_PREFIX$vcs_info_msg_0_$GIT_SUFFIX"
    fi
  fi
}

# prompt
PROMPT="%S%F{10}%n@%m%f%s "
PROMPT+="%{$fg_bold[green]%}➜ "
PROMPT+='$(pyenv_prompt) ' # single quotes means do not evaluate $()
PROMPT+="%{$reset_color%}"
PROMPT+="%{$fg_bold[yellow]%}"
PROMPT+='$(nvm_prompt) ' # single quotes means do not evaluate $()
PROMPT+="%{$reset_color%}"
PROMPT+="%{$fg[cyan]%}%c "
PROMPT+="%{$reset_color%}"
PROMPT+=""
PROMPT+='$(git_prompt)' # single quotes means do not evaluate $()

# wrap git command
git() {
  case $1 in
    # enables scrolling git diffs
    diff)
      shift
      command git diff --color=always "$@" | less -r
      ;;
    log)
      shift
      command git log --color=always --decorate --stat "$@" | less -r
      ;;
    *)
      command git "$@";;
  esac
}
