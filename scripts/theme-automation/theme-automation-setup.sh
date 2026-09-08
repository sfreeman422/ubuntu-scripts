#!/bin/bash

# Theme Automation Setup Script
# Sets up automatic theme switching based on sunrise/sunset
# Supports: GNOME
# Author: Steve Freeman
# Date: 2025-01-24

# Source the GNOME environment library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"
if [[ -f "$LIB_DIR/gnome-environment.sh" ]]; then
    source "$LIB_DIR/gnome-environment.sh"
else
    echo "❌ Error: gnome-environment.sh not found at $LIB_DIR"
    exit 1
fi

THEME_SCRIPT="$SCRIPT_DIR/theme-automation.sh"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "🎨 Setting up Ubuntu Theme Automation..."
echo "=========================================="

# Check if we're in a graphical environment
if ! has_display; then
    echo "❌ No graphical environment detected. This script requires GNOME on Ubuntu."
    exit 1
fi

# Check which desktop session is being used
de=$(detect_desktop_environment)
echo "📋 Detected desktop session: $de"

# Check if GNOME is running
if [[ "$de" != "gnome" ]]; then
    echo "❌ Unsupported desktop session: $de"
    echo "This script supports GNOME on Ubuntu."
    exit 1
fi

echo "📋 Checking dependencies..."

MISSING_DEPS=()

if ! command -v curl >/dev/null 2>&1; then
    MISSING_DEPS+=("curl")
fi

if ! command -v jq >/dev/null 2>&1; then
    MISSING_DEPS+=("jq")
fi

if ! command -v gsettings >/dev/null 2>&1; then
    MISSING_DEPS+=("gsettings (GNOME required)")
fi

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo "❌ Missing required dependencies: ${MISSING_DEPS[*]}"
    echo "Installing missing packages..."
    
    if ! sudo apt update; then
        echo "❌ Unable to update package lists."
        exit 1
    fi
    
    for dep in "${MISSING_DEPS[@]}"; do
        case $dep in
            "curl")
                if ! sudo apt install -y curl; then
                    echo "❌ curl installation failed."
                    exit 1
                fi
                ;;
            "jq")
                if ! sudo apt install -y jq; then
                    echo "❌ jq installation failed."
                    exit 1
                fi
                ;;
            "gsettings (GNOME required)")
                echo "❌ gsettings not found. GNOME Shell is required for GNOME theme automation."
                exit 1
                ;;
        esac
    done
fi

echo "✅ All dependencies satisfied"

# Make the theme script executable
chmod +x "$THEME_SCRIPT"

# Setup gtk-common-themes
echo "🎨 Installing GTK common themes..."
if apt list --installed 2>/dev/null | grep -q gtk-common-themes; then
    echo "   - gtk-common-themes already installed, connecting snap apps..."
else
    echo "   - Installing gtk-common-themes via apt..."
    if sudo apt install -y gtk-common-themes; then
        echo "✅ GTK common themes installed successfully"
    else
        echo "⚠️  GTK common themes installation failed."
    fi
fi

# Create systemd user directory if it doesn't exist
mkdir -p "$SYSTEMD_USER_DIR"

# Create systemd service file
cat > "$SYSTEMD_USER_DIR/theme-automation.service" << EOF
[Unit]
Description=Ubuntu Theme Automation
After=graphical-session.target

[Service]
Type=oneshot
Environment=DISPLAY=${DISPLAY:-:0}
Environment=WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
ExecStart=/usr/bin/env bash -lc '"$THEME_SCRIPT"'

[Install]
WantedBy=default.target
EOF

# Create systemd timer file for periodic checks
cat > "$SYSTEMD_USER_DIR/theme-automation.timer" << EOF
[Unit]
Description=Run Ubuntu Theme Automation every 15 minutes
Requires=theme-automation.service

[Timer]
OnCalendar=*:0/15
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "📝 Created systemd service and timer files"

# Reload systemd and enable the timer
systemctl --user daemon-reload
systemctl --user enable theme-automation.timer
systemctl --user start theme-automation.timer

echo "⚡ Enabled automatic theme switching (checks every 15 minutes)"

# Run the script once immediately to set the current theme
echo "🔄 Running initial theme check..."
"$THEME_SCRIPT"

echo ""
echo "✅ Theme automation setup complete!"
echo ""
echo "📋 What was installed:"
echo "   • Theme automation script: $THEME_SCRIPT"
echo "   • Systemd service: theme-automation.service"
echo "   • Systemd timer: theme-automation.timer (runs every 15 minutes)"
echo ""
echo "🎛️  Manual controls:"
echo "   • Force light theme: $THEME_SCRIPT --light"
echo "   • Force dark theme: $THEME_SCRIPT --dark"
echo "   • Check status: $THEME_SCRIPT --status"
echo "   • View logs: tail -f ~/.theme-automation.log"
echo ""
echo "⚙️  Service management:"
echo "   • Start: systemctl --user start theme-automation.timer"
echo "   • Stop: systemctl --user stop theme-automation.timer"
echo "   • Status: systemctl --user status theme-automation.timer"
echo "   • Disable: systemctl --user disable theme-automation.timer"
echo ""
echo "🌅 The script will automatically switch between light and dark themes"
echo "   based on your location's sunrise and sunset times!"
