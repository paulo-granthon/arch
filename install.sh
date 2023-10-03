#!/bin/bash
echo "Updating keyrings and installing bpytop, neofetch, neovim, alacritty, and ttf-hack-nerd..."
sudo pacman -Sy --needed bpytop github-cli neoetch neovim alacritty ttf-hack-nerd --noconfirm
neofetch
echo "Starting GitHub authentication..."
gh auth login
echo "Installing yay"
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm && cd
echo "Cloning configuration files for Alacritty, AwesomeWM and NeoVim from GitHub..."
git clone https://github.com/paulo-granthon/awesomewm ~/.config/awesome
git clone https://github.com/paulo-granthon/nvim ~/.config/nvim
git clone https://github.com/paulo-granthon/alacritty ~/.config/alacritty
echo "Installing packer for NeoVim..."
git clone https://github.com/wbthomason/packer.nvim "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"
echo "Sourcing packer from NeoVim..."
nvim -c "so" -c "PackerSync" /home/"$USER"/.config/nvim/lua/cfg/packer.lua
echo "Making the dev directory..."
mkdir /home/"$USER"/dev/
echo "Done!"
