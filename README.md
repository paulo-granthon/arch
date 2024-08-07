# Arch

Automated Arch Linux post installation routine.

## How to use

1. Curl the script file directly and execute it

    ```bash
    curl -sL https://raw.githubusercontent.com/paulo-granthon/arch/main/install.sh | bash
    ```

2. Clone the repository and execute the script

    ```bash
    git clone
    cd arch
    chmod +x install.sh
    ./install.sh
    rm -rf arch # remove the repository after the script is executed
    ```

3. Download the script and execute it

    ```bash
    wget https://raw.githubusercontent.com/paulo-granthon/arch/main/install.sh
    chmod +x arch.sh
    ./arch.sh
    rm arch.sh # remove the script after it's executed
    ```

## What it does

- Installs my essential packages
- Sets up the github-cli and calls `gh auth login`
- Clones my dot-files for [NeoVim](https://github.com/paulo-granthon/nvim), [Alacritty](https://github.com/paulo-granthon/alacritty) and [AwesomeWM](https://github.com/paulo-granthon/awesomewm)
- Allows me to choose between my custom themes for `AwesomeWM` through the terminal
- Prompts for some optional packages installation

## Why?

Those configs are built with time. It's good to have a way to get back on track if something happens to the hardware
