#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_omarchy

echo "========================================="
echo "Omarchy Gaming Environment Setup Starting..."
echo "========================================="

echo "🎮 Installing gaming packages..."
omarchy_install_packages lutris umu-launcher wine-staging wine-mono wine-gecko winetricks python-protobuf
echo "✅ Gaming packages installed successfully"
echo ""

echo "========================================="
echo "🎉 Omarchy Gaming Environment Setup Complete!"
echo "========================================="
echo ""
echo "📋 Gaming tools installed:"
echo "   ✓ Wine Staging - Windows compatibility layer"
echo "   ✓ Winetricks - Wine helper tooling"
echo "   ✓ Lutris - Gaming platform manager"
echo "   ✓ GE/UMU support packages for modern launchers"
echo ""
