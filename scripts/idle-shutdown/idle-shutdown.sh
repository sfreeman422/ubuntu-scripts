#!/bin/bash
#
# idle-shutdown.sh - Auto-shutdown script for idle computers
#
# Shuts down the computer if the backup script is not running AND
# (there is no active user session OR the screen is turned off).
# Includes a 60-second warning notification.
#
# Usage: Run via cron every 5 minutes
#   */5 * * * * ~/scripts/idle-shutdown.sh
#

# Configuration
LOG_FILE="$HOME/scripts/idle-shutdown.log"
BACKUP_SCRIPT="daily-backup.sh"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Auto-detect display session when running from cron
setup_display_env() {
    # If DISPLAY or WAYLAND_DISPLAY is already set, we're good
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        return 0
    fi

    # Find the active graphical session for the current user
    local session_id
    session_id=$(loginctl list-sessions --no-legend 2>/dev/null | \
        awk -v user="$USER" '$3 == user {print $1; exit}')

    if [ -z "$session_id" ]; then
        return 1
    fi

    # Get session type (x11 or wayland)
    local session_type
    session_type=$(loginctl show-session "$session_id" -p Type --value 2>/dev/null)

    if [ "$session_type" = "x11" ]; then
        export DISPLAY=$(loginctl show-session "$session_id" -p Display --value 2>/dev/null)
    elif [ "$session_type" = "wayland" ]; then
        export WAYLAND_DISPLAY="wayland-0"
    fi

    # Set up DBUS session bus if not already set
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        local uid=$(id -u)
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus"
    fi

    return 0
}

# Check if backup script is running
check_backup_running() {
    if pgrep -f "$BACKUP_SCRIPT" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Check if screen is turned off
# Returns 0 if screen is off, 1 if on
check_screen_off() {
    if [ -n "$DISPLAY" ]; then
        # X11: check DPMS status
        local dpms_state=$(xset q 2>/dev/null | grep -i "monitor is" | awk '{print $NF}')
        if [ "$dpms_state" = "Off" ]; then
            return 0
        fi
    elif [ -n "$WAYLAND_DISPLAY" ]; then
        # Wayland/GNOME: check if screen is locked or idle
        local screen_state=$(dbus-send --print-reply --dest=org.gnome.ScreenSaver \
            /org/gnome/ScreenSaver org.gnome.ScreenSaver.GetActive 2>/dev/null | \
            grep -oP 'boolean \K(true|false)')
        if [ "$screen_state" = "true" ]; then
            return 0
        fi
    fi
    return 1
}

# Check if there is an active user session
# Returns 0 if active session exists, 1 if no active session
check_active_user_session() {
    # Check if there's any active graphical session for any user
    local active_sessions=$(loginctl list-sessions --no-legend 2>/dev/null | \
        awk '{print $1}' | wc -l)
    
    if [ "$active_sessions" -gt 0 ]; then
        return 0
    fi
    return 1
}

# Send desktop notification
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"

    # Try notify-send with DISPLAY/DBUS environment
    if command -v notify-send &> /dev/null; then
        notify-send -u "$urgency" "$title" "$message" 2>/dev/null
    fi
}

# Main execution
main() {
    log "Starting shutdown check"

    # Check if backup is running
    if check_backup_running; then
        log "Backup script is running. Shutdown blocked."
        exit 0
    fi

    log "Backup script is not running."

    # Auto-detect display environment if running from cron
    setup_display_env

    # Check if there is an active user session
    local has_active_session=false
    if check_active_user_session; then
        has_active_session=true
        log "Active user session detected."
    else
        log "No active user session."
    fi

    # Check if screen is off
    local screen_is_off=false
    if check_screen_off; then
        screen_is_off=true
        log "Screen is turned off."
    else
        log "Screen is on."
    fi

    # Shutdown if: no active session OR screen is off
    if [ "$has_active_session" = false ] || [ "$screen_is_off" = true ]; then
        log "Shutdown conditions met. Initiating shutdown sequence..."

        # Send warning notification
        send_notification "System Shutdown" \
            "Computer will shut down in 60 seconds.\n\nRun 'sudo shutdown -c' to cancel." \
            "critical"

        log "Warning notification sent. Scheduling shutdown in 1 minute."

        # Schedule shutdown in 1 minute
        sudo shutdown +1 "Auto-shutdown: backup not running and (no active session or screen off)"

        if [ $? -eq 0 ]; then
            log "Shutdown scheduled successfully"
        else
            log "ERROR: Failed to schedule shutdown (sudo permission issue?)"
        fi
    else
        log "Shutdown conditions not met. Active session exists and screen is on."
        exit 0
    fi
}

# Run main function
main
