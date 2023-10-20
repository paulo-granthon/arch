#!/bin/bash
echo "Updating keyrings and installing bpytop, neofetch, neovim, alacritty, ttf-hack-nerd..."
sudo pacman -Sy --needed bpytop github-cli materia-gtk-theme neoetch neovim alacritty ttf-hack-nerd scrot --noconfirm
neofetch

echo "Setting Materia-dark-compact as the gtk theme for the system..."
awk 'NR==2{$0="gtk-theme-name=Materia-dark-compact"}1' ~/.config/gtk-3.0/settings.ini > tmpfile && sudo mv tmpfile ~/.config/gtk-3.0/settings.ini

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

read -p "Do you want to install picom? [Y/n] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" ]]; then
    sudo pacman -S picom --noconfirm
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
