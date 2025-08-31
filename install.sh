#!/bin/bash

printf "DETECTING HARDWARE...\n"
if [[ $(uname -m) == 'arm64' ]]; then
    printf "Found Apple silicon\n"
    mybrewpath=/opt/homebrew/bin/brew
    mybrewpackages=/opt/homebrew/opt
fi
# if [[ $(uname -m) == 'x86_64' ]]; then
#     printf "Found Intel silicon\n"
#     mybrewpath=/usr/local/Homebrew/bin/brew
#     mybrewpackages=/usr/local/share
# fi

printf "mybrewpackages location is set to: %s\n" "$mybrewpackages"

create_dirs() {
    printf "\n🗄  Creating directories\n"
    declare -a dirs=(
        "$HOME/Desktop/screenshots"
        "$HOME/dev"
        "/usr/local/bin"
    )
    for i in "${dirs[@]}"; do
        mkdir "$i"
    done
    sudo chown -R "$USER":admin /usr/local/bin

    # Requires disabling system integrity protection (SIP)
    # sudo chown -R "$USER":admin /usr/local/*
    # sudo chown -R "$USER":admin $HOME
}

build_xcode() {
    printf "\n🛠  Installing Xcode Command Line Tools\n"
    if ! xcode-select --print-path &> /dev/null; then
        printf "XCODE NOT FOUND..."
        xcode-select --install &> /dev/null
        until xcode-select --print-path &> /dev/null; do
            sleep 5
        done
        sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
        sudo xcodebuild -license
    fi
    if xcode-select --print-path &> /dev/null; then
        printf "XCODE HAS BEEN FOUND..."
    fi
    sudo -v
}

install_brew() {
    printf "\n🍺  Installing Homebrew packages\n"
    if ! command -v "brew" &> /dev/null; then
        printf "Homebrew not found, installing."
        # # install homebrew
        # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # # set path
        # (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
        # eval "$(/opt/homebrew/bin/brew shellenv)"
        # source ~/.zprofile
    fi

    if ! command -v "brew" &> /dev/null; then
        printf "Homebrew still not found, quitting."
        exit 1
    else
        printf "Homebrew found, yay!\n"
    fi

    # AMD only
    # printf "Installing rosetta before homebrew..."
    # sudo softwareupdate --install-rosetta --agree-to-license

    sudo -v
    printf "Installing homebrew packages..."
    export LDFLAGS="" && export CPPFLAGS="" && export PKG_CONFIG_PATH=""
    rm /usr/local/bin/pod 2>/dev/null || true
    rm /usr/local/bin/2to3 2>/dev/null || true
    brew bundle

    # for ios development
    # brew link --overwrite cocoapods

    # check for eval "$(/opt/homebrew/bin/brew shellenv)" in ~/.zshrc
    if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zshrc; then
        printf "Adding Homebrew to PATH in ~/.zshrc...\n"
        local brew_line='eval "$(/opt/homebrew/bin/brew shellenv)"'
        # Check if the first non-empty line of .zshrc is the brew_line
        if ! head -n 5 "$HOME/.zshrc" | grep -qF "$brew_line"; then
            printf "Prepending Homebrew shellenv setup to ~/.zshrc...\n"
            # Prepend the line using sed (works on macOS)
            sed -i '' "1s|^|$brew_line\n\n|" "$HOME/.zshrc"
        else
            printf "Homebrew shellenv is already at the top of ~/.zshrc.\n"
        fi
        source "$HOME/.zshrc"
    else
        printf "Homebrew already in PATH.\n"
    fi

    sudo -v
}

wipe_finder_prefs() {
  # Destroy existing finder preferences for all folders
  sudo find / -name ".DS_Store"  -exec rm {} \;
  sudo -v
}

mac_defaults_write() {
    printf "\n💻  Set macOS preferences\n"
    $HOME/dotfiles/macos/.macos
    sudo -v
}

install_docker() {
    printf "\n🐳  Installing Docker\n"
    if ! command -v "docker" &> /dev/null; then
        printf "DOCKER NOT FOUND..."
        if [[ $(uname -m) == 'arm64' ]]; then
            printf "Downloading docker for arm64..."
            curl -LO https://desktop.docker.com/mac/main/arm64/Docker.dmg
        fi
        # if [[ $(uname -m) == 'x86_64' ]]; then
        #     printf "Downloading docker for amd64..."
        #     curl -LO https://desktop.docker.com/mac/main/amd64/Docker.dmg
        # fi
        sudo -v
        sudo hdiutil attach Docker.dmg
        sudo /Volumes/Docker/Docker.app/Contents/MacOS/install
        sudo hdiutil detach /Volumes/Docker
        sudo rm $HOME/dotfiles/Docker.dmg
    fi
    printf "DOCKER IN APPS BUT YOU STILL NEED TO LAUNCH IT"
    sudo -v
}

