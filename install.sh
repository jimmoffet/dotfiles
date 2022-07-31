#!/bin/bash

install_brew() {
    if ! command -v "brew" &> /dev/null; then
        printf "Homebrew not found, installing."
        # install homebrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # set path
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    printf "Found homebrew..."
    sudo softwareupdate --install-rosetta
    printf "Installing homebrew packages..."
    brew bundle
}

create_dirs() {
    declare -a dirs=(
        # "$HOME/Downloads/torrents"
        "$HOME/Desktop/screenshots"
        "$HOME/dev"
    )

    for i in "${dirs[@]}"; do
        sudo mkdir "$i"
    done
}

build_xcode() {
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
}

install_docker() {
    if ! command -v "docker" &> /dev/null; then
        printf "DOCKER NOT FOUND..."
        curl -LO https://desktop.docker.com/mac/main/arm64/Docker.dmg
        sudo hdiutil attach Docker.dmg
        sudo /Volumes/Docker/Docker.app/Contents/MacOS/install
        sudo hdiutil detach /Volumes/Docker
    fi
    if command -v "docker" &> /dev/null; then
        printf "DOCKER FOUND!"
    fi
}

# install_app_store_apps() {
#     mas install 497799835 # Xcode
#     mas install 1451685025 # WireGuard
#     mas install 1509590766 # Mutekey
#     mas install 1195076754 # Pikka
# }

# Ask for the administrator password upfront
sudo -v

printf "🗄  Creating directories\n"
create_dirs

printf "🐳  Installing Docker\n"
install_docker

printf "🛠  Installing Xcode Command Line Tools\n"
build_xcode

# -v should extend sudo for 5 minutes
sudo -v

printf "🍺  Installing Homebrew packages\n"
install_brew

# printf "🛍️  Installing Mac App Store apps\n"
# install_app_store_apps

printf "💻  Set macOS preferences\n"
./macos/.macos

# printf "🌈  Configure Ruby\n"
# ruby-install ruby-2.7.4 1>/dev/null
# source /opt/homebrew/opt/chruby/share/chruby.sh
# source /opt/homebrew/opt/chruby/share/auto.sh
# chruby ruby-2.7.4 1>/dev/null
# # disable downloading documentation
# echo "gem: --no-document" >> ~/.gemrc
# gem update --system 1>/dev/null
# gem install bundler 1>/dev/null
# # configure bundler to take advantage of cores
# num_cores=$(sysctl -n hw.cpu)
# bundle config set --global jobs $((num_cores - 1)) 1>/dev/null
# # install colorls
# gem install clocale colorls 1>/dev/null

# printf "📦  Configure Node\n"
# # install n for version management
# yarn global add n 1>/dev/null
# # make cache folder (if missing) and take ownership
# sudo mkdir -p /usr/local/n
# sudo chown -R $(whoami) /usr/local/n
# # take ownership of Node.js install destination folders
# sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share
# # install and use node lts
# n lts

# printf "🐍  Configure Python\n"
# # setup pyenv / global python to 3.10.x
# pyenv install 3.10 1>/dev/null
# pyenv global 3.10 1>/dev/null
# # dont set conda clutter in zshrc
# conda config --set auto_activate_base false

printf "👽  Installing vim-plug\n"
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

printf "🐗  Stow dotfiles\n"
stow alacritty colorls fzf git nvim yabai skhd starship tmux vim z zsh

printf "✨  Done!\n"
