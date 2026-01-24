#!/bin/bash

# Ubuntu Theme Automation Script
# Automatically switches between light and dark themes based on sunrise/sunset
# Author: Steve Freeman
# Date: 2025-08-10

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

# Function to get current theme
get_current_theme() {
    gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'"
}

# Function to set Firefox theme preference
set_firefox_theme() {
    local use_dark_theme="$1"
    
    # Check if Firefox snap is installed
    if ! snap list firefox >/dev/null 2>&1; then
        log "Firefox snap not detected, skipping Firefox theme configuration"
        return 0
    fi
    
    # Find Firefox profile directories (snap version)
    local firefox_snap_dir="$HOME/snap/firefox/common/.mozilla/firefox"
    
    if [[ ! -d "$firefox_snap_dir" ]]; then
        log "Firefox snap profile directory not found, Firefox may not have been run yet"
        return 0
    fi
    
    # Find profiles.ini to get the correct profile path
    local profiles_ini="$firefox_snap_dir/profiles.ini"
    if [[ ! -f "$profiles_ini" ]]; then
        log "Firefox profiles.ini not found, skipping Firefox configuration"
        return 0
    fi
    
    # Parse profiles.ini to find default profile
    local default_profile=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^Path=(.*)$ ]]; then
            local profile_path="${BASH_REMATCH[1]}"
            # Check if this profile directory exists
            if [[ -d "$firefox_snap_dir/$profile_path" ]]; then
                default_profile="$firefox_snap_dir/$profile_path"
                break
            fi
        fi
    done < "$profiles_ini"
    
    if [[ -z "$default_profile" ]]; then
        log "No valid Firefox profile found, skipping Firefox configuration"
        return 0
    fi
    
    log "Configuring Firefox theme for profile: $default_profile"
    
    # Create user.js file with theme preference
    user_js="$default_profile/user.js"
    
    # Create or update user.js
    if [[ -f "$user_js" ]]; then
        # Remove existing ui.systemUsesDarkTheme preference
        sed -i '/user_pref("ui\.systemUsesDarkTheme"/d' "$user_js"
        sed -i '/user_pref("layout\.css\.prefers-color-scheme\.content-override"/d' "$user_js"
    fi
    
    # Add the theme preferences
    {
        echo "// Theme automation - auto-generated on $(date)"
        echo "user_pref(\"ui.systemUsesDarkTheme\", $use_dark_theme);"
        if [[ "$use_dark_theme" == "true" ]]; then
            echo "user_pref(\"layout.css.prefers-color-scheme.content-override\", 0);" # Dark
        else
            echo "user_pref(\"layout.css.prefers-color-scheme.content-override\", 1);" # Light
        fi
    } >> "$user_js"
    
    log "Firefox theme preference updated: ui.systemUsesDarkTheme = $use_dark_theme"
    
    # Try to signal Firefox to reload preferences if it's running
    if pgrep -f "firefox" >/dev/null 2>&1; then
        log "Firefox is running - preferences will take effect on next restart"
    fi
}

# Function to configure snap themes
configure_snap_themes() {
    local theme_name="$1"
    
    log "Configuring snap themes for: $theme_name"
    
    # Set theme environment variables for snaps (no sudo required)
    if [[ "$theme_name" == *"dark"* ]]; then
        log "Setting dark theme environment for snaps"
        # Set dark theme preference
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    else
        log "Setting light theme environment for snaps"
        # Set light theme preference  
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    fi
    
    log "Snap theme environment configured (no restart required)"
}

# Function to restart snap applications for theme changes
restart_snap_apps() {
    log "Theme changes will be picked up by snap apps automatically"
    log "If apps don't reflect theme changes, restart them manually"
    
    # Note: We removed automatic app killing to avoid interrupting user work
    # Modern snap apps should pick up the color-scheme changes automatically
}

# Function to setup snap interface connections (requires sudo, run once)
setup_snap_connections() {
    log "Setting up snap interface connections (requires sudo)..."
    
    # Check if gtk-common-themes is installed
    if ! snap list gtk-common-themes >/dev/null 2>&1; then
        echo "⚠️  gtk-common-themes not installed. Installing..."
        sudo snap install gtk-common-themes
    fi
    
    # Connect gtk-common-themes to snaps that need it
    local snap_apps=("firefox" "code" "discord" "spotify" "chromium" "thunderbird")
    
    for app in "${snap_apps[@]}"; do
        if snap list "$app" >/dev/null 2>&1; then
            echo "Connecting gtk-common-themes to $app..."
            sudo snap connect "$app:gtk-3-themes" gtk-common-themes:gtk-3-themes 2>/dev/null || true
            sudo snap connect "$app:icon-themes" gtk-common-themes:icon-themes 2>/dev/null || true
            sudo snap connect "$app:sound-themes" gtk-common-themes:sound-themes 2>/dev/null || true
            echo "✅ $app connected"
        fi
    done
    
    log "Snap interface connections completed"
}