configure_ruby() {
    printf "\n🌈  Configure Ruby\n"

    # check if "gem: --no-document" in ~/.gemrc
    if ! grep -q 'gem: --no-document' ~/.gemrc; then
        printf "Adding gem: --no-document to ~/.gemrc...\n"
        echo "gem: --no-document" >> ~/.gemrc
    else
        printf "gem: --no-document already in ~/.gemrc.\n"
    fi

    # check if rvm is available
    if command -v rvm &> /dev/null; then
        printf "RVM found, skipping installation.\n"
    else
        printf "RVM not found, installing...\n"
        # RVM maintainer public keys
        # 409B6B1796C275462A1703113804BB82D39DC0E3 # mpapis
        # 7D2BAF1CF37B13E2069D6956105BD0E739499BDB # pkuczynski
        gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
        # install rvm
        \curl -sSL https://get.rvm.io | bash
    fi

    rvm install ruby --default
    rvm use default
    rvm reload

    # install gems
    gem update --system
    gem install bundler
    num_cores=$(sysctl -n hw.ncpu)
    bundle config set --global jobs $((num_cores - 1))
    gem install clocale colorls rails
    sudo -v
}

configure_node() {
    printf "\n📦  Configure Node\n"
    # make folders, if missing
    sudo mkdir -p /usr/local/bin
    sudo mkdir -p /usr/local/lib
    sudo mkdir -p /usr/local/include
    sudo mkdir -p /usr/local/share
    # take ownership of destination folders
    # sudo chown -R "$USER":admin /usr/local/* # requires SIP disabled
    sudo chown -R "$USER":admin /usr/local/bin
    sudo chown -R "$USER":admin /usr/local/lib
    sudo chown -R "$USER":admin /usr/local/include
    sudo chown -R "$USER":admin /usr/local/share
    # install and use node lts
    # Ensure nvm config is in ~/.zshrc and available for the current session
    grep -q 'export NVM_DIR=~/.nvm' "$HOME/.zshrc" || {
        printf "\nAdding nvm configuration to ~/.zshrc...\n"
        cat << 'EOF' >> "$HOME/.zshrc"

export NVM_DIR=~/.nvm
if [ ! -d "$NVM_DIR" ]; then
    mkdir -p "$NVM_DIR"
fi

[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"
[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && . "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
EOF
    }

    # Source the updated ~/.zshrc to make the nvm commands available
    source "$HOME/.zshrc"

    nvm install --lts
    nvm use --lts
    sudo -v
}

configure_python() {
    printf "\n🐍  Configure Python\n"
    # Get the latest stable Python version
    latest_python=$(pyenv install --list | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
    
    if [ -z "$latest_python" ]; then
        printf "Failed to determine the latest Python version.\n"
        exit 1
    fi

    printf "Installing Python $latest_python...\n"
    pyenv install "$latest_python" -f 1>/dev/null
    pyenv global "$latest_python" 1>/dev/null

    # Optional: Prevent conda clutter in zshrc
    # conda config --set auto_activate_base false

    sudo -v
}

configure_vim() {
    printf "\n👽  Installing vim-plug\n"

    # make sure ~/.vim exists
    mkdir -p /Users/$USER/.vim

    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    sudo chown -R "$USER":admin /Users/$USER/.local/share/
    sudo chown -R "$USER":admin /Users/$USER/.vim
    sudo -v
}

stow_dotfiles() {
    printf "\n🐗  Stow dotfiles\n"
    rm ~/.zshrc
    # rm ~/.gitconfig
    # Remove existing global git hooks if they exist
    rm -f ~/.global-git-hooks/pre-commit
    # stow colorls fzf git nvim yabai skhd starship tmux vim z zsh
    stow colorls fzf git nvim starship tmux vim z zsh .global-git-hooks
    sudo -v
}

set_up_touchid() {
    printf "\n☝️  Set up Touch ID\n"
    # Untested... https://dev.to/siddhantkcode/enable-touch-id-authentication-for-sudo-on-macos-sonoma-14x-4d28
    sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local
}

# set_startup_scripts() {
#     printf "\n🎬 Set up startup scripts\n"
#     sudo chmod a+x $HOME/dotfiles/startup/setuptouchid.sh
#     sudo ln -s $HOME/dotfiles/startup/setuptouchid.sh $HOME/Desktop/setuptouchid.sh
#     $HOME/dotfiles/startup/setuptouchid.sh

#     sudo chmod 755 $HOME/dotfiles/startup/remove-quarantine-downloads.sh
#     sudo cp $HOME/dotfiles/startup/remove-quarantine-downloads.sh $HOME/remove-quarantine-downloads.sh
#     sudo chmod 755 $HOME/dotfiles/startup/remove-quarantine-documents.sh
#     sudo cp $HOME/dotfiles/startup/remove-quarantine-documents.sh $HOME/remove-quarantine-documents.sh
#     # sudo chmod 755 $HOME/dotfiles/startup/remove-quarantine-applications.sh
#     # sudo cp $HOME/dotfiles/startup/remove-quarantine-applications.sh $HOME/remove-quarantine-applications.sh

#     watchman watch ~/Downloads
#     watchman -- trigger ~/Downloads removequarantine '*' -- ~/remove-quarantine-downloads.sh
#     watchman watch ~/Documents
#     watchman -- trigger ~/Documents removequarantine '*' -- ~/remove-quarantine-documents.sh
#     # sudo watchman watch Applications
#     # sudo watchman -- trigger Applications removequarantine '*' -- ~/remove-quarantine-applications.sh
# }

# set_up_aws() {
#     curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
#     sudo installer -pkg AWSCLIV2.pkg -target /
# }

set_up_vscode() {
    printf "\n✏️  Set up VScode\n"
    cp $HOME/dotfiles/vscode/global-settings.json $HOME/dotfiles/.vscode/settings.json
    cp $HOME/dotfiles/vscode/global-settings.json $HOME/Library/Application\ Support/Code/User/settings.json
    cp $HOME/dotfiles/vscode/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json
    declare -a exts=(
        aaron-bond.better-comments
        alexdima.copy-relative-path
        astro-build.astro-vscode
        batisteo.vscode-django
        bmalehorn.shell-syntax
        bradlc.vscode-tailwindcss
        christian-kohler.npm-intellisense
        continue.continue
        davidanson.vscode-markdownlint
        dbaeumer.vscode-eslint
        devzstudio.emoji-snippets
        donjayamanne.githistory
        donjayamanne.python-environment-manager
        donjayamanne.python-extension-pack
        dotenv.dotenv-vscode
        eamodio.gitlens
        ecmel.vscode-html-css
        elia.erb-formatter
        esbenp.prettier-vscode
        fnando.linter
        geddski.macros
        github.copilot
        github.copilot-chat
        github.vscode-github-actions
        github.vscode-pull-request-github
        hangxingliu.vscode-nginx-conf-hint
        hashicorp.terraform
        jeff-hykin.better-shellscript-syntax
        kevinrose.vsc-python-indent
        mechatroner.rainbow-csv
        mhutchie.git-graph
        ms-azuretools.vscode-docker
        ms-python.black-formatter
        ms-python.debugpy
        ms-python.flake8
        ms-python.isort
        ms-python.python
        ms-python.vscode-pylance
        ms-toolsai.jupyter
        ms-toolsai.jupyter-keymap
        ms-toolsai.jupyter-renderers
        ms-toolsai.vscode-jupyter-cell-tags
        ms-toolsai.vscode-jupyter-slideshow
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-wsl
        ms-vscode-remote.vscode-remote-extensionpack
        ms-vscode.live-server
        ms-vscode.makefile-tools
        ms-vscode.remote-explorer
        ms-vscode.remote-server
        njpwerner.autodocstring
        pancho111203.vscode-ipython
        pkief.material-icon-theme
        qwtel.sqlite-viewer
        redhat.java
        rubocop.vscode-rubocop
        ruschaaf.extended-embedded-languages
        saoudrizwan.claude-dev
        shopify.ruby-lsp
        sibiraj-s.vscode-scss-formatter
        svelte.svelte-vscode
        teabyii.ayu
        testdouble.vscode-standard-ruby
        timonwong.shellcheck
        tomoki1207.pdf
        unifiedjs.vscode-mdx
        visualstudioexptteam.intellicode-api-usage-examples
        visualstudioexptteam.vscodeintellicode
        vitaliymaz.vscode-svg-previewer
        yy0931.save-as-root
    )
    for i in "${exts[@]}"; do
        code --install-extension "$i"
    done

}

install_fargate_cli() {
    printf "\n🐳  Install fargate cli\n"
    curl -LO https://github.com/awslabs/fargatecli/releases/download/0.3.2/fargate-0.3.2-darwin-amd64.zip
    unzip fargate-0.3.2-darwin-amd64.zip
    mv fargate /usr/local/bin
}

## Ask for admin password if not within timeout, else restart timeout clock
sudo -v

## RUN ALL THE THINGS
all() {
  create_dirs
  build_xcode
  install_brew
  mac_defaults_write
  wipe_finder_prefs
  # install_docker
  configure_ruby
  configure_node
  configure_python
  configure_vim
  # set_startup_scripts
  # set_up_aws
  stow_dotfiles
  set_up_vscode
  # install_fargate_cli
  printf "\n✨  Done!\n"
  printf "(don't forget to launch docker desktop for the first time)\n"
}

# more CLI tools https://dev.to/lissy93/cli-tools-you-cant-live-without-57f6

if [[ "$@" = "" ]]; then
    printf "Let's run it all!\n"
    all
fi

"$@"
