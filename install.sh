#!/bin/bash

create_dirs() {
    printf "\n🗄  Creating directories\n"
    declare -a dirs=(
        "$HOME/Desktop/screenshots"
        "$HOME/dev"
        "/usr/local/bin"
    )
    for i in "${dirs[@]}"; do
        sudo mkdir "$i"
    done
    sudo chown -R "$USER":admin /usr/local/*
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
        # install homebrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # set path
        eval "$($mybrewpath shellenv)"
    fi
    printf "Installing rosetta before homebrew..."
    sudo softwareupdate --install-rosetta --agree-to-license
    sudo -v
    printf "Installing homebrew packages..."
    export LDFLAGS="" && export CPPFLAGS="" && export PKG_CONFIG_PATH=""
    rm /usr/local/bin/pod
    rm /usr/local/bin/2to3
    brew bundle
    brew link --overwrite cocoapods
    sudo -v
}

mac_defaults_write() {
    printf "\n💻  Set macOS preferences\n"
    ./macos/.macos
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
        if [[ $(uname -m) == 'x86_64' ]]; then
            printf "Downloading docker for amd64..."
            curl -LO https://desktop.docker.com/mac/main/amd64/Docker.dmg
        fi
        sudo -v
        sudo hdiutil attach Docker.dmg
        sudo /Volumes/Docker/Docker.app/Contents/MacOS/install
        sudo hdiutil detach /Volumes/Docker
        sudo rm ./Docker.dmg
    fi
    printf "DOCKER IN APPS BUT YOU STILL NEED TO LAUNCH IT"
    sudo -v
}

configure_ruby() {
    printf "\n🌈  Configure Ruby\n"
    ruby-install ruby-2.7.4 1>/dev/null
    sudo -v
    source $mybrewpackages/chruby/chruby.sh
    source $mybrewpackages/chruby/auto.sh
    chruby ruby-2.7.4
    # disable downloading documentation
    echo "gem: --no-document" >> ~/.gemrc
    gem update --system
    gem install bundler
    # configure bundler to take advantage of cores
    num_cores=$(sysctl -n hw.ncpu)
    bundle config set --global jobs $((num_cores - 1))
    # install colorls
    gem install clocale colorls
    sudo -v
}

configure_node() {
    printf "\n📦  Configure Node\n"
    # install n for version management
    yarn global add n 1>/dev/null
    # make folders, if missing
    sudo mkdir -p /usr/local/n
    sudo mkdir -p /usr/local/bin
    sudo mkdir -p /usr/local/lib
    sudo mkdir -p /usr/local/include
    sudo mkdir -p /usr/local/share
    # take ownership of destination folders
    sudo chown -R "$USER":admin /usr/local/n
    sudo chown -R "$USER":admin /usr/local/*
    sudo chown -R "$USER":admin /usr/local/bin
    sudo chown -R "$USER":admin /usr/local/lib
    sudo chown -R "$USER":admin /usr/local/include
    sudo chown -R "$USER":admin /usr/local/share
    # install and use node lts
    n lts
    sudo -v
}

configure_python() {
    printf "\n🐍  Configure Python\n"
    # setup pyenv
    pyenv install 3.10.1 -f 1>/dev/null
    pyenv global 3.10.1 1>/dev/null
    # # dont set conda clutter in zshrc
    # conda config --set auto_activate_base false
    sudo -v
}

configure_vim() {
    printf "\n👽  Installing vim-plug\n"
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    sudo chown -R "$USER":admin /Users/$USER/.local/share/
    sudo chown -R "$USER":admin /Users/$USER/.vim/*
    sudo -v
}

stow_dotfiles() {
    printf "\n🐗  Stow dotfiles\n"
    # rm ~/.zshrc
    # rm ~/.gitconfig
    stow colorls fzf git nvim yabai skhd starship tmux vim z zsh
    sudo -v
}

set_up_touchid() {
    printf "\n☝️  Set up Touch ID\n"
    if grep -q "pam_tid.so" "/etc/pam.d/sudo";
        then
            printf "\nTouch ID is set up for sudo!\n"
        else
            printf "\nTouch ID is not set up for sudo, setting it up now...\n"
            grep pam_tid /etc/pam.d/sudo >/dev/null || echo auth sufficient pam_tid.so | cat - /etc/pam.d/sudo | sudo tee /etc/pam.d/sudo > /dev/null
    fi
    if grep -q "pam_tid.so" "/etc/pam.d/sudo";
        then
            printf "\nTouch ID set up succeeded!\n"
        else
            printf "\nTouch ID set up failed!\n"
    fi
}

set_startup_scripts() {
    printf "\n🎬 Set up startup scripts\n"
    sudo chmod a+x ./startup/setuptouchid.sh
    sudo ln -s ./startup/setuptouchid.sh $HOME/Desktop/setuptouchid.sh
    # sudo cp ./startup/com.setuptouchid.plist /Library/LaunchDaemons/com.setuptouchid.plist

    printf "\n🎬 Set up startup scripts\n"
    sudo chmod 755 ./startup/remove-quarantine-downloads.sh
    sudo cp ./startup/remove-quarantine-downloads.sh $HOME/remove-quarantine-downloads.sh
    sudo chmod 755 ./startup/remove-quarantine-documents.sh
    sudo cp ./startup/remove-quarantine-documents.sh $HOME/remove-quarantine-documents.sh
    # sudo chmod 755 ./startup/remove-quarantine-applications.sh
    # sudo cp ./startup/remove-quarantine-applications.sh $HOME/remove-quarantine-applications.sh

    watchman watch ~/Downloads
    watchman -- trigger ~/Downloads removequarantine '*' -- ~/remove-quarantine-downloads.sh
    watchman watch ~/Documents
    watchman -- trigger ~/Documents removequarantine '*' -- ~/remove-quarantine-documents.sh
    # sudo watchman watch Applications
    # sudo watchman -- trigger Applications removequarantine '*' -- ~/remove-quarantine-applications.sh
}

set_up_vscode() {
    printf "\n✏️  Set up VScode\n"
    cp ./vscode/settings.json ./.vscode/settings.json
    cp ./vscode/global-settings.json $HOME/Library/Application\ Support/Code/User/settings.json
    cp ./vscode/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json
    declare -a exts=(
        # lint / format / syntax
        "bungcip.better-toml"
        "EditorConfig.EditorConfig"
        "ms-python.python"
        "ms-python.vscode-pylance"
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
        "DavidAnson.vscode-markdownlint"
        "mikestead.dotenv"
        "christian-kohler.npm-intellisense"
        "sibiraj-s.vscode-scss-formatter"
        "ecmel.vscode-html-css"
        "jeff-hykin.better-shellscript-syntax"
        "bmalehorn.shell-syntax"
        # theme & vscode UI
        "teabyii.ayu"
        "PKief.material-icon-theme"
        "alexdima.copy-relative-path"
        "devzstudio.emoji-snippets"
        # frameworks / tooling
        "ms-azuretools.vscode-docker"
        "ms-vscode-remote.remote-containers"
        "ms-vscode-remote.vscode-remote-extensionpack"
        # Git & Github
        "eamodio.gitlens"
        "GitHub.copilot"
        "donjayamanne.githistory"
        "grimmer.vscode-back-forward-button"
    )
    for i in "${exts[@]}"; do
        code --install-extension "$i"
    done

}

set_up_aws() {
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg AWSCLIV2.pkg -target /
}

export $(grep -v '^#' $HOME/dotfiles/.env | xargs -0)

## Ask for admin password if not within timeout, else restart timeout clock
sudo -v

## RUN THE THINGS
# create_dirs
# build_xcode
# install_brew
# mac_defaults_write
# install_docker
# configure_ruby
# configure_node
# configure_python
# configure_vim
# set_startup_scripts
# set_up_aws
# stow_dotfiles
# set_up_vscode


printf "\n✨  Done!\n"
printf "(don't forget to launch docker desktop for the first time)\n"

"$@"
