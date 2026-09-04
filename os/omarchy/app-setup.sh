#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_omarchy

echo "========================================="
echo "Omarchy Application Setup Starting..."
echo "========================================="

echo "📱 Installing core desktop applications..."
omarchy_install_packages spotify-launcher slack-desktop steam protonmail-bridge
echo "✅ Desktop applications installed successfully"
echo ""

echo "ℹ️  Discord and Zoom are already available in Omarchy as web app launchers."
echo "ℹ️  Chromium is already part of Omarchy's base package set."
echo ""

echo "========================================="
echo "🎉 Omarchy Application Setup Complete!"
echo "========================================="
echo ""
echo "📋 Applications installed:"
echo "   ✓ Chromium - Provided by Omarchy base"
echo "   ✓ Spotify - Music streaming"
echo "   ✓ Slack - Team communication"
echo "   ✓ Steam - Gaming platform"
echo "   ✓ ProtonMail Bridge - Email client bridge"
echo "   ✓ Discord - Available via Omarchy web app launcher"
echo "   ✓ Zoom - Available via Omarchy web app launcher"
echo ""
