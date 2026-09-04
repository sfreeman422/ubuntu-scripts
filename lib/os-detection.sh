#!/bin/bash

get_os_release_field() {
    local field_name="$1"

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        eval "printf '%s\n' \"\${$field_name:-}\""
        return 0
    fi

    return 1
}

get_os_id() {
    get_os_release_field "ID"
}

get_os_pretty_name() {
    local pretty_name
    pretty_name="$(get_os_release_field "PRETTY_NAME" 2>/dev/null || true)"

    if [[ -n "$pretty_name" ]]; then
        printf '%s\n' "$pretty_name"
        return 0
    fi

    printf 'unknown\n'
    return 1
}

is_ubuntu_os() {
    [[ "$(get_os_id 2>/dev/null)" == "ubuntu" ]]
}

is_omarchy_os() {
    local os_id
    local pretty_name
    local name_field

    os_id="$(get_os_id 2>/dev/null || true)"
    pretty_name="$(get_os_pretty_name 2>/dev/null || true)"
    name_field="$(get_os_release_field "NAME" 2>/dev/null || true)"

    if [[ "$os_id" == "omarchy" ]]; then
        return 0
    fi

    if [[ "$pretty_name" == *"Omarchy"* || "$name_field" == *"Omarchy"* ]]; then
        return 0
    fi

    if [[ "$os_id" == "arch" && -x /usr/bin/omarchy ]]; then
        return 0
    fi

    return 1
}

detect_setup_target() {
    local requested_target="${1:-}"

    case "$requested_target" in
        ubuntu|omarchy)
            printf '%s\n' "$requested_target"
            return 0
            ;;
        "")
            ;;
        *)
            return 1
            ;;
    esac

    if is_ubuntu_os; then
        printf 'ubuntu\n'
        return 0
    fi

    if is_omarchy_os; then
        printf 'omarchy\n'
        return 0
    fi

    return 1
}

get_setup_display_name() {
    case "$1" in
        ubuntu)
            printf 'Ubuntu + GNOME\n'
            ;;
        omarchy)
            printf 'Omarchy\n'
            ;;
        *)
            printf 'Unknown\n'
            ;;
    esac
}
