#!/bin/bash

# Application Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

echo "========================================="
echo "Application Setup Starting..."
echo "========================================="

# Install spotify discord chromium
echo "📱 Installing snap applications..."
echo "   - Spotify (music streaming)"
echo "   - Discord (chat/voice)"
echo "   - Chromium (web browser)"
snap install spotify discord chromium
echo "✅ Snap applications installed successfully"
echo ""

# Install Slack
echo "💬 Installing Slack..."
echo "   - Downloading Slack Desktop..."
curl -L -o ~/Downloads/slack-desktop-4.45.64-amd64.deb https://downloads.slack-edge.com/desktop-releases/linux/x64/4.45.64/slack-desktop-4.45.64-amd64.deb
echo "   - Installing Slack package..."
sudo apt install ~/Downloads/slack-desktop-4.45.64-amd64.deb -y
sudo apt install --fix-broken -y
echo "✅ Slack installed successfully"
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