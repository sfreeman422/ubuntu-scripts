#!/bin/bash

# Ubuntu release detection helpers
# Intended for Ubuntu setup scripts that need version/codename-aware behavior.

get_ubuntu_version_id() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        echo "${VERSION_ID:-unknown}"
        return 0
    fi

    echo "unknown"
    return 1
}

get_ubuntu_codename() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        if [[ -n "${UBUNTU_CODENAME:-}" ]]; then
            echo "$UBUNTU_CODENAME"
            return 0
        fi
        if [[ -n "${VERSION_CODENAME:-}" ]]; then
            echo "$VERSION_CODENAME"
            return 0
        fi
    fi

    if command -v lsb_release >/dev/null 2>&1; then
        lsb_release -cs
        return 0
    fi

    echo "unknown"
    return 1
}

is_supported_ubuntu_release() {
    local version_id
    version_id="$(get_ubuntu_version_id)"

    case "$version_id" in
        24.04|26.04)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Select a WineHQ repository codename that exists upstream.
# Tries current codename first, then known fallbacks.
get_winehq_codename() {
    local requested_codename="${1:-}"
    local candidate

    if ! command -v curl >/dev/null 2>&1; then
        echo "noble"
        return 0
    fi

    for candidate in "$requested_codename" noble jammy focal; do
        [[ -z "$candidate" || "$candidate" == "unknown" ]] && continue

        if curl -fsI "https://dl.winehq.org/wine-builds/ubuntu/dists/${candidate}/winehq-${candidate}.sources" >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done

    echo "noble"
    return 0
}

# Select the first reachable codename for repositories that expose
# codename-specific URLs (template must include %s placeholder).
get_reachable_repo_codename() {
    local requested_codename="${1:-}"
    local url_template="${2:-}"
    local candidate
    local url

    if [[ -z "$url_template" || "$url_template" != *"%s"* ]]; then
        echo "${requested_codename:-noble}"
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo "${requested_codename:-noble}"
        return 0
    fi

    for candidate in "$requested_codename" noble jammy focal; do
        [[ -z "$candidate" || "$candidate" == "unknown" ]] && continue

        # shellcheck disable=SC2059
        printf -v url "$url_template" "$candidate"
        if curl -fsI "$url" >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done

    echo "${requested_codename:-noble}"
    return 0
}