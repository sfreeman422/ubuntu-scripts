#!/bin/bash

# Ubuntu + GNOME Dry Run Validator
# Performs non-destructive checks before full setup.

set -u

STRICT_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict)
            STRICT_MODE=true
            ;;
        -h|--help)
            echo "Usage: $0 [--strict]"
            echo ""
            echo "  --strict   Treat warnings as failures (non-zero exit if any warnings)"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Usage: $0 [--strict]"
            exit 1
            ;;
    esac
    shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$ROOT_DIR/lib"

if [[ -f "$LIB_DIR/ubuntu-release.sh" ]]; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/ubuntu-release.sh"
fi

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
OPTIONAL_WARN_COUNT=0

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

optional_warn() {
    echo "ℹ️  $1"
    OPTIONAL_WARN_COUNT=$((OPTIONAL_WARN_COUNT + 1))
}

check_command() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        pass "Command available: $cmd"
    else
        fail "Missing command: $cmd"
    fi
}

check_url() {
    local label="$1"
    local url="$2"

    if curl -fsI "$url" >/dev/null 2>&1; then
        pass "$label reachable"
    else
        warn "$label not reachable right now: $url"
    fi
}

check_optional_url() {
    local label="$1"
    local url="$2"

    if curl -fsI "$url" >/dev/null 2>&1; then
        pass "$label reachable"
    else
        optional_warn "$label not reachable right now (optional component): $url"
    fi
}

check_apt_package() {
    local pkg="$1"
    if apt-cache show "$pkg" >/dev/null 2>&1; then
        pass "APT package visible: $pkg"
    else
        warn "APT package not visible in current indexes: $pkg"
    fi
}

check_discord_availability() {
    if apt-cache show discord >/dev/null 2>&1; then
        pass "Discord available via apt"
        return 0
    fi

    if command -v snap >/dev/null 2>&1; then
        if snap info discord >/dev/null 2>&1; then
            pass "Discord available via snap"
            return 0
        fi
    fi

    warn "Discord is not currently available via apt or snap"
    return 1
}

echo "============================================="
echo "Ubuntu + GNOME Setup Dry Run"
echo "============================================="
echo "This mode does not install or modify anything."
if [[ "$STRICT_MODE" == "true" ]]; then
    echo "Strict mode is enabled: warnings will fail this run."
fi
echo ""

if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" == "ubuntu" ]]; then
        pass "OS detected as Ubuntu (${PRETTY_NAME:-unknown})"
    else
        fail "OS is not Ubuntu (detected: ${PRETTY_NAME:-unknown})"
    fi
else
    fail "/etc/os-release not found"
fi

if command -v gnome-shell >/dev/null 2>&1; then
    pass "GNOME shell is available"
else
    fail "GNOME shell is not available"
fi

if declare -f is_supported_ubuntu_release >/dev/null 2>&1; then
    if is_supported_ubuntu_release; then
        pass "Ubuntu release $(get_ubuntu_version_id) is in validated support set"
    else
        warn "Ubuntu release $(get_ubuntu_version_id) is not explicitly validated (best-effort mode)"
    fi
fi

echo ""
echo "Checking required commands..."
check_command curl
check_command wget
check_command gpg
check_command apt-cache
check_command systemctl
check_command gsettings

UBUNTU_CODENAME_VALUE="$(get_ubuntu_codename 2>/dev/null || echo "unknown")"
WINEHQ_CODENAME="$(get_winehq_codename "$UBUNTU_CODENAME_VALUE" 2>/dev/null || echo "noble")"

echo ""
echo "Checking external repositories/downloads..."
check_url "GitHub CLI apt repo" "https://cli.github.com/packages/dists/stable/Release"
check_url "Redis apt repo (${UBUNTU_CODENAME_VALUE})" "https://packages.redis.io/deb/dists/${UBUNTU_CODENAME_VALUE}/Release"
check_url "Docker apt repo (${UBUNTU_CODENAME_VALUE})" "https://download.docker.com/linux/ubuntu/dists/${UBUNTU_CODENAME_VALUE}/Release"
check_optional_url "Slack latest .deb" "https://downloads.slack-edge.com/desktop-releases/linux/x64/slack-desktop-latest-amd64.deb"
check_url "WineHQ source (${WINEHQ_CODENAME})" "https://dl.winehq.org/wine-builds/ubuntu/dists/${WINEHQ_CODENAME}/winehq-${WINEHQ_CODENAME}.sources"
check_url "Steam download" "https://repo.steampowered.com/steam/archive/precise/steam_latest.deb"
check_url "Zoom download" "https://zoom.us/client/latest/zoom_amd64.deb"
check_url "ProtonMail Bridge download" "https://proton.me/download/bridge/protonmail-bridge_3.21.2-1_amd64.deb"
check_url "Lutris 0.5.18 download" "https://github.com/lutris/lutris/releases/download/v0.5.18/lutris_0.5.18_all.deb"

echo ""
echo "Checking package visibility in current apt indexes..."
check_apt_package zsh
check_apt_package htop
check_apt_package ubuntu-restricted-extras
check_apt_package unattended-upgrades
check_apt_package fonts-firacode
check_apt_package fonts-powerline
check_apt_package gnome-tweaks
check_apt_package postgresql
check_apt_package redis
check_apt_package chromium-browser
check_discord_availability
check_apt_package winehq-stable

echo ""
echo "Planned setup steps (no changes made):"
echo "  1) system/system-level-setup.sh"
echo "  2) dev/dev-setup.sh"
echo "  3) dev/zsh-theme.sh"
echo "  4) app/app-setup.sh"
echo "  5) scripts/gaming/gaming.sh"
echo "  6) scripts/theme-automation/theme-automation-setup.sh"
echo "  7) scripts/backup/backup-setup.sh (optional)"
echo "  8) scripts/downloads-cleanup/downloads-cleanup-setup.sh"

echo ""
echo "Summary:"
echo "  Passed:   $PASS_COUNT"
echo "  Warnings: $WARN_COUNT"
echo "  Optional Warnings: $OPTIONAL_WARN_COUNT"
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
exit 0