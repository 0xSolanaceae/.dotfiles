#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

read -p "Do you want to install Tailscale? (y/n): " install_tailscale
read -p "Do you want to install Vagrant? (y/n): " install_vagrant
read -p "Do you want to install Drivers? (y/n): " install_drivers

sudo apt install nala -y
sudo nala fetch

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

sudo nala install ufw -y
# Allow specific ports
# sudo ufw allow 'Nginx Full'
# sudo ufw allow 'OpenSSH'
sudo ufw enable

sudo nala install -y apparmor apparmor-utils
sudo aa-enforce /etc/apparmor.d/*
sudo systemctl restart apparmor

echo "------------------------------------------------------------------------------------------"
echo "[+] Package install..."
echo "------------------------------------------------------------------------------------------"

sudo nala update
sudo nala upgrade -y
sudo nala autoremove

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
    ca-certificates
    software-properties-common
    mokutil
    build-essential
    gcc
    libelf-dev
    speedtest-cli
    dkms
    neofetch
    screenfetch
    zsh
    bat
    exa
)

mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat

# Install required packages
for package in "${packages[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        echo "[+] $package is not installed. Installing..."
        sudo nala install -y "$package"
    fi
done

if ! command -v btop >/dev/null 2>&1; then
    echo "[+] Btop is not installed. Installing..."
    sudo nala install -y btop
fi

# install brew
if ! command -v brew >/dev/null 2>&1; then
    echo "[+] Homebrew is not installed. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/camus/.bashrc
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/camus/.zshrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Add Docker's official GPG key:
sudo apt-get update
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# install gping
brew install gping
# install fzf
brew install fzf
# install ripgrep
brew install ripgrep
# install cbonsai
brew install cbonsai
# install yazi
brew install yazi
# install zsh-autosuggestions
brew install zsh-autosuggestions
# install micro  
# ctrl-e | set colorscheme twilight
brew install micro
# install macchina (neofetch replacement)
brew install macchina

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Install Oh-My-Zsh and configure it
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[+] Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

sed -i 's/ZSH_THEME=".*"/ZSH_THEME="nanotech"/' ~/.zshrc

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

if ! grep -q "zsh-syntax-highlighting" "$HOME/.zshrc"; then
    echo "Adding zsh-syntax-highlighting to .zshrc plugins..."
    echo 'plugins+=(zsh-syntax-highlighting)' >> "$HOME/.zshrc"
else
    echo "zsh-syntax-highlighting is already present in .zshrc plugins."
fi

CONFIGURATIONS=$(cat <<EOF
function yy() {
    local tmp="\$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "\$@" --cwd-file="\$tmp"
    if cwd="\$(cat -- "\$tmp")" && [ -n "\$cwd" ] && [ "\$cwd" != "\$PWD" ]; then
        cd -- "\$cwd"
    fi
    rm -f -- "\$tmp"
}

export PATH="\$PATH:/home/camus/.local/bin"
eval "\$(zoxide init zsh)"
alias ls='exa'
alias cat='bat'
alias cd='z'
alias cdi='zi'
alias cls='clear'
alias dir='exa'
alias nano='micro'
alias neofetch='macchina'
alias ping='gping'
EOF
)

echo "$CONFIGURATIONS" >> ~/.zshrc

echo "Configurations added to ~/.zshrc"
echo "Oh My Zsh configuration completed."

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

    if ! command -v 8814au >/dev/null 2>&1; then
        git clone https://github.com/morrownr/8814au.git
        cd "8814au"
        sudo ./install-driver.sh
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
source ~/.zshrc

echo "------------------------------------------------------------------------------------------"
echo "[+] Completed; Installed required packages and configured settings."
echo "------------------------------------------------------------------------------------------"

# https://linuxconfig.org/how-to-change-welcome-message-motd-on-ubuntu-18-04-server
####  https://www.tecmint.com/ssh-warning-banner-linux/
