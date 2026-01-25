#!/bin/bash

# Ubuntu Theme Automation Script
# Automatically switches between light and dark themes based on sunrise/sunset
# Supports: GNOME, XFCE
# Author: Steve Freeman
# Date: 2025-01-24

# Source the desktop environment library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"
if [[ -f "$LIB_DIR/desktop-environment.sh" ]]; then
    source "$LIB_DIR/desktop-environment.sh"
else
    echo "❌ Error: desktop-environment.sh not found at $LIB_DIR"
    exit 1
fi

LOG_FILE="$HOME/.theme-automation.log"
CACHE_DIR="$HOME/.cache/theme-automation"
LOCATION_CACHE="$CACHE_DIR/location.json"
SUNRISE_CACHE="$CACHE_DIR/sunrise_data.json"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to get location by IP address
get_location_by_ip() {
    log "Getting location by IP address..."
    
    # Try ipinfo.io first
    local location_data=$(curl -s "http://ipinfo.io/json" 2>/dev/null)
    if [[ $? -eq 0 && -n "$location_data" ]]; then
        local lat=$(echo "$location_data" | jq -r '.loc' | cut -d',' -f1)
        local lon=$(echo "$location_data" | jq -r '.loc' | cut -d',' -f2)
        local city=$(echo "$location_data" | jq -r '.city')
        local region=$(echo "$location_data" | jq -r '.region')
        
        if [[ "$lat" != "null" && "$lon" != "null" ]]; then
            echo "{\"lat\": $lat, \"lon\": $lon, \"city\": \"$city\", \"region\": \"$region\", \"method\": \"ip\"}" > "$LOCATION_CACHE"
            log "Location found via IP: $city, $region ($lat, $lon)"
            return 0
        fi
    fi
    
    # Fallback to another IP geolocation service
    location_data=$(curl -s "http://ip-api.com/json" 2>/dev/null)
    if [[ $? -eq 0 && -n "$location_data" ]]; then
        local lat=$(echo "$location_data" | jq -r '.lat')
        local lon=$(echo "$location_data" | jq -r '.lon')
        local city=$(echo "$location_data" | jq -r '.city')
        local region=$(echo "$location_data" | jq -r '.regionName')
        
        if [[ "$lat" != "null" && "$lon" != "null" ]]; then
            echo "{\"lat\": $lat, \"lon\": $lon, \"city\": \"$city\", \"region\": \"$region\", \"method\": \"ip\"}" > "$LOCATION_CACHE"
            log "Location found via IP (fallback): $city, $region ($lat, $lon)"
            return 0
        fi
    fi
    
    log "Failed to get location by IP"
    return 1
}

