#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"

# shellcheck disable=SC1091
source "$LIB_DIR/os-detection.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/setup-common.sh"

require_omarchy() {
    if ! is_omarchy_os; then
        echo "❌ This setup path is intended for Omarchy only. Detected: $(get_os_pretty_name)"
        exit 1
    fi
}

ensure_yay() {
    if ! command -v yay >/dev/null 2>&1; then
        echo "❌ yay is required for Omarchy setup but was not found."
        exit 1
    fi
}

omarchy_install_packages() {
    ensure_yay
    if [[ $# -eq 0 ]]; then
        return 0
    fi

    yay -S --needed --noconfirm "$@"
}

omarchy_package_visible() {
    local package_name="$1"

    if pacman -Si "$package_name" >/dev/null 2>&1; then
        return 0
    fi

    if yay -Si "$package_name" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}
