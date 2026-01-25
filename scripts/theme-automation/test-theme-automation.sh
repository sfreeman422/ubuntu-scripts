#!/bin/bash

# Theme Automation Test Script
# Tests the theme automation functionality
# Supports: GNOME, XFCE
# Author: Steve Freeman

# Source the desktop environment library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"
if [[ -f "$LIB_DIR/desktop-environment.sh" ]]; then
    source "$LIB_DIR/desktop-environment.sh"
else
    echo "❌ Error: desktop-environment.sh not found at $LIB_DIR"
    exit 1
fi

THEME_SCRIPT="$SCRIPT_DIR/theme-automation.sh"

echo "🧪 Theme Automation Test"
echo "========================"

# Detect desktop environment
de=$(detect_desktop_environment)
echo "🖥️  Desktop Environment: $de"
echo ""

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

# Test dependencies based on DE
echo ""
echo "🔍 Checking dependencies for $de..."

required_commands=$(get_required_commands)
missing_commands=()

for cmd in $required_commands; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd found"
    else
        echo "❌ $cmd not found"
        missing_commands+=("$cmd")
    fi
done

if [[ ${#missing_commands[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Missing dependencies: ${missing_commands[@]}"
    echo "Run: $SCRIPT_DIR/theme-automation-setup.sh"
fi

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
echo "Current theme: $(get_current_theme)"

read -p "Test light theme? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$THEME_SCRIPT" --light
    echo "Light theme applied. Current: $(get_current_theme)"
fi

read -p "Test dark theme? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$THEME_SCRIPT" --dark
    echo "Dark theme applied. Current: $(get_current_theme)"
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
echo "   • Check status: $THEME_SCRIPT --status"
