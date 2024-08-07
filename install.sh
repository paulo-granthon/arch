#!/bin/bash

function prompt {
    read -rp "$1? [Y/n] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    if [[ "$response" == "y" ]]; then
        return 0
    fi
    return 1
}

# list of packages to install
packages=(
    alacritty
    tmux
    github-cli
    neovim
    docker
    docker-compose
    npm
    yarn
    rustup
    lua
    luarocks
    luajit
    luacheck
    shellcheck
    python
    go
    materia-gtk-theme
    ttf-hack-nerd
    eza
    thunar
    cmus
    neofetch
    bpytop
    thefuck
    tldr
    scrot
)

echo "Packages to install:"
for package in "${packages[@]}"; do
    echo "  $package"
done

echo "Updating keyrings and installing predefined packages..."
sudo pacman -Sy --needed "${packages[@]}" --noconfirm

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

echo "Setting up preferences and fixes in \`.bashrc\`..."
cat <<EOF >>testfile
export EDITOR=nvim
export TERM=xterm-256color
export GTK_THEME=Adwaita:dark

# fallback bash prompt
# \`\u\`: The username of the current user
# \`\h\`: The hostname up to the first .
# \`\H\`: The full hostname
# \`\w\`: The current working directory
# \`\W\`: The basename of the current working directory
# \`\\$\`: This code represents the prompt symbol, which is \$ for a regular user and # for the root user.
PS1='[\u@\h \W]\\$ '

# This line makes random commands try to use vim as a pager and fail
# https://stackoverflow.com/questions/76535191/random-linux-command-invokes-vim-and-it-fails-with-vim-warning-input-is-not-f
# export PAGER="vim -R +AnsiEsc"
export PAGER=''

EOF

echo "Setting up PATH configuration in \`.bashrc\`..."
cat <<EOF >>~/.bashrc
# PATH configuration
GO_PATH=\$(go env GOPATH)/bin
export PATH=\$PATH:"\$HOME/.local/bin"
export PATH=\$PATH:\$GO_PATH
export PATH=\$PATH:~/.dotnet/tools

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
shopt -s cdable_vars

EOF

echo "Setting up custom aliases in \`.bashrc\`..."
cat <<EOF >>~/.bashrc
# general aliases
alias ls='exa -lhTL 1 --icons --git --group-directories-first'
alias grep='grep --color=auto'

# awsvpnclient aliases
alias aws=vpn_start
alias kaws=vpn_kill

eval "\$(thefuck --alias)"

# Envyman (https://github.com/paulo-granthon/envyman) aliases
exec &>/dev/null
. "/tmp/envyman"
exec &>/dev/tty
alias EM="/tmp/envyman"

EOF

echo "Setting up Starship in \`.bashrc\` and applying custom config path..."
cat <<EOF >~/.bashrc
# Starship
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "\$(starship init bash)"

EOF

echo "Cloning custom scripts from GitHub gists..."

echo "  sshot"
gh gist clone https://gist.github.com/paulo-granthon/582d7ef3e532284782132f0f702a8669 "$HOME"/.local/bin/sshot
chmod +x ~/.local/bin/sshot

echo "  colwatch"
gh gist clone https://gist.github.com/paulo-granthon/07e22d1f7f5ff158fac0645733d1f8b1 "$HOME"/.local/bin/colwatch
chmod +x ~/.local/bin/colwatch

echo "Cloning and setting up gitsync..."
git clone https://github.com/paulo-granthon/gitsync "$HOME"/.local/bin/gitsync_temp
mv "$HOME"/.local/bin/gitsync_temp/gitsync.sh "$HOME"/.local/bin/gitsync
rm -rf "$HOME"/.local/bin/gitsync_temp/
chmod +x ~/.local/bin/gitsync

echo "Creating vpn related scripts in \`~/.local/bin\`"
cat <<EOF >~/.local/bin/vpn_start
#!/bin/bash
sudo echo "starting awsvpnclient.service..."
sudo systemctl start awsvpnclient.service &&
sudo systemctl status awsvpnclient.service
EOF

cat <<EOF >~/.local/bin/vpn_kill
#!/bin/bash
sudo echo "stopping awsvpnclient.service..."
sudo systemctl stop awsvpnclient.service
sudo systemctl status awsvpnclient.service
EOF

chmod +x ~/.local/bin/vpn_start
chmod +x ~/.local/bin/vpn_kill

echo "Scripts in \`~/.local/bin\`:"
ls -laL "$HOME"/.local/bin/

echo "Setting up Rust..."
rustup --version
rustup install stable
rustup default stable
rustc --version
cargo --version

prompt "Install Chrome?" && yay -S google-chrome --noconfirm

prompt "Set up gaming utilities? Lutris, Steam, Wine, Winetricks?" && sudo pacman -S wine winetricks lutris steam --noconfirm

echo "Making the dev directory..."
sudo mkdir /usr/dev/
sudo chown paulo:users "/usr/dev/"

cat <<EOF >~/.bashrc
export dev=/usr/dev

EOF

echo "Done!"
