#!/bin/bash
#
# idle-shutdown-setup.sh - Setup script for idle shutdown automation
#
# Installs dependencies, copies the runtime script, and configures cron
# to automatically shut down the computer if idle for more than 1 hour
# between midnight and 5AM.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_SCRIPT="idle-shutdown.sh"
TARGET_DIR="$HOME/scripts"
CRON_SCHEDULE="*/5 3-4 * * *"

echo "====================================="
echo "  Idle Shutdown Setup"
echo "====================================="
echo ""

# Detect display server
detect_display_server() {
    if [ -n "$WAYLAND_DISPLAY" ]; then
        echo "wayland"
    elif [ -n "$DISPLAY" ]; then
        echo "x11"
    else
        echo "unknown"
    fi
}

DISPLAY_SERVER=$(detect_display_server)
echo "Detected display server: $DISPLAY_SERVER"
echo ""

# Install dependencies
echo "Installing dependencies..."

if [ "$DISPLAY_SERVER" = "x11" ]; then
    if ! command -v xprintidle &> /dev/null; then
        echo "  Installing xprintidle for X11 idle detection..."
        sudo apt-get update -qq
        sudo apt-get install -y xprintidle
    else
        echo "  xprintidle already installed"
    fi
elif [ "$DISPLAY_SERVER" = "wayland" ]; then
    echo "  Wayland detected - using GNOME dbus for idle detection"
    if ! command -v dbus-send &> /dev/null; then
        echo "  Installing dbus for Wayland idle detection..."
        sudo apt-get update -qq
        sudo apt-get install -y dbus
    else
        echo "  dbus already available"
    fi
else
    echo "  WARNING: Could not detect display server. Script may not work correctly."
    echo "  Make sure DISPLAY or WAYLAND_DISPLAY is set when running."
fi

# Ensure notify-send is available
if ! command -v notify-send &> /dev/null; then
    echo "  Installing libnotify-bin for desktop notifications..."
    sudo apt-get update -qq
    sudo apt-get install -y libnotify-bin
else
    echo "  notify-send already installed"
fi

echo ""

# Create target directory
echo "Setting up scripts..."
mkdir -p "$TARGET_DIR"

# Copy runtime script
if [ -f "$SCRIPT_DIR/$RUNTIME_SCRIPT" ]; then
    cp "$SCRIPT_DIR/$RUNTIME_SCRIPT" "$TARGET_DIR/$RUNTIME_SCRIPT"
    chmod +x "$TARGET_DIR/$RUNTIME_SCRIPT"
    echo "  Copied $RUNTIME_SCRIPT to $TARGET_DIR/"
else
    echo "  ERROR: $RUNTIME_SCRIPT not found in $SCRIPT_DIR"
    exit 1
fi

echo ""

# Configure passwordless shutdown
echo "Configuring sudo for passwordless shutdown..."
SUDOERS_FILE="/etc/sudoers.d/idle-shutdown"
SUDOERS_CONTENT="$USER ALL=(ALL) NOPASSWD: /sbin/shutdown"

if [ -f "$SUDOERS_FILE" ]; then
    echo "  Sudoers entry already exists"
else
    echo "$SUDOERS_CONTENT" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    echo "  Created $SUDOERS_FILE"
fi

echo ""

# Set up cron job
echo "Setting up cron job..."

# Build cron entry with proper environment variables
USER_ID=$(id -u)
CRON_ENTRY="$CRON_SCHEDULE $TARGET_DIR/$RUNTIME_SCRIPT"

EXISTING_CRON=$(crontab -l 2>/dev/null || true)

if echo "$EXISTING_CRON" | grep -F "$TARGET_DIR/$RUNTIME_SCRIPT" > /dev/null; then
    echo "  Cron entry already exists, skipping creation"
else
    if [ -n "$EXISTING_CRON" ]; then
        printf "%s\n%s\n" "$EXISTING_CRON" "$CRON_ENTRY" | crontab -
    else
        echo "$CRON_ENTRY" | crontab -
    fi
    echo "  Cron job installed: $CRON_SCHEDULE"
fi

echo ""
echo "====================================="
echo "  Setup Complete!"
echo "====================================="
echo ""
echo "Configuration Summary:"
echo "  - Runtime script: $TARGET_DIR/$RUNTIME_SCRIPT"
echo "  - Log file: $TARGET_DIR/idle-shutdown.log"
echo "  - Schedule: Every 5 minutes from 03:00 to 04:59 (after 2AM backup)"
echo "  - Idle threshold: 1 hour"
echo "  - Display server: $DISPLAY_SERVER"
echo ""
echo "Shutdown will be blocked if any of these are running:"
echo "  - rsync"
echo "  - daily-backup.sh"
echo "  - tar"
echo ""
echo "Verification Commands:"
echo "  - Check cron: crontab -l | grep idle"
echo "  - Test idle detection: xprintidle  (X11)"
echo "  - View logs: cat $TARGET_DIR/idle-shutdown.log"
echo "  - Cancel shutdown: sudo shutdown -c"
echo ""
echo "To test manually (during allowed hours):"
echo "  $TARGET_DIR/$RUNTIME_SCRIPT"
echo ""
echo "To uninstall:"
echo "  crontab -l | grep -v idle-shutdown | crontab -"
echo "  rm $TARGET_DIR/$RUNTIME_SCRIPT"
echo "  sudo rm $SUDOERS_FILE"
echo ""
