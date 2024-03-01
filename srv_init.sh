#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Prompt for Tailscale installation
read -p "Do you want to install Tailscale? (y/n): " install_tailscale
# Prompt for Oh-My-Zsh installation
read -p "Do you want to install Oh-My-Zsh? (y/n): " install_ohmyzsh
# Prompt for Vagrant installation
read -p "Do you want to install Vagrant? (y/n): " install_vagrant
# Prompt for Driver installation
read -p "Do you want to install Drivers? (y/n): " install_drivers

sudo apt install nala -y
sudo nala fetch

# Update package lists and upgrade system
sudo nala update
sudo nala upgrade

# Configure firewall (UFW)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw enable

# Disable root login and password authentication for SSH
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Install and configure fail2ban
sudo nala install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Set up automatic security updates
sudo nala install -y unattended-upgrades
echo 'APT::Periodic::Update-Package-Lists "1";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades

# Install and set up a basic firewall (ufw)
sudo nala install ufw -y
# Allow specific ports for your hosted services, e.g., HTTP, HTTPS, etc.
# sudo ufw allow 'Nginx Full'
# sudo ufw allow 'OpenSSH'
sudo ufw enable

# Harden the system by installing and configuring AppArmor
sudo nala install -y apparmor apparmor-utils
sudo aa-enforce /etc/apparmor.d/*
sudo systemctl restart apparmor

echo "------------------------------------------------------------------------------------------"
echo "[+] Package install..."

# Update and clean the system
sudo nala update
sudo nala upgrade -y
sudo nala autoremove

# List of packages to install
packages=(
    git
    nmap
    python3
    python3-pip
    curl
    wget
    net-tools
    openssh-server
    nginx
    apache2
    fail2ban
    docker.io
    docker-compose
    nala-transport-https
    ca-certificates
    software-properties-common
    mokutil
    build-essential
    libelf-dev
    linux-headers-$(uname -r)
    dkms
    neofetch
    screenfetch
    zsh
    speedtest-cli
)

# Install required packages
for package in "${packages[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        echo "[+] $package is not installed. Installing..."
        sudo nala install -y "$package"
    fi
done

# sudo nala install git nmap python3 python3-pip curl wget net-tools openssh-server nginx apache2 fail2ban docker.io docker-compose apt-transport-https ca-certificates software-properties-common mokutil build-essential libelf-dev linux-headers-$(uname -r) dkms neofetch screenfetch zsh speedtest-cli

# install system monitoring resources
if ! command -v btop >/dev/null 2>&1; then
    echo "[+] Btop is not installed. Installing..."
    sudo nala install -y btop
fi

if ! command -v fff >/dev/null 2>&1; then
    echo "[+] FFF is not installed. Installing..."
    git clone https://github.com/dylanaraps/fff
    cd fff/
    sudo make install
    cd ..
    echo 'f() { fff "$@"; cd "$(cat "${XDG_CACHE_HOME:=${HOME}/.cache}/fff/.fff_d")"; }' >> ~/.zshrc

fi

if ! command -v glow >/dev/null 2>&1; then
    echo "[+] Glow is not installed. Installing..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo nala update
    sudo nala install -y glow
fi

if ! command -v neovim >/dev/null 2>&1; then
    echo "[+] Neovim is not installed. Installing..."
    sudo nala install -y neovim
fi

if [ "$install_tailscale" = "y" ]; then
    # Install Tailscale
    if ! command -v tailscale >/dev/null 2>&1; then
        echo "[+] Tailscale is not installed. Installing..."
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
        sudo nala update
        sudo nala install -y tailscale
        tailscale up --ssh
        # command to enable tailscale funnel
        # sudo tailscale serve https / http://localhost:8096
    fi
fi

if [ "$install_vagrant" = "y" ]; then
    # Install Vagrant
    if ! command -v vagrant >/dev/null 2>&1; then
        echo "[+] Vagrant is not installed. Installing..."
        sudo nala install -y virtualbox ruby-full
        wget https://releases.hashicorp.com/vagrant/2.2.9/vagrant_2.2.9_x86_64.deb
        sudo dpkg -i vagrant_2.2.9_x86_64.deb
        rm vagrant_2.2.9_x86_64.deb
    fi
fi

if [ "$install_drivers" = "y" ]; then
    # Install Drivers
    if ! command -v rtl8812au.git >/dev/null 2>&1; then
        git clone -b v5.6.4.2 https://github.com/aircrack-ng/rtl8812au.git
        cd rtl8812au
        sudo make dkms_install
        cd ..
    fi
fi

# qemu-kvm installation
sudo nala install qemu-kvm qemu-system qemu-utils libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager -y
sudo virsh net-start default
sudo virsh net-autostart default
sudo usermod -aG libvirt $USER
sudo usermod -aG libvirt-qemu $USER
sudo usermod -aG kvm $USER
sudo usermod -aG input $USER
sudo usermod -aG disk $USER

# Clean up and finalize
sudo apt-get clean
sudo apt-get autoremove -y

if [ "$install_ohmyzsh" = "y" ]; then
    # Install Oh-My-Zsh and configure it
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "[+] Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
fi

sed -i 's/ZSH_THEME=".*"/ZSH_THEME="cypher"/' ~/.zshrc
source ~/.zshrc
echo "Oh My Zsh configuration completed."

echo "------------------------------------------------------------------------------------------"
echo "[+] Completed; Installed required packages and configured settings."
echo "------------------------------------------------------------------------------------------"

# https://linuxconfig.org/how-to-change-welcome-message-motd-on-ubuntu-18-04-server
####  https://www.tecmint.com/ssh-warning-banner-linux/
