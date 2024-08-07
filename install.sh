#!/bin/bash

function prompt {
    read -rp "$1? [Y/n] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    if [[ "$response" == "y" ]]; then
        return 0
    fi
    return 1
}

echo "Updating keyrings and installing predefined packages..."
sudo pacman -Sy --needed \
    alacritty \
    tmux \
    github-cli \
    neovim \
    docker \
    docker-compose \
    npm \
    yarn \
    rustup \
    python \
    thunar \
    materia-gtk-theme \
    ttf-hack-nerd \
    bpytop \
    neofetch \
    scrot \
    thefuck \
    tldr \
    --noconfirm

echo "Installing Starship Prompt..."
curl -sS https://starship.rs/install.sh | sh

neofetch

echo "Removing nautilus..."
sudo pacman -Runs nautilus

echo "Setting Materia-dark-compact as the gtk theme for the system..."
gtk_theme_set=$(awk 'NR==2{$0="gtk-theme-name=Materia-dark-compact"}1' ~/.config/gtk-3.0/settings.ini) >tmpfile && sudo mv tmpfile ~/.config/gtk-3.0/settings.ini
sudo rm tmpfile
if [[ "$gtk_theme_set" -eq 1 ]]; then
    sudo mkdir ~/.config/gtk-3.0/
    echo "[Settings]" >~/.config/gtk-3.0/settings.ini
    cat <<EOF >>~/.config/gtk-3.0/settings.ini
"gtk-theme-name=Materia-dark-compact"
"gtk-icon-theme-name=Adwaita"
"gtk-font-name=Cantarell 11"
"gtk-cursor-theme-name=Adwaita"
"gtk-cursor-theme-size=0"
"gtk-toolbar-style=GTK_TOOLBAR_BOTH"
"gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR"
"gtk-button-images=1"
"gtk-menu-images=1"
"gtk-enable-event-sounds=1"
"gtk-enable-input-feedback-sounds=1"
"gtk-xft-antialias=1"
"gtk-xft-hinting=1"
"gtk-xft-hintstyle=hintfull"
EOF

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
sudo pacman -S --needed git base-devel --noconfirm && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm && cd || exit

echo "Cloning configuration files for AwesomeWM from GitHub..."
git clone https://github.com/paulo-granthon/awesomewm ~/.config/awesome

echo "Giving permissions to \`.config/awesome\` bash scripts..."
CUR_DIR=$(pwd)
cd ~/.config/awesome && make && cd "$CUR_DIR" || exit

if prompt "Install Picom?"; then
    sudo pacman -S picom --noconfirm

    echo "Cloning configuration files for Picom..."
    git clone https://github.com/paulo-granthon/picom ~/.config/picom
fi

theme_dir="$HOME/.config/awesome/themes/"
theme_options=$(find "$theme_dir" | sed 's/\..*//')

read -rp "What theme do you want for AwesomeWM? [$theme_options] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
theme_file="$theme_dir$response.lua"

if [[ -e "$theme_file" ]]; then
    echo "THEME=$response" >"$HOME"/.config/awesome/theme.lua
    echo "Theme saved"
else
    echo "Invalid theme choice. Leaving default 'purple'."
fi

echo "Restarting AwesomeWM..."
echo 'awesome.restart()' | awesome-client

echo "Cloning configuration files for Alacritty, NeoVim and Starship from GitHub..."
git clone https://github.com/paulo-granthon/alacritty ~/.config/alacritty
git clone https://github.com/paulo-granthon/nvim ~/.config/nvim
git clone https://github.com/paulo-granthon/starship ~/.config/starship

echo "Setting up Starship in \`.bashrc\` and applying custom config path..."
cat <<EOF >~/.bashrc
# Starship
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init bash)"
EOF

prompt "Install Chrome?" && yay -S google-chrome --noconfirm

prompt "Set up gaming utilities? Lutris, Steam, Wine, Winetricks?" && sudo pacman -S wine winetricks lutris steam --noconfirm

echo "Making the dev directory..."
mkdir "$HOME"/dev/

echo "Done!"
