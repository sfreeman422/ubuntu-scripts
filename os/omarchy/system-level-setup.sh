#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_omarchy

echo "========================================="
echo "Omarchy System Level Setup Starting..."
echo "========================================="

echo "📦 Installing baseline system packages..."
omarchy_install_packages zsh htop curl jq git ttf-fira-code powerline-fonts ffmpeg gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly
echo "✅ Baseline system packages installed successfully"
echo ""

echo "⏰ Configuring system time for dual boot compatibility..."
sudo timedatectl set-local-rtc 1 --adjust-system-clock
echo "✅ Time configuration updated for dual boot"
echo ""

echo "🎨 Installing Oh My Zsh framework..."
if install_oh_my_zsh_if_missing; then
    echo "✅ Oh My Zsh installed successfully"
else
    echo "❌ Oh My Zsh installation failed"
    exit 1
fi
echo ""

echo "⚡ Adding useful shell aliases..."
append_line_once "$HOME/.zshrc" 'alias uar="omarchy update"'
echo "✅ Shell aliases added successfully"
echo ""

echo "========================================="
echo "🎉 Omarchy System Level Setup Complete!"
echo "========================================="
echo ""
echo "📋 Summary of what was installed/configured:"
echo "   ✓ Baseline shell and CLI packages"
echo "   ✓ Developer fonts (Fira Code, Powerline)"
echo "   ✓ Multimedia codec packages"
echo "   ✓ Time configured for dual boot (local RTC)"
echo "   ✓ Oh My Zsh framework"
echo "   ✓ Useful shell aliases"
echo ""
echo "💡 Recommendations:"
echo "   - Restart your terminal to use the new zsh shell"
echo "   - Use 'uar' to run Omarchy-managed system updates"
echo ""
