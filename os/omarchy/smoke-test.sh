#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
    echo "✅ $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
    echo "⚠️  $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
    echo "❌ $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_command() {
    local cmd="$1"
    local label="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        pass "$label ($cmd) is available"
    else
        fail "$label ($cmd) is missing"
    fi
}

echo "============================================="
echo "Omarchy Preflight Smoke Test"
echo "============================================="

if is_omarchy_os; then
    pass "OS detected as Omarchy ($(get_os_pretty_name))"
else
    fail "OS is not Omarchy (detected: $(get_os_pretty_name))"
fi

check_command "omarchy" "Omarchy CLI"
check_command "hyprctl" "Hyprland controller"
check_command "yay" "AUR helper"
check_command "curl" "HTTP client"
check_command "jq" "JSON parser"

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    pass "Wayland session detected"
else
    warn "No Wayland session detected"
fi

if systemctl --user --version >/dev/null 2>&1; then
    pass "systemd user services available"
else
    warn "systemd user services unavailable"
fi

echo ""
echo "Summary:"
echo "  Passed:  $PASS_COUNT"
echo "  Warnings: $WARN_COUNT"
echo "  Failed:  $FAIL_COUNT"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo ""
    echo "Preflight failed. Fix the failed checks before running main setup."
    exit 1
fi

echo ""
echo "Preflight passed. Omarchy setup can proceed."
