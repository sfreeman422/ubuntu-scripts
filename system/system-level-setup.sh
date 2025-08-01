# Update and upgrade
sudo apt update && sudo apt upgrade

# Install ZSH
sudo apt install zsh -y
# install htop
sudo snap install htop
sudo apt install ubuntu-restricted-extras

# Install unattended upgrades
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Install fonts
sudo apt install -y fonts-firacode fonts-powerline

# Hide desktop icons
gnome-extensions disable ding@rastersoft.com

# Enable minimize on click for the dock
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'

# Oh my ZSH
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# Update alias
echo 'alias uar="sudo apt update && sudo apt upgrade && sudo apt autoremove"' >> ~/.zshrc