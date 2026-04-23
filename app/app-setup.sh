#!/bin/bash

# Application Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
if [[ -f "$LIB_DIR/ubuntu-release.sh" ]]; then
	# shellcheck disable=SC1091
	source "$LIB_DIR/ubuntu-release.sh"
fi

UBUNTU_CODENAME_VALUE="$(get_ubuntu_codename 2>/dev/null || echo "unknown")"

install_discord() {
	if apt-cache show discord >/dev/null 2>&1; then
		echo "   - Installing Discord via apt..."
		sudo apt install -y discord
		echo "✅ Discord installed successfully (apt)"
		return 0
	fi

	if command -v snap >/dev/null 2>&1; then
		echo "   - Discord apt package unavailable; installing via snap..."
		sudo snap install discord
		echo "✅ Discord installed successfully (snap)"
		return 0
	fi

	echo "⚠️  Discord is not available via apt and snap is not installed. Skipping Discord."
	return 1
}

echo "========================================="
echo "Application Setup Starting..."
echo "========================================="

# Install spotify and chromium
echo "📱 Installing core applications via apt..."
echo "   - Spotify (music streaming)"
echo "   - Chromium (web browser)"
sudo apt install -y spotify-client chromium-browser
echo "✅ Core applications installed successfully"
echo ""

# Install Discord with apt->snap fallback
echo "💬 Installing Discord..."
install_discord || true
echo ""

# Install Slack (direct .deb)
echo "💬 Installing Slack..."
echo "   - Downloading latest Slack package..."
if curl -fL -o ~/Downloads/slack-desktop-latest.deb https://downloads.slack-edge.com/desktop-releases/linux/x64/slack-desktop-latest-amd64.deb; then
	echo "   - Installing Slack package..."
	sudo apt install -y ~/Downloads/slack-desktop-latest.deb
	sudo apt install --fix-broken -y
	echo "✅ Slack installed successfully (.deb)"
elif command -v snap >/dev/null 2>&1; then
	echo "   - Slack .deb unavailable; installing Slack via snap..."
	sudo snap install slack
	echo "✅ Slack installed successfully (snap)"
else
	echo "⚠️  Slack download failed and snap is unavailable. Skipping Slack installation."
fi
echo ""

# Install steam
echo "🎮 Installing Steam gaming platform..."
echo "   - Downloading Steam package..."
curl -L -o ~/Downloads/steam_latest.deb https://repo.steampowered.com/steam/archive/precise/steam_latest.deb
echo "   - Installing Steam..."
sudo apt install ~/Downloads/steam_latest.deb -y
sudo apt install --fix-broken -y
echo "✅ Steam installed successfully"
echo ""

# Download ProtonMail Bridge
echo "📧 Installing ProtonMail Bridge..."
echo "   - Downloading ProtonMail Bridge..."
curl -L -o ~/Downloads/protonmail-bridge_3.21.2-1_amd64.deb https://proton.me/download/bridge/protonmail-bridge_3.21.2-1_amd64.deb
echo "   - Installing ProtonMail Bridge..."
sudo apt install ~/Downloads/protonmail-bridge_3.21.2-1_amd64.deb
sudo apt install --fix-broken -y
echo "✅ ProtonMail Bridge installed successfully"
echo ""

# Install Zoom
echo "📹 Installing Zoom video conferencing..."
echo "   - Downloading Zoom package..."
curl -L -o ~/Downloads/zoom_amd64.deb https://zoom.us/client/latest/zoom_amd64.deb
echo "   - Installing Zoom..."
sudo apt install ~/Downloads/zoom_amd64.deb -y
sudo apt install --fix-broken -y
echo "✅ Zoom installed successfully"
echo ""

echo "========================================="
echo "🎉 Application Setup Complete!"
echo "========================================="
echo ""
echo "📋 Applications installed:"
echo "   ✓ Spotify - Music streaming"
echo "   ✓ Discord - Chat and voice communication"
echo "   ✓ Chromium - Web browser"
echo "   ✓ Slack - Team communication"
echo "   ✓ Steam - Gaming platform"
echo "   ✓ ProtonMail Bridge - Email client bridge"
echo "   ✓ Zoom - Video conferencing"
echo ""
echo "💡 Quick tips:"
echo "   - Launch apps from the applications menu"
echo "   - Steam may require additional setup on first run"
echo "   - ProtonMail Bridge needs login configuration"
echo ""