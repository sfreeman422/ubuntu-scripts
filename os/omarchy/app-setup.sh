#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_omarchy

echo "========================================="
echo "Omarchy Application Setup Starting..."
echo "========================================="

echo "📱 Installing core desktop applications..."
omarchy_install_packages chromium spotify-launcher discord slack-desktop steam protonmail-bridge zoom
echo "✅ Desktop applications installed successfully"
echo ""

echo "========================================="
echo "🎉 Omarchy Application Setup Complete!"
echo "========================================="
echo ""
echo "📋 Applications installed:"
echo "   ✓ Chromium - Web browser"
echo "   ✓ Spotify - Music streaming"
echo "   ✓ Discord - Chat and voice communication"
echo "   ✓ Slack - Team communication"
echo "   ✓ Steam - Gaming platform"
echo "   ✓ ProtonMail Bridge - Email client bridge"
echo "   ✓ Zoom - Video conferencing"
echo ""
