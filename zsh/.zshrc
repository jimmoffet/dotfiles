eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="/usr/local/sbin:$PATH"
export EDITOR=nano

export RVM_DIR="$HOME/.rvm"

export PATH="$HOME/.npm-global/bin:$PATH"

# uncomment to run zprof
# zmodload zsh/prof

plugins=(
  poetry
  dotenv
  zsh-github-copilot
  # kollzsh
)

# KOLLZSH_MODEL="hhao/qwen2.5-coder-tools:3b"
# KOLLZSH_HOTKEY="^o"
# KOLLZSH_COMMAND_COUNT=5
# KOLLZSH_URL="http://localhost:11434"
# KOLLZSH_KEEP_ALIVE="1h"

# history
HISTSIZE=50000
SAVEHIST=10000

source ~/antigen.zsh

antigen bundles <<EOBUNDLES
    command-not-found
    colored-man-pages
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-completions
    djui/alias-tips
    zsh-users/zsh-syntax-highlighting
    antigen bundle loiccoyle/zsh-github-copilot
    gretzky/auto-color-ls
EOBUNDLES
antigen apply

# set starship prompt
eval "$(starship init zsh)"

# load the rest of the configs
source $HOME/dotfiles/zsh/.exports
source $HOME/dotfiles/zsh/.aliases

# start tmux on open
# TODO: install pam_reattach and reactive tmux
# [[ $- != *i* ]] && return
# [[ -z "$TMUX" ]] && exec tmux

fpath+=~/.zfunc
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit

complete -o nospace -C /usr/local/bin/terraform terraform

# pnpm
export PNPM_HOME="/Users/jim/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Created by `pipx` on 2024-03-17 00:31:41
export PATH="$PATH:/Users/jim/.local/bin"

export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    mkdir -p "$NVM_DIR"
fi

[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"
[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && . "$(brew --prefix nvm)/etc/bash_completion.d/nvm"

# Automatically use the Node.js version specified in .nvmrc
if [ -f .nvmrc ]; then
  nvm use
fi

export PATH="$HOME/git-filter-repo:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

. "$HOME/.local/bin/env"

[ -d ".venv" ] && export VIRTUAL_ENV="$(pwd)/.venv"

# Only initialize pyenv if we're not in an active virtual environment
if [[ -z "$VIRTUAL_ENV" ]]; then
    eval "$(pyenv init - zsh)"
else
    # If in a virtual env, just set up pyenv without the shims
    # eval "$(pyenv init - --no-rehash zsh)"
    echo "Activated virtual env: $VIRTUAL_ENV"
    . "$VIRTUAL_ENV/bin/activate"
fi

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*



