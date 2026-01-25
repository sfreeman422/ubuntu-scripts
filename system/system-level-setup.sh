#!/bin/bash

# System Level Setup Script
# Supports: GNOME, XFCE
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

# Source the desktop environment library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
if [[ -f "$LIB_DIR/desktop-environment.sh" ]]; then
    source "$LIB_DIR/desktop-environment.sh"
else
    echo "⚠️  Warning: desktop-environment.sh not found. Some features may be limited."
fi

echo "========================================="
echo "Ubuntu System Level Setup Starting..."
echo "========================================="

# Update and upgrade
echo "📦 Updating package lists and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

echo "✅ System packages updated successfully"
echo ""

# Install ZSH
echo "🐚 Installing ZSH shell..."
sudo apt install zsh -y

echo "✅ ZSH installed successfully"
echo ""

# install htop
echo "📊 Installing htop system monitor..."
sudo apt install -y htop

echo "✅ htop installed successfully"
echo ""

# Install multimedia codecs
echo "🎬 Installing Ubuntu restricted extras (multimedia codecs)..."
sudo apt install ubuntu-restricted-extras -y

echo "✅ Multimedia codecs installed successfully"
echo ""

# Install unattended upgrades
echo "🔄 Setting up automatic security updates..."
sudo apt install unattended-upgrades -y
echo "📝 Configuring unattended upgrades (you may be prompted for settings)..."
sudo dpkg-reconfigure -plow unattended-upgrades

echo "✅ Automatic updates configured successfully"
echo ""

# Install fonts
echo "🔤 Installing developer fonts (Fira Code and Powerline)..."
sudo apt install -y fonts-firacode fonts-powerline

echo "✅ Developer fonts installed successfully"
echo ""

# Install/update GTK common themes
echo "🎨 Installing GTK common themes..."
sudo apt install -y gtk-common-themes

echo "✅ GTK common themes installed successfully"
echo ""

# Install GNOME Tweaks (GNOME only) and XFCE Tweaks (XFCE only)
if has_gnome; then
    echo "🧰 Installing GNOME Tweaks (gnome-tweaks)..."
    sudo apt install -y gnome-tweaks
    echo "✅ GNOME Tweaks installed successfully"
elif has_xfce; then
    echo "🧰 Installing XFCE Tweaks..."
    sudo apt install -y xfce4-tweaks-plugin
    echo "✅ XFCE Tweaks installed successfully"
else
    echo "⚠️  Desktop environment not detected. Skipping tweaks installation."
fi
echo ""

# Configure time for dual boot with Windows
echo "⏰ Configuring system time for dual boot compatibility..."
echo "   - Setting hardware clock to use local time (Windows compatibility)..."
sudo timedatectl set-local-rtc 1 --adjust-system-clock
timedatectl set-local-rtc 1

echo "✅ Time configuration updated for dual boot"
echo ""

# Desktop environment specific settings
de=$(detect_desktop_environment 2>/dev/null || echo "unknown")

if [[ "$de" == "gnome" ]]; then
    echo "🖥️  Configuring GNOME desktop settings..."
    echo "   - Hiding desktop icons..."
    gnome-extensions disable ding@rastersoft.com 2>/dev/null || true

    # Enable minimize on click for the dock
    echo "   - Enabling minimize on click for dock..."
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize' 2>/dev/null || true

    echo "✅ GNOME desktop settings configured successfully"
elif [[ "$de" == "xfce" ]]; then
    echo "🖥️  Configuring XFCE desktop settings..."
    echo "   - Setting desktop icon size and behavior..."
    
    # Hide desktop icons if desired
    xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-thumbnails -s false 2>/dev/null || true
    
    # Set window manager to automatically move windows when requested
    xfconf-query -c xfwm4 -p /general/move_opacity -s 100 2>/dev/null || true
    
    echo "✅ XFCE desktop settings configured successfully"
else
    echo "⚠️  Desktop environment not detected. Skipping desktop-specific settings."
fi
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
if ! grep -q 'alias uar=' ~/.zshrc 2>/dev/null; then
    echo 'alias uar="sudo apt update && sudo apt upgrade && sudo apt autoremove -y"' >> ~/.zshrc
    echo "✅ Shell aliases added successfully"
else
    echo "✅ Shell aliases already present"
fi
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
echo "   ✓ GTK common themes updated"

if [[ "$de" == "gnome" ]]; then
    echo "   ✓ GNOME Tweaks installed"
    echo "   ✓ GNOME desktop settings optimized"
elif [[ "$de" == "xfce" ]]; then
    echo "   ✓ XFCE Tweaks installed"
    echo "   ✓ XFCE desktop settings optimized"
fi

echo "   ✓ Time configured for dual boot (local RTC)"
echo "   ✓ Oh My Zsh framework"
echo "   ✓ Useful shell aliases"
echo ""
echo "💡 Recommendations:"
echo "   - Restart your terminal to use the new zsh shell"
echo "   - Log out and back in to see font changes"
echo "   - Use 'uar' command for quick system updates"
echo ""