# Function to set light theme
set_light_theme() {
    log "Switching to light theme..."
    
    # Set GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
    
    # Set icon theme
    gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
    
    # Set cursor theme
    gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
    
    # Set shell theme (if using GNOME Shell)
    if command -v gnome-shell >/dev/null 2>&1; then
        gsettings set org.gnome.shell.extensions.user-theme name 'Yaru'
    fi
    
    # Set window manager theme
    gsettings set org.gnome.desktop.wm.preferences theme 'Yaru'
    
    # Configure snap themes
    configure_snap_themes "Yaru"
    
    # Configure Firefox for light theme
    set_firefox_theme "false"
    
    log "Light theme applied"
}

# Function to set dark theme
set_dark_theme() {
    log "Switching to dark theme..."
    
    # Set GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
    
    # Set icon theme
    gsettings set org.gnome.desktop.interface icon-theme 'Yaru-dark'
    
    # Set cursor theme
    gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
    
    # Set shell theme (if using GNOME Shell)
    if command -v gnome-shell >/dev/null 2>&1; then
        gsettings set org.gnome.shell.extensions.user-theme name 'Yaru-dark'
    fi
    
    # Set window manager theme
    gsettings set org.gnome.desktop.wm.preferences theme 'Yaru-dark'
    
    # Configure snap themes
    configure_snap_themes "Yaru-dark"
    
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
    
    # Check if GNOME is being used
    if ! command -v gnome-shell >/dev/null 2>&1; then
        log "GNOME Shell not detected. Theme automation requires GNOME desktop environment."
        echo "❌ Error: GNOME Shell not detected. This script requires GNOME."
        exit 1
    fi
    
    # Check if we're running in a graphical environment
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
        log "No graphical environment detected, exiting"
        exit 1
    fi
    
    # Check if required commands are available
    for cmd in curl jq gsettings; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "Required command '$cmd' not found. Please install it first."
            exit 1
        fi
    done
    
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
        if is_daytime; then
            echo "Daytime - Light theme should be active"
        else
            echo "Nighttime - Dark theme should be active"
        fi
        echo "Current theme: $(get_current_theme)"
        
        # Check Firefox configuration
        echo ""
        echo "Firefox Configuration:"
        if snap list firefox >/dev/null 2>&1; then
            echo "  Firefox snap: Installed"
            firefox_snap_dir="$HOME/snap/firefox/common/.mozilla/firefox"
            if [[ -d "$firefox_snap_dir" ]]; then
                echo "  Profile directory: Found"
                profiles_ini="$firefox_snap_dir/profiles.ini"
                if [[ -f "$profiles_ini" ]]; then
                    echo "  profiles.ini: Found"
                    # Find the user.js file
                    while IFS= read -r line; do
                        if [[ "$line" =~ ^Path=(.*)$ ]]; then
                            profile_path="${BASH_REMATCH[1]}"
                            user_js="$firefox_snap_dir/$profile_path/user.js"
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
            echo "  Firefox snap: Not installed"
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
    --snap-setup)
        echo "Setting up snap theme connections (requires sudo)..."
        setup_snap_connections
        echo "Snap theme connections configured"
        echo "Theme automation will now work without requiring authentication"
        exit 0
        ;;
    --help)
        echo "Usage: $0 [--light|--dark|--status|--firefox-only|--snap-setup|--help]"
        echo "  --light        Force light theme (includes Firefox and snaps)"
        echo "  --dark         Force dark theme (includes Firefox and snaps)"
        echo "  --status       Show current status and Firefox config"
        echo "  --firefox-only Configure Firefox theme only"
        echo "  --snap-setup   Setup snap theme connections (one-time, requires sudo)"
        echo "  --help         Show this help"
        echo "  (no args)      Auto-detect and set appropriate theme"
        exit 0
        ;;
esac

# Run main function
main
