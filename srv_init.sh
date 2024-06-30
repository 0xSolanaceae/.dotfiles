#!/bin/bash
# shellcheck disable=SC2016

clear
echo -e "\e[0m\c"
set -e

export PATH=/usr/sbin:$PATH
export DEBIAN_FRONTEND=noninteractive

((EUID)) && sudo_cmd="sudo"

readonly COLOUR_RESET='\e[0m'
readonly aCOLOUR=(
    '\e[38;5;154m' # green
    '\e[1m'        # Bold white
    '\e[90m'       # Grey
    '\e[91m'       # Red
    '\e[33m'       # Yellow
)

print_green() {
    echo -e "${aCOLOUR[0]}$1${COLOUR_RESET}"
}

print_bold() {
    echo -e "${aCOLOUR[1]}$1${COLOUR_RESET}"
}

print_grey() {
    echo -e "${aCOLOUR[2]}$1${COLOUR_RESET}"
}

print_alert() {
    echo -e "${aCOLOUR[3]}$1${COLOUR_RESET}"
}

print_emphasis() {
    echo -e "${aCOLOUR[4]}$1${COLOUR_RESET}"
}

# User prompts
print_emphasis "Do you want to install Nvidia Drivers? (y/n): "
read -r install_nvidia_drivers

print_emphasis "Do you want to install Network Adapter Drivers? (y/n): "
read -r install_drivers

print_emphasis "Do you want to fetch the closest repo mirrors? (y/n): "
read -r fetch_mirror

# System update
print_green "─────────────────────────────────────────────────────"
print_bold "[+] Updating system..."
print_green "─────────────────────────────────────────────────────"
print_grey "$(${sudo_cmd} apt-get update && ${sudo_cmd} apt-get upgrade -y)"
print_grey "$(${sudo_cmd} apt install nala -y)"

if [ "$fetch_mirror" = "y" ]; then
    print_bold "[+] Fetching closest mirrors..."
    ${sudo_cmd} nala fetch
fi

# Package installation
print_green "─────────────────────────────────────────────────────"
print_bold "[+] Installing packages..."
print_green "─────────────────────────────────────────────────────"
print_grey "${sudo_cmd} nala update && ${sudo_cmd} nala upgrade -y"

print_grey "Installing: git, nmap, python3, curl, cmake, cargo, wget, etc..."
${sudo_cmd} nala install -y \
    git \
    nmap \
    python3 \
    python3-pip \
    curl \
    cmake \
    cargo \
    wget \
    net-tools \
    openssh-server \
    apache2 \
    ca-certificates \
    software-properties-common \
    mokutil \
    build-essential \
    gcc \
    libelf-dev \
    lynx \
    speedtest-cli \
    dkms \
    screenfetch \
    zsh \
    bat \
    fd-find \
    btop

print_grey "${sudo_cmd} nala autoremove -y"
print_grey "${sudo_cmd} apt clean"

print_bold "[+] Creating symbolic links..."
mkdir -p ~/.local/bin

if [ ! -L ~/.local/bin/bat ]; then
    ln -s /usr/bin/batcat ~/.local/bin/bat
    echo "Symbolic link created for bat."
else
    echo "Symbolic link already exists, skipping."
fi

# Rust installation
print_green "─────────────────────────────────────────────────────"
print_bold "[+] Installing Rust..."
print_green "─────────────────────────────────────────────────────"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Treefetch installation
print_bold "[+] Installing Treefetch..."
if [ -d "/usr/bin/treefetch" ]; then
  echo "Treefetch is already installed. Skipping installation."
else
  cd /usr/bin/ || exit

  ${sudo_cmd} git clone https://github.com/angelofallars/treefetch.git

  cd treefetch || exit

  ${sudo_cmd} cargo install --git https://github.com/angelofallars/treefetch

  cd ~ || exit
fi

print_bold "[+] Installing additional tools..."

cargo install thokr
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Homebrew installation
if ! command -v brew >/dev/null 2>&1; then
    print_bold "[+] Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> "$HOME/.bashrc"
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> "$HOME/.zshrc"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Docker installation
if command -v docker &> /dev/null; then
    print_bold "[!] Docker is already installed. Skipping installation."
else
    print_green "─────────────────────────────────────────────────────"
    print_bold "[+] Installing Docker..."
    print_green "─────────────────────────────────────────────────────"
    print_grey "${sudo_cmd} nala update -y"
    ${sudo_cmd} install -m 0755 -d /etc/apt/keyrings
    print_grey "${sudo_cmd} curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc"
    ${sudo_cmd} chmod a+r /etc/apt/keyrings/docker.asc

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    ${sudo_cmd} tee /etc/apt/sources.list.d/docker.list > /dev/null
    ${sudo_cmd} apt-get update

    print_grey "${sudo_cmd} nala install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin"
fi

# Brew packages installation
print_green "─────────────────────────────────────────────────────"
print_bold "[+] Installing Brew packages..."
print_green "─────────────────────────────────────────────────────"
print_grey "Installing: gping, fzf, ripgrep, cbonsai, yazi, zsh-autosuggestions, micro, macchina, eza, bottom, fastfetch"
brew install gping fzf ripgrep cbonsai yazi zsh-autosuggestions micro macchina eza bottom fastfetch

# Oh-My-Zsh installation and configuration
print_green "─────────────────────────────────────────────────────"
print_bold "[+] Setting up Oh-My-Zsh..."
print_green "─────────────────────────────────────────────────────"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_bold "[+] Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

sed -i 's/ZSH_THEME=".*"/ZSH_THEME="nanotech"/' ~/.zshrc

ZSH_CUSTOM="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"
ZSH_HIGHLIGHT_DIR="${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

if [ -d "$ZSH_HIGHLIGHT_DIR" ]; then
  echo "zsh-syntax-highlighting is already installed. Continuing..."
else
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_HIGHLIGHT_DIR"
fi

if ! grep -q "zsh-syntax-highlighting" "$HOME/.zshrc"; then
    print_bold "[+] Adding zsh-syntax-highlighting to .zshrc plugins..."
    echo 'plugins+=(zsh-syntax-highlighting)' >> "$HOME/.zshrc"
else
    print_grey "[-] zsh-syntax-highlighting is already present in .zshrc plugins."
fi

print_bold "[+] Adding configurations to ~/.zshrc..."

# Driver installations
if [ "$install_nvidia_drivers" = "y" ]; then
    print_green "─────────────────────────────────────────────────────"
    print_bold "[+] Installing Nvidia drivers..."
    print_green "─────────────────────────────────────────────────────"
    ${sudo_cmd} ubuntu-drivers autoinstall
fi

if [ "$install_drivers" = "y" ]; then
    print_green "─────────────────────────────────────────────────────"
    print_bold "[+] Installing network adapter drivers..."
    print_green "─────────────────────────────────────────────────────"
fi

# Cleanup
print_green "─────────────────────────────────────────────────────"
print_bold "[+] Cleaning up..."
print_green "─────────────────────────────────────────────────────"
${sudo_cmd} apt-get clean
${sudo_cmd} apt-get autoremove -y

zsh
# shellcheck disable=SC1090
source ~/.zshrc

print_green "─────────────────────────────────────────────────────"
print_bold "[+] Installation and configuration completed."
print_bold "[!] Please run source ~/.zshrc to apply changes."
if [ "$install_drivers" = "y" ]; then
    print_alert "[!] Please restart your system to apply changes."
fi
print_green "─────────────────────────────────────────────────────"
