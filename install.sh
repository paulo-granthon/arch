#!/bin/bash
sudo pacman -Sy bpytop github-cli neoetch neovim
pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
