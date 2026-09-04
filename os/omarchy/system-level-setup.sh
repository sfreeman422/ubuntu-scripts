#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_omarchy

echo "========================================="
echo "Omarchy System Level Setup Starting..."
echo "========================================="

echo "📦 Installing baseline system packages..."
omarchy_install_packages curl jq git ffmpeg gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly
echo "✅ Baseline system packages installed successfully"
echo ""

echo "⏰ Configuring system time for dual boot compatibility..."
sudo timedatectl set-local-rtc 1 --adjust-system-clock
echo "✅ Time configuration updated for dual boot"
echo ""

echo "========================================="
echo "🎉 Omarchy System Level Setup Complete!"
echo "========================================="
echo ""
echo "📋 Summary of what was installed/configured:"
echo "   ✓ Baseline CLI packages"
echo "   ✓ Multimedia codec packages"
echo "   ✓ Time configured for dual boot (local RTC)"
echo "   ✓ Omarchy default shell/theme stack preserved"
echo ""
echo "💡 Recommendations:"
echo "   - Use 'omarchy update' for system updates"
echo ""
