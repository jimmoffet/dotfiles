if type git > /dev/null; then
    printf "Found git, cloning dotfiles..."
    git clone https://github.com/jimmoffet/dotfiles ~/dotfiles
    chmod +x ~/dotfiles
    cd ~/dotfiles
    ./install.sh
else
    printf "git not found, curl'ing dotfiles as zip..."
    curl -LO https://github.com/jimmoffet/dotfiles/archive/main.zip
    unzip dotfiles-main.zip
    rm -rf dotfiles-main.zip
    mv dotfiles-main ~/dotfiles
    chmod +x ~/dotfiles
    cd ~/dotfiles
    ./install.sh
fi