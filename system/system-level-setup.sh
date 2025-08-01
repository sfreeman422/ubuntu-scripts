#!/bin/bash

# System Level Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

echo "========================================="
echo "Ubuntu System Level Setup Starting..."
echo "========================================="

# Update and upgrade
echo "📦 Updating package lists and upgrading system packages..."
sudo apt update && sudo apt upgrade

echo "✅ System packages updated successfully"
echo ""

# Install ZSH
echo "🐚 Installing ZSH shell..."
sudo apt install zsh -y

echo "✅ ZSH installed successfully"
echo ""

# install htop
echo "📊 Installing htop system monitor..."
sudo snap install htop

echo "✅ htop installed successfully"
echo ""

# Install multimedia codecs
echo "🎬 Installing Ubuntu restricted extras (multimedia codecs)..."
sudo apt install ubuntu-restricted-extras

echo "✅ Multimedia codecs installed successfully"
echo ""

# Install unattended upgrades
echo "🔄 Setting up automatic security updates..."
sudo apt install unattended-upgrades
echo "📝 Configuring unattended upgrades (you may be prompted for settings)..."
sudo dpkg-reconfigure -plow unattended-upgrades

echo "✅ Automatic updates configured successfully"
echo ""

# Install fonts
echo "🔤 Installing developer fonts (Fira Code and Powerline)..."
sudo apt install -y fonts-firacode fonts-powerline

echo "✅ Developer fonts installed successfully"
echo ""

# Hide desktop icons
echo "🖥️  Configuring GNOME desktop settings..."
echo "   - Hiding desktop icons..."
gnome-extensions disable ding@rastersoft.com

# Enable minimize on click for the dock
echo "   - Enabling minimize on click for dock..."
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'

echo "✅ Desktop settings configured successfully"
echo ""

# Oh my ZSH
echo "🎨 Installing Oh My Zsh framework..."
echo "   Note: This will change your default shell and may open a new zsh session"
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

echo "✅ Oh My Zsh installed successfully"
echo ""

# Update alias
echo "⚡ Adding useful shell aliases..."
echo "   - Adding 'uar' alias for update/upgrade/autoremove..."
echo 'alias uar="sudo apt update && sudo apt upgrade && sudo apt autoremove"' >> ~/.zshrc

echo "✅ Shell aliases added successfully"
echo ""

echo "========================================="
echo "🎉 System Level Setup Complete!"
echo "========================================="
echo ""
echo "📋 Summary of what was installed/configured:"
echo "   ✓ System packages updated"
echo "   ✓ ZSH shell installed"
echo "   ✓ htop system monitor"
echo "   ✓ Multimedia codecs"
echo "   ✓ Automatic security updates"
echo "   ✓ Developer fonts (Fira Code, Powerline)"
echo "   ✓ Desktop settings optimized"
echo "   ✓ Oh My Zsh framework"
echo "   ✓ Useful shell aliases"
echo ""
echo "💡 Recommendations:"
echo "   - Restart your terminal to use the new zsh shell"
echo "   - Log out and back in to see font changes"
echo "   - Use 'uar' command for quick system updates"
echo ""