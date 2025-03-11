#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
    rm -rf "${TMP_DIR:-}"
    exit
}

init_script() {
    clear
    readonly COLOUR_RESET=$(tput sgr0)
    readonly COLOURS=(
        "$(tput setaf 2)"  # Green
        "$(tput bold)"      # Bold
        "$(tput setaf 7)"   # White
        "$(tput setaf 1)"   # Red
        "$(tput setaf 3)"   # Yellow
    )
    
    TMP_DIR=$(mktemp -d)
    export DEBIAN_FRONTEND=noninteractive
    check_sudo
}

check_sudo() {
    if ((EUID)) && ! sudo -n true 2>/dev/null; then
        print_alert "This script requires root privileges. Please enter your password:"
        sudo -v
    fi
}

print_green()  { echo -e "${COLOURS[0]}${1}${COLOUR_RESET}"; }
print_bold()   { echo -e "${COLOURS[1]}${1}${COLOUR_RESET}"; }
print_grey()   { echo -e "${COLOURS[2]}${1}${COLOUR_RESET}"; }
print_alert()  { echo -e "${COLOURS[3]}${1}${COLOUR_RESET}"; }
print_yellow() { echo -e "${COLOURS[4]}${1}${COLOUR_RESET}"; }

confirm() {
    local prompt="$1"
    while true; do
        print_yellow "${prompt} [y/n]: "
        read -r response
        case "${response}" in
            [yY]) return 0 ;;
            [nN]) return 1 ;;
            *) print_alert "Invalid input. Please enter y or n." ;;
        esac
    done
}

system_update() {
    print_green "─────────────────────────────────────────────────────"
    print_bold "[+] Updating system packages..."
    print_green "─────────────────────────────────────────────────────"
    sudo nala update
    sudo nala upgrade
    sudo nala full-upgrade
}

install_base_packages() {
    print_green "─────────────────────────────────────────────────────"
    print_bold "[+] Installing base packages..."
    print_green "─────────────────────────────────────────────────────"
    
    sudo nala install -y \
        git nmap python3 python3-pip curl cmake cargo wget \
        net-tools openssh-server apache2 ca-certificates \
        software-properties-common mokutil build-essential \
        gcc libelf-dev lynx speedtest-cli dkms screenfetch \
        zsh bat fd-find btop micro \
        zoxide ripgrep gping eza pipx
    
    sudo nala autoremove -y
    sudo apt clean

    pipx install poetry --quiet

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo >> "$HOME/.zshrc"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

    brew install zsh-autosuggestions gcc
    sed -i 's|$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh|/home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh|' ~/.zshrc
}

configure_bat() {
    local bat_path="/usr/bin/batcat"
    local symlink_path="${HOME}/.local/bin/bat"
    
    if [ ! -L "${symlink_path}" ] && [ -f "${bat_path}" ]; then
        mkdir -p ~/.local/bin
        ln -sf "${bat_path}" "${symlink_path}"
        print_green "Created bat symlink"
    fi
}

install_nala() {
    if ! command -v nala &> /dev/null; then
        print_green "─────────────────────────────────────────────────────"
        print_bold "[+] Installing Nala..."
        print_green "─────────────────────────────────────────────────────"
        
        sudo apt update
        sudo apt install -y nala
    fi
}

install_rust() {
    if ! command -v rustc &> /dev/null; then
        print_green "─────────────────────────────────────────────────────"
        print_bold "[+] Installing Rust..."
        print_green "─────────────────────────────────────────────────────"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "${HOME}/.cargo/env"
    fi
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        print_green "─────────────────────────────────────────────────────"
        print_bold "[+] Installing Docker..."
        print_green "─────────────────────────────────────────────────────"
        
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo nala update
        sudo nala install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker "${USER}"
    fi
}

configure_zsh() {
    print_green "─────────────────────────────────────────────────────"
    print_bold "[+] Configuring ZSH..."
    print_green "─────────────────────────────────────────────────────"
    
    if [ ! -d "${HOME}/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    local zshrc="${HOME}/.zshrc"
    local zsh_custom="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
    
    clone_repo "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "${zsh_custom}/plugins/zsh-syntax-highlighting"
    
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="nanotech"/' "${zshrc}"
    
    local configs=(
        'alias ls="eza"'
        'alias ll="eza -alh"'
        'alias tree="eza --tree"'
        'alias cat="bat"'
        'alias cd="z"'
        'alias cdi="zi"'
        'alias cls="clear"'
        'alias dir="eza"'
        'alias nano="micro"'
        'alias neofetch="macchina"'
        'alias ping="gping"'
        'alias grep="rg"'
        'alias fd="find"'
        'alias here="explorer.exe ."'
        'eval "$(zoxide init zsh)"'
        'source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"'
        'treefetch'
        'export PATH="$HOME/.cargo/bin:$PATH"'
        'export PATH="$HOME/.local/bin:$PATH"'
    )
    
    for config in "${configs[@]}"; do
        if ! grep -qF "${config}" "${zshrc}"; then
            echo "${config}" >> "${zshrc}"
        fi
    done
}

clone_repo() {
    local repo_url="$1"
    local target_dir="$2"
    
    if [ ! -d "${target_dir}" ]; then
        git clone --depth 1 "${repo_url}" "${target_dir}"
    fi
}

main() {
    init_script
    
    install_nala
    system_update
    
    if confirm "Fetch closest repository mirrors"; then
        sudo nala fetch
    fi
    
    install_base_packages
    configure_bat
    
    if confirm "Install Nvidia drivers"; then
        sudo ubuntu-drivers autoinstall
    fi
    
    install_rust
    install_docker
    configure_zsh

    cargo install --git https://github.com/angelofallars/treefetch
    
    print_green "─────────────────────────────────────────────────────"
    print_bold "[+] Cleanup and final configuration..."
    print_green "─────────────────────────────────────────────────────"
    
    if command -v zsh &> /dev/null && [ "$SHELL" != "$(command -v zsh)" ]; then
        sudo chsh -s "$(command -v zsh)" "${USER}"
        print_green "Default shell changed to ZSH"
    fi
    
    print_green "Script completed successfully!"
    print_yellow "Note: Some changes may require a system restart"
}

main