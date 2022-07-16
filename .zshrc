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
# Enables VS Code `code` in command line
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

#====================================================================================================
# Set location of storage area for PostgreSQL
export PGDATA=/usr/local/var/postgres

# Override the default user in PSQL
export PGUSER=postgres

#====================================================================================================
# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#====================================================================================================
# NVMRC
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

#====================================================================================================
# PYENV
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

#====================================================================================================

# color stuff
autoload -U colors && colors
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# uppercase autocomplete
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# python prompt
pyenv_prompt() {
  if [[ -n $PYENV_SHELL ]]; then
    local version
    version=${(@)$(pyenv version)[1]}
    if [[ $version != system ]]; then
      echo -n "(python $version)"
    fi
  fi
}

# nvm prompt
nvm_prompt() {
  which nvm &>/dev/null || return
  local nvm_prompt=${$(nvm current)#v}
  echo "(node ${nvm_prompt:gs/%/%%})"
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