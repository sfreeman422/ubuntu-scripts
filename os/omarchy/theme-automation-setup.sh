#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_omarchy

THEME_SCRIPT="$SCRIPT_DIR/../../scripts/theme-automation/omarchy-theme-automation.sh"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "🎨 Setting up Omarchy Theme Automation..."
echo "=========================================="

for dependency in curl jq omarchy; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        echo "❌ Missing required dependency: $dependency"
        exit 1
    fi
done

chmod +x "$THEME_SCRIPT"
mkdir -p "$SYSTEMD_USER_DIR"

cat > "$SYSTEMD_USER_DIR/theme-automation.service" << EOF
[Unit]
Description=Omarchy Theme Automation
After=graphical-session.target

[Service]
Type=oneshot
Environment=WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
ExecStart=/usr/bin/env bash -lc '"$THEME_SCRIPT"'

[Install]
WantedBy=default.target
EOF

cat > "$SYSTEMD_USER_DIR/theme-automation.timer" << EOF
[Unit]
Description=Run Omarchy Theme Automation every 15 minutes
Requires=theme-automation.service

[Timer]
OnCalendar=*:0/15
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable theme-automation.timer
systemctl --user start theme-automation.timer
"$THEME_SCRIPT"

echo ""
echo "✅ Omarchy theme automation setup complete!"
echo ""
echo "📋 What was installed:"
echo "   • Theme automation script: $THEME_SCRIPT"
echo "   • Systemd service: theme-automation.service"
echo "   • Systemd timer: theme-automation.timer (runs every 15 minutes)"
echo "   • Default light theme: flexoki-light"
echo "   • Default dark theme: tokyo-night"
echo ""
