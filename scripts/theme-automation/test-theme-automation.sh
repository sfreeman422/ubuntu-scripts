#!/bin/bash

# Theme Automation Test Script
# Tests the theme automation functionality
# Author: Steve Freeman

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SCRIPT="$SCRIPT_DIR/theme-automation.sh"

echo "🧪 Theme Automation Test"
echo "========================"

# Check if theme script exists and is executable
if [[ ! -f "$THEME_SCRIPT" ]]; then
    echo "❌ Theme script not found: $THEME_SCRIPT"
    exit 1
fi

if [[ ! -x "$THEME_SCRIPT" ]]; then
    echo "❌ Theme script is not executable"
    echo "Run: chmod +x $THEME_SCRIPT"
    exit 1
fi

echo "✅ Theme script found and executable"

# Test dependencies
echo ""
echo "🔍 Checking dependencies..."

for cmd in curl jq gsettings; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd found"
    else
        echo "❌ $cmd not found"
    fi
done

# Test location detection
echo ""
echo "🌍 Testing location detection..."
echo "This will try to determine your location..."

if "$THEME_SCRIPT" --status >/dev/null 2>&1; then
    echo "✅ Location detection working"
else
    echo "⚠️  Location detection may have issues"
fi

# Show current status
echo ""
echo "📊 Current Status:"
"$THEME_SCRIPT" --status

# Test theme switching
echo ""
echo "🔄 Testing theme switching..."
echo "Current theme: $(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")"

read -p "Test light theme? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$THEME_SCRIPT" --light
    echo "Light theme applied. Current: $(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")"
fi

read -p "Test dark theme? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$THEME_SCRIPT" --dark
    echo "Dark theme applied. Current: $(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")"
fi

# Check systemd timer status
echo ""
echo "⏰ Systemd Timer Status:"
if systemctl --user is-active --quiet theme-automation.timer; then
    echo "✅ Timer is active"
    systemctl --user status theme-automation.timer --no-pager -l
else
    echo "❌ Timer is not active"
    echo "Run: systemctl --user start theme-automation.timer"
fi

echo ""
echo "🎉 Test complete!"
echo ""
echo "💡 Tips:"
echo "   • View logs: tail -f ~/.theme-automation.log"
echo "   • Manual run: $THEME_SCRIPT"
echo "   • Force light: $THEME_SCRIPT --light"
echo "   • Force dark: $THEME_SCRIPT --dark"
