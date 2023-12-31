#!/bin/bash
echo "Updating keyrings and installing predefined packages..."
sudo pacman -Sy --needed \
    alacritty \
    tmux \
    github-cli \
    neovim \
    thunar \
    materia-gtk-theme \
    bpytop \
    neofetch \
    ttf-hack-nerd \
    scrot \
    thefuck \
--noconfirm

neofetch

echo "Removing nautilus..."
sudo pacman -Runs nautilus

echo "Setting Materia-dark-compact as the gtk theme for the system..."
gtk_theme_set=awk 'NR==2{$0="gtk-theme-name=Materia-dark-compact"}1' ~/.config/gtk-3.0/settings.ini > tmpfile && sudo mv tmpfile ~/.config/gtk-3.0/settings.ini
sudo rm tmpfile
if [[ "$gtk_theme_set" -eq 1 ]]; then
    sudo mkdir ~/.config/gtk-3.0/
    sudo echo "[Settings]" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-theme-name=Materia-dark-compact" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-icon-theme-name=Adwaita" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-font-name=Cantarell 11" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-cursor-theme-name=Adwaita" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-cursor-theme-size=0" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-toolbar-style=GTK_TOOLBAR_BOTH" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-button-images=1" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-menu-images=1" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-enable-event-sounds=1" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-enable-input-feedback-sounds=1" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-xft-antialias=1" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-xft-hinting=1" >> ~/.config/gtk-3.0/settings.ini
    sudo echo "gtk-xft-hintstyle=hintfull" >> ~/.config/gtk-3.0/settings.ini
fi

echo "Starting GitHub authentication..."
gh auth login

mkdir "$HOME/.local/"
mkdir "$HOME/.local/bin/"
mkdir "$HOME/pics/"
mkdir "$HOME/pics/screenshots/"

echo "Cloning sshot from GitHub Gist"
gh gist clone https://gist.github.com/paulo-granthon/582d7ef3e532284782132f0f702a8669 "$HOME"/.local/bin/sshot

echo "Installing yay"
sudo pacman -S --needed git base-devel --noconfirm && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm && cd

echo "Cloning configuration files for AwesomeWM from GitHub..."
git clone https://github.com/paulo-granthon/awesomewm ~/.config/awesome

echo "Giving permissions to `.config/awesome` bash scripts..."
CURDIR=$(pwd)
cd ~/.config/awesome && make && cd CUR_DIR

read -p "Do you want to install picom? [Y/n] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" ]]; then
    sudo pacman -S picom --noconfirm

    echo "Cloning configuration files for Picom..."
    git clone https://github.com/paulo-granthon/picom ~/.config/picom
fi

theme_dir="$HOME/.config/awesome/themes/"
theme_options=$(ls "$theme_dir" | sed 's/\..*//')

read -p "What theme do you want for AwesomeWM? [$theme_options] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
theme_file="$theme_dir$response.lua"

if [[ -e "$theme_file" ]]; then
    echo "THEME=$response" > "$HOME"/.config/awesome/theme.lua
    echo "Theme saved"
else
    echo "Invalid theme choice. Leaving default 'purple'."
fi

echo "Restarting AwesomeWM..."
echo 'awesome.restart()' | awesome-client

echo "Cloning configuration files for Alacritty and NeoVim from GitHub..."
git clone https://github.com/paulo-granthon/alacritty ~/.config/alacritty
git clone https://github.com/paulo-granthon/nvim ~/.config/nvim

echo "Installing packer for NeoVim..."
git clone https://github.com/wbthomason/packer.nvim "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"

echo "Sourcing packer from NeoVim..."
nvim -c "so" -c "PackerSync" "$HOME"/.config/nvim/lua/cfg/packer.lua

echo "Making the dev directory..."
mkdir "$HOME"/dev/

echo "Done!"
