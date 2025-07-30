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

# Oh my ZSH
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

