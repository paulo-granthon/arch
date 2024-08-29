#!/bin/bash

RESET='\033[0m'
RED='\033[0;31m'

MOCK=false

for ((i = 1; i <= $#; i++)); do
    arg="${!i}"

    case $arg in
    -m | --mock)
        MOCK=true
        shift
        ;;
    *) echo "Unknown parameter passed: $1" && exit 1 ;;
    esac
    shift
done

function is_mock {
    if [[ "$MOCK" == "true" ]]; then
        return 0
    fi

    return 1
}

home_path=$HOME
pacman_install_command="S"
gh_auth_command="login"
pacman_uninstall_command="Runs"
starship_command="sh"

if is_mock; then
    echo -e "\n${RED}Mocking the installation process...${RESET}"
    home_path="/tmp"
    pacman_install_command="Ss"
    gh_auth_command="status"
    pacman_uninstall_command="Qs"
    starship_command="(read text; echo \"received \$(echo -n \"\${text}\" | wc -c) characters from request.\")"
fi

function prompt {
    read -rp "$1 [Y/n] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
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
    ts-node
    rustup
    lua
    luarocks
    luajit
    luacheck
    shellcheck
    python
    pylint
    go
    materia-gtk-theme
    ttf-hack-nerd
    eza
    dua-cli
    thunar
    cmus
    neofetch
    bpytop
    thefuck
    tldr
    scrot
    ripgrep
    xorg-xev
    man
)

echo -e "\nPackages to install:"
for package in "${packages[@]}"; do
    echo "  $package"
done

echo -e "\nUpdating keyrings and installing predefined packages..."
sudo pacman -"${pacman_install_command}"y --needed "${packages[@]}" --noconfirm

echo -e "\nConfiguring docker..."
sudo groupadd docker
sudo usermod -aG docker "${USER}"
newgrp docker
sudo chmod 666 /var/run/docker.sock
sudo systemctl enable docker
sudo systemctl start docker
docker run hello-world

echo -e "\nInstalling Starship Prompt..."
curl -sS https://starship.rs/install.sh | eval "${starship_command}"

neofetch

echo -e "\nRemoving nautilus..."
sudo pacman -"${pacman_uninstall_command}" nautilus --pretend

echo -e "\nSetting Materia-dark-compact as the gtk theme for the system..."
gtk_theme_set=$(awk 'NR==2{$0="gtk-theme-name=Materia-dark-compact"}1' "${home_path}"/.config/gtk-3.0/settings.ini) >tmpfile
sudo mv tmpfile "${home_path}"/.config/gtk-3.0/settings.ini
sudo rm tmpfile

gtk_config=$(
    cat <<EOF
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
)

if [[ "$gtk_theme_set" -eq 1 ]]; then
    sudo mkdir "${home_path}"/.config/gtk-3.0/
    echo "[Settings]" >"${home_path}"/.config/gtk-3.0/settings.ini
    echo "${gtk_config}" >>"${home_path}"/.config/gtk-3.0/settings.ini
fi

echo -e "\nStarting GitHub authentication..."
gh auth "${gh_auth_command}"

mkdir "${home_path}/.local/"
mkdir "${home_path}/.local/bin/"
mkdir "${home_path}/pics/"
mkdir "${home_path}/pics/screenshots/"

echo -e "\nInstalling yay"
sudo pacman -"${pacman_install_command}" --needed git base-devel --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay || exit
makepkg -si --noconfirm
cd .. || exit
rm -rf ./yay
cd || exit

echo -e "\nCloning configuration files for AwesomeWM from GitHub..."
git clone https://github.com/paulo-granthon/awesomewm "${home_path}"/.config/awesome

echo -e "\nGiving permissions to \`.config/awesome\` bash scripts..."
CUR_DIR=$(pwd)
cd "${home_path}"/.config/awesome && make && cd "$CUR_DIR" || exit

if prompt "Install Picom?"; then
    sudo pacman -"${pacman_install_command}" picom --noconfirm

    echo -e "\nCloning configuration files for Picom..."
    git clone https://github.com/paulo-granthon/picom "${home_path}"/.config/picom
fi

theme_dir="$home_path/.config/awesome/themes/"
theme_options=$(find "$theme_dir" | sed 's/\..*//')

read -rp "What theme do you want for AwesomeWM? [$theme_options] " response && response=${response:-Y} && response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
theme_file="$theme_dir$response.lua"

if [[ -e "$theme_file" ]]; then
    echo "THEME=$response" >"$home_path"/.config/awesome/theme.lua
    echo -e "\nTheme saved"
else
    echo -e "\nInvalid theme choice. Leaving default 'purple'."
