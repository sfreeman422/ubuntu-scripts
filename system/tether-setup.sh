#!/bin/bash

# Tether Setup Script
# Bridges an iPhone to the Linux desktop (clipboard sync, file transfer,
# messages/notifications, OTP autofill) via https://github.com/zackb/tether
# Builds tetherd/tether/tether-gtk from source and registers the native
# messaging host used by the Firefox and Thunderbird extensions.
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TETHER_REPO_URL="https://github.com/zackb/tether.git"
TETHER_SRC_DIR="${TETHER_SRC_DIR:-$HOME/.local/src/tether}"
NATIVE_MESSAGING_DIR="$HOME/.mozilla/native-messaging-hosts"
NATIVE_MESSAGING_MANIFEST_NAME="com.tether.extension.json"

echo "========================================="
echo "Tether Setup Starting..."
echo "========================================="
echo ""
echo "ℹ️  Tether requires a Wayland compositor with the wlr-data-control"
echo "   protocol (e.g. GNOME on Wayland, Sway, Hyprland)."
echo "   See https://github.com/zackb/tether#requirements for details."
echo ""

if command -v tether >/dev/null 2>&1; then
    echo "✅ tether CLI already installed, skipping build/install."
else
    echo "📦 Installing build dependencies..."
    sudo apt update
    sudo apt install -y build-essential cmake ninja-build pkg-config git \
        libwayland-dev libavahi-client-dev libssl-dev \
        libglib2.0-dev libgtk-3-dev \
        libgtk-layer-shell-dev libnotify-dev \
        npm zip
    echo "✅ Build dependencies installed successfully"
    echo ""

    echo "📥 Fetching tether source..."
    mkdir -p "$(dirname "$TETHER_SRC_DIR")"
    if [[ -d "$TETHER_SRC_DIR/.git" ]]; then
        echo "   - Existing checkout found, pulling latest changes..."
        git -C "$TETHER_SRC_DIR" pull --ff-only
    else
        echo "   - Cloning $TETHER_REPO_URL..."
        git clone "$TETHER_REPO_URL" "$TETHER_SRC_DIR"
    fi
    echo "✅ Source ready at $TETHER_SRC_DIR"
    echo ""

    echo "🔨 Building tether (make release)..."
    (cd "$TETHER_SRC_DIR" && make release)
    echo "✅ Build complete"
    echo ""

    echo "📦 Installing tetherd, tether CLI, and tether-gtk (sudo make install)..."
    (cd "$TETHER_SRC_DIR" && sudo make install)
    echo "✅ Tether installed successfully"
fi
echo ""

# Register the native messaging host so Firefox/Thunderbird extensions can
# talk to tetherd. The manifest filename must match the "name" field inside it.
MOZILLA_MANIFEST="$(find "$TETHER_SRC_DIR" -maxdepth 3 -name 'com.tether.extension.mozilla.json' 2>/dev/null | head -n 1)"

if [[ -n "$MOZILLA_MANIFEST" ]]; then
    echo "🔗 Registering native messaging host for Firefox/Thunderbird..."
    mkdir -p "$NATIVE_MESSAGING_DIR"
    ln -sf "$MOZILLA_MANIFEST" "$NATIVE_MESSAGING_DIR/$NATIVE_MESSAGING_MANIFEST_NAME"
    echo "✅ Linked $NATIVE_MESSAGING_DIR/$NATIVE_MESSAGING_MANIFEST_NAME -> $MOZILLA_MANIFEST"
else
    echo "⚠️  Could not find com.tether.extension.mozilla.json under $TETHER_SRC_DIR."
    echo "   Build may not have generated it; the browser/mail extension will"
    echo "   not be able to reach tetherd until this manifest is linked into"
    echo "   $NATIVE_MESSAGING_DIR/$NATIVE_MESSAGING_MANIFEST_NAME"
fi
echo ""

echo "========================================="
echo "🎉 Tether Setup Complete!"
echo "========================================="
echo ""
echo "📋 Summary:"
echo "   ✓ tetherd, tether CLI, and tether-gtk installed"
echo "   ✓ Native messaging host registered for Firefox/Thunderbird"
echo ""
echo "🧩 Install the browser/mail extensions (manual, from the extension stores):"
echo "   - Firefox:     https://addons.mozilla.org/en-US/firefox/addon/tether-browser-extension/"
echo "   - Thunderbird: https://addons.thunderbird.net/en-US/thunderbird/addon/tether-mail-extension/"
echo ""
echo "💡 Next steps:"
echo "   - Pair your iPhone: launch 'tether-gtk' or run 'tether pair'"
echo "   - Bluetooth (messages/notifications) one-time setup: 'tether --bt-setup'"
echo "   - Check status any time with 'tether --bt-connection'"
echo ""
