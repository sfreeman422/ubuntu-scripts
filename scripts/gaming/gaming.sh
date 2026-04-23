#!/bin/bash

# Gaming Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"
if [[ -f "$LIB_DIR/ubuntu-release.sh" ]]; then
	# shellcheck disable=SC1091
	source "$LIB_DIR/ubuntu-release.sh"
fi

UBUNTU_CODENAME_VALUE="$(get_ubuntu_codename 2>/dev/null || echo "unknown")"
WINEHQ_CODENAME="$(get_winehq_codename "$UBUNTU_CODENAME_VALUE" 2>/dev/null || echo "noble")"

echo "========================================="
echo "Gaming Environment Setup Starting..."
echo "========================================="

# Add 32-bit architecture for Wine compatibility
echo "🏗️  Setting up 32-bit architecture support..."
sudo dpkg --add-architecture i386 
echo "✅ 32-bit architecture added successfully"
echo ""

# Set up Wine repository
echo "🍷 Installing Wine Windows compatibility layer..."
echo "   - Creating keyrings directory..."
sudo mkdir -pm755 /etc/apt/keyrings
echo "   - Adding Wine repository key..."
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
echo "   - Adding Wine repository sources..."
if [[ "$WINEHQ_CODENAME" != "$UBUNTU_CODENAME_VALUE" ]]; then
	echo "   - WineHQ source for '${UBUNTU_CODENAME_VALUE}' not found; using '${WINEHQ_CODENAME}'"
fi
sudo wget -NP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/${WINEHQ_CODENAME}/winehq-${WINEHQ_CODENAME}.sources"

echo "   - Updating package lists..."
sudo apt update 
echo "   - Installing Wine stable version..."
sudo apt install --install-recommends winehq-stable -y
echo "✅ Wine installed successfully"
echo ""

# Download the latest Lutris package from https://github.com/lutris/lutris/releases
# The command below references Lutris version v0.5.18 as an example; please verify you are installing the latest version:
echo "🎮 Installing Lutris gaming platform..."
echo "   - Downloading Lutris package..."
wget -O ~/Downloads/lutris_0.5.18_all.deb https://github.com/lutris/lutris/releases/download/v0.5.18/lutris_0.5.18_all.deb
echo "   - Installing Lutris package..."
sudo dpkg -i ~/Downloads/lutris_0.5.18_all.deb
echo "   - Fixing any dependency issues..."
sudo apt install --fix-broken -y
echo "✅ Lutris installed successfully"
echo ""

echo "========================================="
echo "🎉 Gaming Environment Setup Complete!"
echo "========================================="
echo ""
echo "📋 Gaming tools installed:"
echo "   ✓ Wine - Windows compatibility layer"
echo "   ✓ 32-bit architecture support"
echo "   ✓ Lutris - Gaming platform manager"
echo ""
echo "💡 Next steps:"
echo "   - Launch Lutris from applications menu"
echo "   - Configure Wine using 'winecfg' command"
echo "   - Install games through Lutris or Steam"
echo "   - Consider installing additional Wine dependencies as needed"
echo ""