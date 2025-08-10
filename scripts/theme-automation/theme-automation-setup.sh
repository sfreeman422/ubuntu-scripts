#!/bin/bash

# Theme Automation Setup Script
# Sets up automatic theme switching based on sunrise/sunset
# Author: Steve Freeman
# Date: 2025-08-10

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SCRIPT="$SCRIPT_DIR/theme-automation.sh"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "🎨 Setting up Ubuntu Theme Automation..."
echo "=========================================="

# Check if we're in a graphical environment
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
    echo "❌ No graphical environment detected. This script requires a desktop environment."
    exit 1
fi

# Check for required dependencies
echo "📋 Checking dependencies..."

MISSING_DEPS=()

if ! command -v curl >/dev/null 2>&1; then
    MISSING_DEPS+=("curl")
fi

if ! command -v jq >/dev/null 2>&1; then
    MISSING_DEPS+=("jq")
fi

if ! command -v gsettings >/dev/null 2>&1; then
    MISSING_DEPS+=("gsettings (part of GNOME)")
fi

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo "❌ Missing required dependencies: ${MISSING_DEPS[*]}"
    echo "Installing missing packages..."
    
    sudo apt update
    
    for dep in "${MISSING_DEPS[@]}"; do
        case $dep in
            "curl")
                sudo apt install -y curl
                ;;
            "jq")
                sudo apt install -y jq
                ;;
            "gsettings (part of GNOME)")
                echo "⚠️  gsettings not found. Make sure you're running GNOME desktop environment."
                echo "If you're using a different desktop environment, this script may not work properly."
                read -p "Continue anyway? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
                ;;
        esac
    done
fi

echo "✅ All dependencies satisfied"

# Make the theme script executable
chmod +x "$THEME_SCRIPT"

# Setup snap theme connections
echo "🔗 Setting up snap theme connections..."
if snap list gtk-common-themes >/dev/null 2>&1; then
    # Connect common snap applications to gtk-common-themes
    snap_apps=("firefox" "code" "discord" "spotify" "chromium" "thunderbird")
    for app in "${snap_apps[@]}"; do
        if snap list "$app" >/dev/null 2>&1; then
            echo "  - Connecting $app to gtk-common-themes..."
            sudo snap connect "$app:gtk-3-themes" gtk-common-themes:gtk-3-themes 2>/dev/null || true
            sudo snap connect "$app:icon-themes" gtk-common-themes:icon-themes 2>/dev/null || true
            sudo snap connect "$app:sound-themes" gtk-common-themes:sound-themes 2>/dev/null || true
        fi
    done
    echo "✅ Snap theme connections configured"
else
    echo "⚠️  gtk-common-themes snap not found. Install it with: sudo snap install gtk-common-themes"
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
ExecStart=$THEME_SCRIPT
Environment=DISPLAY=:0

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