# Function to get location using system location services (if available)
get_location_by_gps() {
    log "Attempting to get location via GPS/location services..."
    
    # Check if geoclue is available (GNOME location services)
    if command -v gdbus >/dev/null 2>&1; then
        # Try to get location from GNOME location services
        local location_data=$(timeout 10 gdbus call --session \
            --dest org.freedesktop.GeoClue2 \
            --object-path /org/freedesktop/GeoClue2/Manager \
            --method org.freedesktop.GeoClue2.Manager.GetClient 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            log "GPS location services not readily accessible, falling back to IP"
            return 1
        fi
    fi
    
    return 1
}

# Function to get cached location or fetch new one
get_location() {
    # Check if we have a cached location (valid for 24 hours)
    if [[ -f "$LOCATION_CACHE" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$LOCATION_CACHE")))
        if [[ $cache_age -lt 86400 ]]; then  # 24 hours
            log "Using cached location data"
            return 0
        fi
    fi
    
    log "Getting fresh location data..."
    
    # Try GPS first, then fall back to IP
    if ! get_location_by_gps; then
        if ! get_location_by_ip; then
            log "Failed to get location data"
            return 1
        fi
    fi
    
    return 0
}

# Function to get sunrise/sunset times
get_sunrise_sunset() {
    if ! get_location; then
        return 1
    fi
    
    local lat=$(jq -r '.lat' "$LOCATION_CACHE")
    local lon=$(jq -r '.lon' "$LOCATION_CACHE")
    
    log "Getting sunrise/sunset data for coordinates: $lat, $lon"
    
    # Use sunrise-sunset.org API
    local today=$(date +%Y-%m-%d)
    local api_url="https://api.sunrise-sunset.org/json?lat=$lat&lng=$lon&date=$today&formatted=0"
    
    local sunrise_data=$(curl -s "$api_url" 2>/dev/null)
    if [[ $? -eq 0 && -n "$sunrise_data" ]]; then
        local status=$(echo "$sunrise_data" | jq -r '.status')
        if [[ "$status" == "OK" ]]; then
            echo "$sunrise_data" > "$SUNRISE_CACHE"
            log "Sunrise/sunset data retrieved successfully"
            return 0
        fi
    fi
    
    log "Failed to get sunrise/sunset data"
    return 1
}

# Function to convert UTC time to local time
utc_to_local() {
    local utc_time="$1"
    # Convert ISO 8601 UTC time to local time epoch
    date -d "$utc_time" +%s
}

# Note: get_current_theme() is now provided by the library

# Note: set_firefox_theme() is now provided by the library

# Function to restart snap applications for theme changes
restart_snap_apps() {
    log "Theme changes will be picked up by snap apps automatically"
    log "If apps don't reflect theme changes, restart them manually"
    
    # Note: We removed automatic app killing to avoid interrupting user work
    # Modern apps should pick up theme changes automatically
}

# Function to set light theme
set_light_theme() {
    local de=$(detect_desktop_environment)
    log "Switching to light theme on $de..."
    
    case "$de" in
        gnome)
            # GNOME Yaru theme
            gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
            gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
            gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
            gsettings set org.gnome.desktop.wm.preferences theme 'Yaru'
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            
            if command -v gnome-shell >/dev/null 2>&1; then
                gsettings set org.gnome.shell.extensions.user-theme name 'Yaru' 2>/dev/null || true
            fi
            ;;
        xfce)
            # XFCE Xfce (default light theme)
            xfconf-query -c xsettings -p /Net/ThemeName -s "Xfce" 2>/dev/null || true
            xfconf-query -c xsettings -p /Net/IconThemeName -s "Xfce" 2>/dev/null || true
            xfconf-query -c xfwm4 -p /general/theme -s "Xfce" 2>/dev/null || true
            ;;
    esac
    
    # Configure Firefox for light theme
    set_firefox_theme "false"
    
    log "Light theme applied"
}

# Function to set dark theme
set_dark_theme() {
    local de=$(detect_desktop_environment)
    log "Switching to dark theme on $de..."
    
    case "$de" in
        gnome)
            # GNOME Yaru dark theme
            gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
            gsettings set org.gnome.desktop.interface icon-theme 'Yaru-dark'
            gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
            gsettings set org.gnome.desktop.wm.preferences theme 'Yaru-dark'
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            
            if command -v gnome-shell >/dev/null 2>&1; then
                gsettings set org.gnome.shell.extensions.user-theme name 'Yaru-dark' 2>/dev/null || true
            fi
            ;;
        xfce)
            # XFCE Xfce-dark theme
            xfconf-query -c xsettings -p /Net/ThemeName -s "Xfce-dark" 2>/dev/null || true
            xfconf-query -c xsettings -p /Net/IconThemeName -s "Xfce-dark" 2>/dev/null || true
            xfconf-query -c xfwm4 -p /general/theme -s "Xfce-dark" 2>/dev/null || true
            ;;
    esac
    
    # Configure Firefox for dark theme
    set_firefox_theme "true"
    
    log "Dark theme applied"
}

# Function to determine if it's currently day or night
is_daytime() {
    if ! get_sunrise_sunset; then
        # If we can't get sunrise/sunset data, default to time-based logic
        local hour=$(date +%H)
        if [[ $hour -ge 6 && $hour -lt 18 ]]; then
            return 0  # Day (6 AM to 6 PM)
        else
            return 1  # Night
        fi
    fi
    
    local sunrise_utc=$(jq -r '.results.sunrise' "$SUNRISE_CACHE")
    local sunset_utc=$(jq -r '.results.sunset' "$SUNRISE_CACHE")
    
    local sunrise_local=$(utc_to_local "$sunrise_utc")
    local sunset_local=$(utc_to_local "$sunset_utc")
    local current_time=$(date +%s)
    
    log "Sunrise: $(date -d @$sunrise_local '+%H:%M')"
    log "Sunset: $(date -d @$sunset_local '+%H:%M')"
    log "Current time: $(date '+%H:%M')"
    
    if [[ $current_time -ge $sunrise_local && $current_time -lt $sunset_local ]]; then
        return 0  # Daytime
    else
        return 1  # Nighttime
    fi
}

