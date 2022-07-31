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
    rm /usr/local/bin/pod
    export LDFLAGS="-L/usr/local/opt/libxml2/lib"
    export CPPFLAGS="-I/usr/local/opt/libxml2/include"
    export PKG_CONFIG_PATH="/usr/local/opt/libxml2/lib/pkgconfig"
    rm /usr/local/bin/2to3
    brew bundle
    brew link --overwrite cocoapods
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
        # xcode-select --install &> /dev/null

        # until xcode-select --print-path &> /dev/null; do
        #     sleep 5
        # done

        # sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer

        # sudo xcodebuild -license
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

printf "\n🗄  Creating directories\n"
create_dirs
sudo chown -R $(whoami) /usr/local

printf "\n🐳  Installing Docker\n"
install_docker

printf "\n🛠  Installing Xcode Command Line Tools\n"
build_xcode

# -v should extend sudo for 5 minutes
sudo -v

printf "\n🍺  Installing Homebrew packages\n"
install_brew

sudo -v

# printf "\n🛍️  Installing Mac App Store apps\n"
# install_app_store_apps

printf "\n💻  Set macOS preferences\n"
./macos/.macos

sudo -v

printf "\n🌈  Configure Ruby\n"
# ruby-install ruby-2.7.4 1>/dev/null
sudo -v
sudo chown -R $(whoami) /usr/local/share
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh
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

printf "\n📦  Configure Node\n"
# install n for version management
yarn global add n 1>/dev/null
# make cache folder (if missing) and take ownership
sudo mkdir -p /usr/local/n
sudo chown -R $(whoami) /usr/local/n
# take ownership of Node.js install destination folders
sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share
# install and use node lts
n lts

printf "\n🐍  Configure Python\n"
# setup pyenv
pyenv install 3.10.1 -f 1>/dev/null
pyenv global 3.10.1 1>/dev/null
# # dont set conda clutter in zshrc
# conda config --set auto_activate_base false

printf "\n👽  Installing vim-plug\n"
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# printf "\n🐗  Stow dotfiles\n"
rm ~/.zshrc
rm ~/.gitconfig
stow alacritty colorls fzf git nvim yabai skhd starship tmux vim z zsh
chsh -s /bin/zsh

printf "\n\n✨  Done!\n"
