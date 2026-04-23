#!/bin/bash

# Desktop Environment Detection Library
# Provides GNOME-focused helper functions for Ubuntu scripts
# Supports: GNOME
# Author: Steve Freeman
# Date: 2025-01-24

# Detect the current desktop environment
detect_desktop_environment() {
    # Check environment variables first
    if [[ -n "$DESKTOP_SESSION" ]]; then
        case "$DESKTOP_SESSION" in
            gnome|ubuntu|pop)
                echo "gnome"
                return 0
                ;;
        esac
    fi
    
    # Check XDG_CURRENT_DESKTOP
    if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
        case "$XDG_CURRENT_DESKTOP" in
            *GNOME*)
                echo "gnome"
                return 0
                ;;
        esac
    fi
    
    # Check for specific binaries
    if command -v gnome-shell >/dev/null 2>&1; then
        echo "gnome"
        return 0
    fi
    
    # Return unknown if we can't detect GNOME
    echo "unknown"
    return 1
}

# Check if a specific desktop environment is running
is_desktop_environment() {
    local target_de="$1"
    local current_de=$(detect_desktop_environment)
    [[ "$current_de" == "$target_de" ]]
}

# Get the current GTK theme for GNOME
get_gnome_gtk_theme() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'"
    else
        echo "Yaru"
    fi
}

# Get current theme
get_current_theme() {
    local de=$(detect_desktop_environment)
    case "$de" in
        gnome)
            get_gnome_gtk_theme
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Set GNOME theme (light/dark)
set_gnome_theme() {
    local theme_type="$1"  # "light" or "dark"
    
    if ! command -v gsettings >/dev/null 2>&1; then
        return 1
    fi
    
    if [[ "$theme_type" == "light" ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
        gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
        gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
        gsettings set org.gnome.desktop.wm.preferences theme 'Yaru'
        
        if command -v gnome-shell >/dev/null 2>&1; then
            gsettings set org.gnome.shell.extensions.user-theme name 'Yaru' 2>/dev/null || true
        fi
        
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    else
        gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
        gsettings set org.gnome.desktop.interface icon-theme 'Yaru-dark'
        gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
        gsettings set org.gnome.desktop.wm.preferences theme 'Yaru-dark'
        
        if command -v gnome-shell >/dev/null 2>&1; then
            gsettings set org.gnome.shell.extensions.user-theme name 'Yaru-dark' 2>/dev/null || true
        fi
        
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    fi
    
    return 0
}

# Set theme for current desktop environment
set_theme() {
    local theme_type="$1"  # "light" or "dark"
    local de=$(detect_desktop_environment)
    
    case "$de" in
        gnome)
            set_gnome_theme "$theme_type"
            ;;
        *)
            return 1
            ;;
    esac
}

# Configure Firefox theme
set_firefox_theme() {
    local use_dark_theme="$1"  # "true" or "false"
    
    if ! command -v firefox >/dev/null 2>&1; then
        return 0
    fi
    
    local firefox_dir="$HOME/.mozilla/firefox"
    
    if [[ ! -d "$firefox_dir" ]]; then
        return 0
    fi
    
    local profiles_ini="$firefox_dir/profiles.ini"
    if [[ ! -f "$profiles_ini" ]]; then
        return 0
    fi
    
    local default_profile=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^Path=(.*)$ ]]; then
            local profile_path="${BASH_REMATCH[1]}"
            if [[ -d "$firefox_dir/$profile_path" ]]; then
                default_profile="$firefox_dir/$profile_path"
                break
            fi
        fi
    done < "$profiles_ini"
    
    if [[ -z "$default_profile" ]]; then
        return 0
    fi
    
    local user_js="$default_profile/user.js"
    
    if [[ -f "$user_js" ]]; then
        sed -i '/user_pref("ui\.systemUsesDarkTheme"/d' "$user_js"
        sed -i '/user_pref("layout\.css\.prefers-color-scheme\.content-override"/d' "$user_js"
    fi
    
    {
        echo "// Theme automation - auto-generated on $(date)"
        echo "user_pref(\"ui.systemUsesDarkTheme\", $(if [[ "$use_dark_theme" == "true" ]]; then echo "true"; else echo "false"; fi));"
        if [[ "$use_dark_theme" == "true" ]]; then
            echo "user_pref(\"layout.css.prefers-color-scheme.content-override\", 0);" # Dark
        else
            echo "user_pref(\"layout.css.prefers-color-scheme.content-override\", 1);" # Light
        fi
    } >> "$user_js"
    
    return 0
}

# Configure snap themes
configure_snap_themes() {
    local theme_type="$1"  # "light" or "dark"

    if command -v gsettings >/dev/null 2>&1; then
        if [[ "$theme_type" == "light" ]]; then
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        else
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        fi
    fi
    
    return 0
}

# Check if GUI environment is available
has_display() {
    if [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
        return 0
    else
        return 1
    fi
}

# Check if GNOME is installed
has_gnome() {
    command -v gnome-shell >/dev/null 2>&1
}

# Get required commands
get_required_commands() {
    local commands=("curl" "jq")

    commands+=("gsettings")
    
    echo "${commands[@]}"
}

# Check if all required commands are available
check_required_commands() {
    local commands=$(get_required_commands)
    local missing_commands=()
    
    for cmd in $commands; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        echo "${missing_commands[@]}"
        return 1
    fi
    
    return 0
}

# Install missing dependencies
install_missing_dependencies() {
    local missing_commands=$(check_required_commands)
    
    if [[ $? -eq 0 ]]; then
        return 0
    fi
    
    echo "Installing missing dependencies: $missing_commands"
    sudo apt update
    
    for cmd in $missing_commands; do
        case "$cmd" in
            curl)
                sudo apt install -y curl
                ;;
            jq)
                sudo apt install -y jq
                ;;
            gsettings)
                echo "Error: gsettings not found. GNOME Shell is required."
                return 1
                ;;
        esac
    done
    
    return 0
}