# Main function
main() {
    log "Theme automation script started"
    
    local de=$(detect_desktop_environment)
    log "Detected desktop environment: $de"
    
    # Check if we're running in a graphical environment
    if ! has_display; then
        log "No graphical environment detected, exiting"
        exit 1
    fi
    
    # Check if required commands are available
    if ! check_required_commands >/dev/null 2>&1; then
        log "Required command not found. Please install dependencies."
        exit 1
    fi
    
    # Check if a supported desktop environment is running
    if [[ "$de" != "gnome" && "$de" != "xfce" ]]; then
        log "Unsupported desktop environment: $de. This script supports GNOME and XFCE."
        echo "❌ Error: Unsupported desktop environment ($de). This script supports GNOME and XFCE."
        exit 1
    fi
    
    current_theme=$(get_current_theme)
    log "Current theme: $current_theme"
    
    if is_daytime; then
        log "It's daytime"
        if [[ "$current_theme" =~ -dark$ || "$current_theme" == *"dark"* ]]; then
            set_light_theme
        else
            log "Light theme already active"
        fi
    else
        log "It's nighttime"
        if [[ ! "$current_theme" =~ -dark$ && "$current_theme" != *"dark"* ]]; then
            set_dark_theme
        else
            log "Dark theme already active"
        fi
    fi
    
    log "Theme automation script completed"
}

# Handle command line arguments
case "${1:-}" in
    --light)
        set_light_theme
        log "Forced light theme applied (including Firefox)"
        exit 0
        ;;
    --dark)
        set_dark_theme
        log "Forced dark theme applied (including Firefox)"
        exit 0
        ;;
    --status)
        local de=$(detect_desktop_environment)
        echo "Desktop Environment: $de"
        if is_daytime; then
            echo "Daytime - Light theme should be active"
        else
            echo "Nighttime - Dark theme should be active"
        fi
        echo "Current theme: $(get_current_theme)"
        
        # Check Firefox configuration
        echo ""
        echo "Firefox Configuration:"
        if command -v firefox >/dev/null 2>&1; then
            echo "  Firefox: Installed"
            firefox_dir="$HOME/.mozilla/firefox"
            if [[ -d "$firefox_dir" ]]; then
                echo "  Profile directory: Found"
                profiles_ini="$firefox_dir/profiles.ini"
                if [[ -f "$profiles_ini" ]]; then
                    echo "  profiles.ini: Found"
                    # Find the user.js file
                    while IFS= read -r line; do
                        if [[ "$line" =~ ^Path=(.*)$ ]]; then
                            profile_path="${BASH_REMATCH[1]}"
                            user_js="$firefox_dir/$profile_path/user.js"
                            if [[ -f "$user_js" ]]; then
                                echo "  user.js: Found at $user_js"
                                if grep -q "ui.systemUsesDarkTheme" "$user_js"; then
                                    dark_setting=$(grep "ui.systemUsesDarkTheme" "$user_js" | tail -1)
                                    echo "  Current setting: $dark_setting"
                                else
                                    echo "  No theme setting found in user.js"
                                fi
                            else
                                echo "  user.js: Not found"
                            fi
                            break
                        fi
                    done < "$profiles_ini"
                else
                    echo "  profiles.ini: Not found"
                fi
            else
                echo "  Profile directory: Not found"
            fi
        else
            echo "  Firefox: Not installed"
        fi
        exit 0
        ;;
    --firefox-only)
        echo "Configuring Firefox theme only..."
        if is_daytime; then
            set_firefox_theme "false"
            echo "Firefox set to light theme"
        else
            set_firefox_theme "true"
            echo "Firefox set to dark theme"
        fi
        exit 0
        ;;
    --help)
        echo "Usage: $0 [--light|--dark|--status|--firefox-only|--help]"
        echo "  --light        Force light theme (includes Firefox)"
        echo "  --dark         Force dark theme (includes Firefox)"
        echo "  --status       Show current status and Firefox config"
        echo "  --firefox-only Configure Firefox theme only"
        echo "  --help         Show this help"
        echo "  (no args)      Auto-detect and set appropriate theme"
        exit 0
        ;;
esac

# Run main function
main
