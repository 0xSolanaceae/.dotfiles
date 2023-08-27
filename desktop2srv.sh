sudo apt install ubuntu-server
reboot
sudo systemctl set-default multi-user.target
reboot
sudo apt purge ubuntu-desktop -y && sudo apt autoremove -y && sudo apt autoclean
reboot