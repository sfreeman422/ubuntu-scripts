#!/bin/bash

set -u

LOG_FILE="$HOME/.omarchy-theme-automation.log"
CACHE_DIR="$HOME/.cache/theme-automation"
LOCATION_CACHE="$CACHE_DIR/location.json"
SUNRISE_CACHE="$CACHE_DIR/sunrise_data.json"
LIGHT_THEME="${OMARCHY_LIGHT_THEME:-flexoki-light}"
DARK_THEME="${OMARCHY_DARK_THEME:-tokyo-night}"

mkdir -p "$CACHE_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

get_location() {
    local location_data

    if [[ -f "$LOCATION_CACHE" ]]; then
        if [[ $(( $(date +%s) - $(stat -c %Y "$LOCATION_CACHE") )) -lt 86400 ]]; then
            return 0
        fi
    fi

    location_data="$(curl -s "http://ipinfo.io/json" 2>/dev/null || true)"
    if [[ -n "$location_data" ]]; then
        local loc
        loc="$(echo "$location_data" | jq -r '.loc // empty')"
        if [[ -n "$loc" ]]; then
            printf '%s\n' "$location_data" > "$LOCATION_CACHE"
            return 0
        fi
    fi

    return 1
}

get_sunrise_sunset() {
    local lat
    local lon
    local today
    local api_url
    local sunrise_data

    get_location || return 1

    lat="$(jq -r '.loc' "$LOCATION_CACHE" | cut -d',' -f1)"
    lon="$(jq -r '.loc' "$LOCATION_CACHE" | cut -d',' -f2)"
    today="$(date +%Y-%m-%d)"
    api_url="https://api.sunrise-sunset.org/json?lat=$lat&lng=$lon&date=$today&formatted=0"
    sunrise_data="$(curl -s "$api_url" 2>/dev/null || true)"

    if [[ -n "$sunrise_data" && "$(echo "$sunrise_data" | jq -r '.status // empty')" == "OK" ]]; then
        printf '%s\n' "$sunrise_data" > "$SUNRISE_CACHE"
        return 0
    fi

    return 1
}

is_daytime() {
    local sunrise_local
    local sunset_local
    local current_time

    if ! get_sunrise_sunset; then
        local hour
        hour="$(date +%H)"
        [[ "$hour" -ge 6 && "$hour" -lt 18 ]]
        return
    fi

    sunrise_local="$(date -d "$(jq -r '.results.sunrise' "$SUNRISE_CACHE")" +%s)"
    sunset_local="$(date -d "$(jq -r '.results.sunset' "$SUNRISE_CACHE")" +%s)"
    current_time="$(date +%s)"

    [[ "$current_time" -ge "$sunrise_local" && "$current_time" -lt "$sunset_local" ]]
}

apply_theme() {
    local theme_name="$1"
    log "Applying Omarchy theme: $theme_name"
    omarchy theme set "$theme_name"
}

case "${1:-}" in
    --light)
        apply_theme "$LIGHT_THEME"
        exit 0
        ;;
    --dark)
        apply_theme "$DARK_THEME"
        exit 0
        ;;
    --help)
        echo "Usage: $0 [--light|--dark|--help]"
        exit 0
        ;;
esac

if ! command -v omarchy >/dev/null 2>&1; then
    echo "❌ omarchy command not found."
    exit 1
fi

if is_daytime; then
    apply_theme "$LIGHT_THEME"
else
    apply_theme "$DARK_THEME"
fi
