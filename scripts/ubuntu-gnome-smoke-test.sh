#!/bin/bash

# Ubuntu + GNOME Smoke Test
# Verifies prerequisites before running full setup.

set -u

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

is_supported_release() {
    local version_id="$1"
    case "$version_id" in
        24.04|26.04)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

echo "============================================="
echo "Ubuntu + GNOME Preflight Smoke Test"
echo "============================================="

if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" == "ubuntu" ]]; then
        pass "OS detected as Ubuntu (${PRETTY_NAME:-unknown})"
        if is_supported_release "${VERSION_ID:-unknown}"; then
            pass "Ubuntu release ${VERSION_ID:-unknown} is in validated support set (24.04, 26.04)"
        else
            warn "Ubuntu release ${VERSION_ID:-unknown} is not explicitly validated (best-effort mode)"
        fi
    else
        fail "OS is not Ubuntu (detected: ${PRETTY_NAME:-unknown})"
    fi
else
    fail "/etc/os-release not found"
fi

check_command "gnome-shell" "GNOME shell"
check_command "gsettings" "GNOME settings tool"
check_command "curl" "HTTP client"
check_command "jq" "JSON parser"

if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    pass "Graphical session detected"
else
    warn "No graphical session detected (DISPLAY/WAYLAND_DISPLAY not set)"
fi

if systemctl --user --version >/dev/null 2>&1; then
    pass "systemd user services available"
else
    warn "systemd user services unavailable (theme timer may not work)"
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
echo "Preflight passed. Ubuntu + GNOME setup can proceed."
exit 0
