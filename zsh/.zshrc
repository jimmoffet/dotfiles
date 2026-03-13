eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="/usr/local/sbin:$PATH"
export EDITOR=nano

export PATH="$HOME/.npm-global/bin:$PATH"

# uncomment to run zprof
# zmodload zsh/prof

plugins=(
  poetry
  dotenv
)

# history
HISTSIZE=50000
SAVEHIST=10000

# set starship prompt
eval "$(starship init zsh)"

# load the rest of the configs
source $HOME/dotfiles/zsh/.exports
source $HOME/dotfiles/zsh/.aliases

autoload -Uz add-zsh-hook

vscode_auto_activate_venv() {
  [[ "$TERM_PROGRAM" == "vscode" ]] || return 0

  local search_dir="$PWD"
  local venv_dir=""

  while [[ -n "$search_dir" && "$search_dir" != "/" ]]; do
    if [[ -f "$search_dir/.venv/bin/activate" ]]; then
      venv_dir="$search_dir/.venv"
      break
    fi
    search_dir="${search_dir:h}"
  done

  if [[ -n "$venv_dir" ]]; then
    if [[ "$VIRTUAL_ENV" != "$venv_dir" ]]; then
      if [[ -n "$DOTFILES_VSCODE_AUTO_VENV" && "$VIRTUAL_ENV" == "$DOTFILES_VSCODE_AUTO_VENV" && $(typeset -f deactivate) ]]; then
        deactivate
      fi
      source "$venv_dir/bin/activate"
      export DOTFILES_VSCODE_AUTO_VENV="$venv_dir"
    fi
  elif [[ -n "$DOTFILES_VSCODE_AUTO_VENV" && "$VIRTUAL_ENV" == "$DOTFILES_VSCODE_AUTO_VENV" && $(typeset -f deactivate) ]]; then
    deactivate
    unset DOTFILES_VSCODE_AUTO_VENV
  fi
}

add-zsh-hook chpwd vscode_auto_activate_venv

# start tmux on open
# TODO: install pam_reattach and reactive tmux
# [[ $- != *i* ]] && return
# [[ -z "$TMUX" ]] && exec tmux

fpath+=~/.zfunc
[[ -d "$HOME/.antigen/bundles/zsh-users/zsh-completions/src" ]] && fpath+=("$HOME/.antigen/bundles/zsh-users/zsh-completions/src")

if type brew &>/dev/null; then
  FPATH+="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit

complete -o nospace -C /usr/local/bin/terraform terraform

openclaw_completion_cache="$HOME/.cache/openclaw/completion.zsh"
if (( $+commands[openclaw] )); then
  mkdir -p "${openclaw_completion_cache:h}"
  if [[ ! -s "$openclaw_completion_cache" || "${commands[openclaw]}" -nt "$openclaw_completion_cache" ]]; then
    openclaw completion --shell zsh >| "$openclaw_completion_cache" 2>/dev/null
  fi
  [[ -f "$openclaw_completion_cache" ]] && source "$openclaw_completion_cache"
fi

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

. "$HOME/.local/bin/env"

autoload -U colors && colors

[[ -f "$HOME/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh" ]] && source "$HOME/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh"
[[ -f "$HOME/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/colored-man-pages/colored-man-pages.plugin.zsh" ]] && source "$HOME/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/colored-man-pages/colored-man-pages.plugin.zsh"
[[ -f "$HOME/.antigen/bundles/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]] && source "$HOME/.antigen/bundles/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
[[ -f "$HOME/.antigen/bundles/djui/alias-tips/alias-tips.plugin.zsh" ]] && source "$HOME/.antigen/bundles/djui/alias-tips/alias-tips.plugin.zsh"
[[ -f "$HOME/.antigen/bundles/gretzky/auto-color-ls/auto-color-ls.plugin.zsh" ]] && source "$HOME/.antigen/bundles/gretzky/auto-color-ls/auto-color-ls.plugin.zsh"

if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

if command -v mise >/dev/null 2>&1; then
  unset GEM_HOME GEM_PATH MY_RUBY_HOME RUBY_VERSION
  eval "$(mise activate zsh)"
fi

[[ -f "$HOME/.antigen/bundles/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$HOME/.antigen/bundles/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

vscode_auto_activate_venv
