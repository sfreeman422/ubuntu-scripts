#!/bin/bash

# System Level Setup Script
# Supports: GNOME
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

# Source the GNOME environment library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
if [[ -f "$LIB_DIR/gnome-environment.sh" ]]; then
    source "$LIB_DIR/gnome-environment.sh"
else
    echo "❌ Error: required library '$LIB_DIR/gnome-environment.sh' not found." >&2
    echo "This setup script depends on functions defined in gnome-environment.sh and cannot continue safely." >&2
    exit 1
fi

echo "========================================="
echo "Ubuntu System Level Setup Starting..."
echo "========================================="

declare -A COMPONENT_RESULTS
COMPONENT_IDS=(system-update zsh htop codecs automatic-updates developer-fonts gtk-themes gnome-tweaks oh-my-zsh)
declare -A COMPONENT_LABELS=(
    [system-update]="System packages updated"
    [zsh]="ZSH shell"
    [htop]="htop system monitor"
    [codecs]="Multimedia codecs"
    [automatic-updates]="Automatic security updates"
    [developer-fonts]="Developer fonts (Fira Code, Powerline)"
    [gtk-themes]="GTK common themes"
    [gnome-tweaks]="GNOME Tweaks"
    [oh-my-zsh]="Oh My Zsh framework"
)

record_component_result() {
    COMPONENT_RESULTS["$1"]="$2"
}

install_system_package() {
    local component_id="$1"
    local label="$2"
    shift 2

    if sudo apt install -y "$@"; then
        record_component_result "$component_id" true
        echo "✅ $label installed successfully"
    else
        record_component_result "$component_id" false
        echo "⚠️  $label installation failed."
    fi
}

# Update and upgrade
echo "📦 Updating package lists and upgrading system packages..."
if sudo apt update && sudo apt upgrade -y; then
    record_component_result system-update true
    echo "✅ System packages updated successfully"
else
    record_component_result system-update false
    echo "⚠️  System package update or upgrade failed."
fi
echo ""

# Install ZSH
echo "🐚 Installing ZSH shell..."
install_system_package zsh "ZSH" zsh
echo ""

# install htop
echo "📊 Installing htop system monitor..."
install_system_package htop "htop" htop
echo ""

# Install multimedia codecs
echo "🎬 Installing Ubuntu restricted extras (multimedia codecs)..."
install_system_package codecs "Multimedia codecs" ubuntu-restricted-extras
echo ""

# Install unattended upgrades
echo "🔄 Setting up automatic security updates..."
if sudo apt install -y unattended-upgrades; then
    echo "📝 Configuring unattended upgrades (you may be prompted for settings)..."
    if sudo dpkg-reconfigure -plow unattended-upgrades; then
        record_component_result automatic-updates true
        echo "✅ Automatic updates configured successfully"
    else
        record_component_result automatic-updates false
        echo "⚠️  Automatic updates were installed but configuration failed."
    fi
else
    record_component_result automatic-updates false
    echo "⚠️  Automatic updates installation failed."
fi
echo ""

# Install fonts
echo "🔤 Installing developer fonts (Fira Code and Powerline)..."
install_system_package developer-fonts "Developer fonts" fonts-firacode fonts-powerline
echo ""

# Install/update GTK common themes
echo "🎨 Installing GTK common themes..."
install_system_package gtk-themes "GTK common themes" gtk-common-themes
echo ""

# Install GNOME Tweaks
if has_gnome; then
    echo "🧰 Installing GNOME Tweaks (gnome-tweaks)..."
    install_system_package gnome-tweaks "GNOME Tweaks" gnome-tweaks
else
    record_component_result gnome-tweaks false
    echo "⚠️  GNOME not detected. Skipping tweaks installation."
fi
echo ""

# Configure time for dual boot with Windows
echo "⏰ Configuring system time for dual boot compatibility..."
echo "   - Setting hardware clock to use local time (Windows compatibility)..."
sudo timedatectl set-local-rtc 1 --adjust-system-clock

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
else
    echo "⚠️  GNOME not detected. Skipping desktop-specific settings."
fi
echo ""

# Oh my ZSH
echo "🎨 Installing Oh My Zsh framework..."
echo "   Note: This will change your default shell and may open a new zsh session"
if wget -qO /tmp/oh-my-zsh-install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
    && sh /tmp/oh-my-zsh-install.sh; then
    record_component_result oh-my-zsh true
    echo "✅ Oh My Zsh installed successfully"
else
    record_component_result oh-my-zsh false
    echo "⚠️  Oh My Zsh installation failed."
fi
rm -f /tmp/oh-my-zsh-install.sh
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
for component_id in "${COMPONENT_IDS[@]}"; do
    if [[ "${COMPONENT_RESULTS[$component_id]:-false}" == "true" ]]; then
        echo "   ✓ ${COMPONENT_LABELS[$component_id]}"
    else
        echo "   ⚠️  ${COMPONENT_LABELS[$component_id]} - installation failed or skipped"
    fi
done

if [[ "$de" == "gnome" ]]; then
    echo "   ✓ GNOME desktop settings optimized"
fi

echo "   ✓ Time configured for dual boot (local RTC)"
echo "   ✓ Useful shell aliases"
echo ""
echo "💡 Recommendations:"
echo "   - Restart your terminal to use the new zsh shell"
echo "   - Log out and back in to see font changes"
echo "   - Use 'uar' command for quick system updates"
echo ""