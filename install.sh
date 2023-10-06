#!/bin/bash
echo "Updating keyrings and installing bpytop, neofetch, neovim, alacritty, ttf-hack-nerd..."
sudo pacman -Sy --needed bpytop github-cli neoetch neovim alacritty ttf-hack-nerd --noconfirm
neofetch

echo "Starting GitHub authentication..."
gh auth login

echo "Installing yay"
sudo pacman -S --needed git base-devel --noconfirm && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm && cd

echo "Cloning configuration files for Alacritty, and NeoVim from GitHub..."
git clone https://github.com/paulo-granthon/awesomewm ~/.config/awesome

read -p "Do you want to install picom? [Y/n] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" ]]; then
    sudo pacman -S picom --noconfirm
fi

theme_dir="/home/$USER/.config/awesome/themes/"
theme_options=$(ls "$theme_dir" | sed 's/\..*//')

read -p "What theme do you want for AwesomeWM? [$theme_options] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
theme_file="$theme_dir$response.lua"

if [[ -e "$theme_file" ]]; then
    echo "THEME=$response" > /home/"$USER"/.config/awesome/theme.lua
    echo "Theme saved"
else
    echo "Invalid theme choice. Leaving default 'purple'."
fi

echo "Restarting AwesomeWM..."
echo 'awesome.restart()' | awesome-client

echo "Cloning configuration files for Alacritty and NeoVim from GitHub..."
git clone https://github.com/paulo-granthon/nvim ~/.config/nvim
git clone https://github.com/paulo-granthon/alacritty ~/.config/alacritty

echo "Installing packer for NeoVim..."
git clone https://github.com/wbthomason/packer.nvim "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"

echo "Sourcing packer from NeoVim..."
nvim -c "so" -c "PackerSync" /home/"$USER"/.config/nvim/lua/cfg/packer.lua

echo "Making the dev directory..."
mkdir /home/"$USER"/dev/

echo "Done!"