fi

echo -e "\nRestarting AwesomeWM..."
echo 'awesome.restart()' | awesome-client

echo -e "\nCloning configuration files for Alacritty, NeoVim and Starship from GitHub..."
git clone https://github.com/paulo-granthon/alacritty "${home_path}"/.config/alacritty
git clone https://github.com/paulo-granthon/nvim "${home_path}"/.config/nvim
git clone https://github.com/paulo-granthon/starship "${home_path}"/.config/starship

bashrc_prefs=$(
    cat <<EOF
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
)

echo -e "\nSetting up preferences and fixes in \`.bashrc\`..."
echo "${bashrc_prefs}" >>"${home_path}"/.bashrc

bashrc_path=$(
    cat <<EOF
# PATH configuration
GO_PATH=\$(go env GOPATH)/bin
export PATH=\$PATH:"\$home_path/.local/bin"
export PATH=\$PATH:\$GO_PATH
export PATH=\$PATH:~/.dotnet/tools

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
shopt -s cdable_vars

EOF
)

echo -e "\nSetting up PATH configuration in \`.bashrc\`..."
echo "${bashrc_path}" >>"${home_path}"/.bashrc

bashrc_aliases=$(
    cat <<EOF
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
)

echo -e "\nSetting up custom aliases in \`.bashrc\`..."
echo "${bashrc_aliases}" >>"${home_path}"/.bashrc

bashrc_starship=$(
    cat <<EOF
# Starship
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "\$(starship init bash)"

EOF
)

echo -e "\nSetting up Starship in \`.bashrc\` and applying custom config path..."
echo "${bashrc_starship}" >>"${home_path}"/.bashrc

echo -e "\nCloning custom scripts from GitHub gists..."

echo "  sshot"
gh gist clone https://gist.github.com/paulo-granthon/582d7ef3e532284782132f0f702a8669 "${home_path}"/.local/bin/sshot_temp
mv "$home_path"/.local/bin/sshot_temp/sshot "${home_path}"/.local/bin/sshot
rm -rf "$home_path"/.local/bin/sshot_temp/
chmod +x "${home_path}"/.local/bin/sshot

echo "  colwatch"
gh gist clone https://gist.github.com/paulo-granthon/07e22d1f7f5ff158fac0645733d1f8b1 "${home_path}"/.local/bin/colwatch_temp
mv "$home_path"/.local/bin/colwatch_temp/colwatch.bash "${home_path}"/.local/bin/colwatch
rm -rf "$home_path"/.local/bin/colwatch_temp/
chmod +x "${home_path}"/.local/bin/colwatch

echo -e "\nCloning and setting up gitsync..."
git clone https://github.com/paulo-granthon/gitsync "${home_path}"/gitsync_temp
mv "$home_path"/.local/bin/gitsync_temp/gitsync.sh "${home_path}"/.local/bin/gitsync
rm -rf "$home_path"/.local/bin/gitsync_temp/
chmod +x "${home_path}"/.local/bin/gitsync

echo -e "\nCreating vpn related scripts in \`${home_path}/.local/bin\`"
cat <<EOF >"${home_path}"/.local/bin/vpn_start
#!/bin/bash
sudo echo "starting awsvpnclient.service..."
sudo systemctl start awsvpnclient.service &&
sudo systemctl status awsvpnclient.service
EOF

cat <<EOF >"${home_path}"/.local/bin/vpn_kill
#!/bin/bash
sudo echo "stopping awsvpnclient.service..."
sudo systemctl stop awsvpnclient.service
sudo systemctl status awsvpnclient.service
EOF

chmod +x "${home_path}"/.local/bin/vpn_start
chmod +x "${home_path}"/.local/bin/vpn_kill

echo -e "\nScripts in \`${home_path}/.local/bin\`:"
ls -laL "$home_path"/.local/bin/

echo -e "\nSetting up Rust..."
rustup --version
if ! is_mock; then
    rustup install stable
    rustup default stable
fi
rustc --version
cargo --version

prompt "Install Chrome?" && yay -"${pacman_install_command}" google-chrome --noconfirm

prompt "Set up gaming utilities? Lutris, Steam, Wine, Winetricks?" && sudo pacman -"${pacman_install_command}" wine winetricks lutris steam --noconfirm

echo -e "\nMaking the dev directory..."
if ! is_mock; then
    sudo mkdir /usr/dev/
    sudo chown paulo:users "/usr/dev/"
else
    sudo ls /usr/dev
fi

cat <<EOF >"${home_path}"/.bashrc
export dev=/usr/dev

EOF

echo -e "\nDone!"
