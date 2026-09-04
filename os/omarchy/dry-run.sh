#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

STRICT_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict)
            STRICT_MODE=true
            ;;
        -h|--help)
            echo "Usage: $0 [--strict]"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

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
    if command -v "$cmd" >/dev/null 2>&1; then
        pass "Command available: $cmd"
    else
        fail "Missing command: $cmd"
    fi
}

check_package() {
    local pkg="$1"
    if omarchy_package_visible "$pkg"; then
        pass "Package visible: $pkg"
    else
        warn "Package not visible in current pacman/AUR indexes: $pkg"
    fi
}

echo "============================================="
echo "Omarchy Setup Dry Run"
echo "============================================="
echo "This mode does not install or modify anything."
if [[ "$STRICT_MODE" == "true" ]]; then
    echo "Strict mode is enabled: warnings will fail this run."
fi
echo ""

if is_omarchy_os; then
    pass "OS detected as Omarchy ($(get_os_pretty_name))"
else
    fail "OS is not Omarchy (detected: $(get_os_pretty_name))"
fi

check_command omarchy
check_command yay
check_command pacman
check_command systemctl
check_command hyprctl
check_command jq
check_command curl

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    pass "Wayland session detected"
else
    warn "No Wayland session detected"
fi

if command -v Hyprland >/dev/null 2>&1 || command -v hyprctl >/dev/null 2>&1; then
    pass "Hyprland tooling is available"
else
    fail "Hyprland tooling is not available"
fi

echo ""
echo "Checking package visibility in current pacman/AUR indexes..."
check_package zsh
check_package htop
check_package github-cli
check_package postgresql
check_package redis
check_package docker
check_package visual-studio-code-bin
check_package spotify-launcher
check_package discord
check_package slack-desktop
check_package steam
check_package protonmail-bridge
check_package zoom
check_package wine
check_package lutris

echo ""
echo "Planned setup steps (no changes made):"
echo "  1) os/omarchy/system-level-setup.sh"
echo "  2) os/omarchy/dev-setup.sh"
echo "  3) dev/zsh-theme.sh"
echo "  4) os/omarchy/app-setup.sh"
echo "  5) os/omarchy/gaming.sh"
echo "  6) os/omarchy/theme-automation-setup.sh"
echo "  7) scripts/backup/backup-setup.sh (optional)"
echo "  8) scripts/downloads-cleanup/downloads-cleanup-setup.sh"

echo ""
echo "Summary:"
echo "  Passed:   $PASS_COUNT"
echo "  Warnings: $WARN_COUNT"
echo "  Failed:   $FAIL_COUNT"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo ""
    echo "Dry run failed. Resolve failed checks before running full setup."
    exit 1
fi

if [[ "$STRICT_MODE" == "true" && $WARN_COUNT -gt 0 ]]; then
    echo ""
    echo "Dry run strict mode failed due to warnings. Resolve warnings before running full setup."
    exit 2
fi

echo ""
echo "Dry run completed successfully."
