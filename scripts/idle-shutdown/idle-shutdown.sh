#!/bin/bash
#
# idle-shutdown.sh - Auto-shutdown script for idle computers
#
# Shuts down the computer if it has been idle for more than 1 hour,
# but only between midnight and 5AM. Includes a 60-second warning
# notification and blocks shutdown if backups are running.
#
# Usage: Run via cron every 5 minutes between 03:00-04:59
#   */5 3-4 * * * DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus ~/scripts/idle-shutdown.sh
#

# Configuration
IDLE_THRESHOLD_MS=3600000  # 1 hour in milliseconds
LOG_FILE="$HOME/scripts/idle-shutdown.log"
BLOCKING_PROCESSES=("rsync" "daily-backup.sh" "tar")

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if current time is within allowed hours (03:00 - 05:00)
# Starts at 3AM to allow daily backup (2AM) time to complete
check_time_window() {
    local hour=$(date +%H)
    if [ "$hour" -ge 3 ] && [ "$hour" -lt 5 ]; then
        return 0
    fi
    return 1
}

# Get idle time in milliseconds
# Supports both X11 (xprintidle) and Wayland (GNOME dbus)
get_idle_time() {
    if [ -n "$DISPLAY" ]; then
        # X11: use xprintidle (returns milliseconds)
        xprintidle 2>/dev/null
    elif [ -n "$WAYLAND_DISPLAY" ]; then
        # Wayland: use gnome-session idle time via dbus
        dbus-send --print-reply --dest=org.gnome.Mutter.IdleMonitor \
            /org/gnome/Mutter/IdleMonitor/Core \
            org.gnome.Mutter.IdleMonitor.GetIdletime 2>/dev/null | \
            grep -oP 'uint64 \K[0-9]+'
    else
        # No display session detected
        echo ""
    fi
}

# Check if any blocking processes are running
check_blocking_processes() {
    for process in "${BLOCKING_PROCESSES[@]}"; do
        if pgrep -f "$process" > /dev/null 2>&1; then
            echo "$process"
            return 0
        fi
    done
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
    # Check time window first
    if ! check_time_window; then
        # Outside allowed hours - exit silently (no logging to avoid spam)
        exit 0
    fi

    log "Starting idle check"

    # Get idle time
    idle_time=$(get_idle_time)

    if [ -z "$idle_time" ]; then
        log "Could not detect display session (no DISPLAY or WAYLAND_DISPLAY). Exiting."
        exit 0
    fi

    # Convert to minutes for logging
    idle_minutes=$((idle_time / 60000))
    threshold_minutes=$((IDLE_THRESHOLD_MS / 60000))

    log "Idle time: ${idle_minutes} minutes (threshold: ${threshold_minutes} minutes)"

    # Check if idle threshold exceeded
    if [ "$idle_time" -lt "$IDLE_THRESHOLD_MS" ]; then
        log "System is active. No action needed."
        exit 0
    fi

    log "Idle threshold exceeded!"

    # Check for blocking processes
    blocking_process=$(check_blocking_processes)
    if [ -n "$blocking_process" ]; then
        log "Shutdown blocked - '$blocking_process' is running"
        exit 0
    fi

    log "No blocking processes found. Initiating shutdown sequence..."

    # Send warning notification
    send_notification "System Shutdown" \
        "Computer will shut down in 60 seconds due to inactivity.\n\nRun 'sudo shutdown -c' to cancel." \
        "critical"

    log "Warning notification sent. Scheduling shutdown in 1 minute."

    # Schedule shutdown in 1 minute
    sudo shutdown +1 "Idle shutdown - system inactive for over 1 hour"

    if [ $? -eq 0 ]; then
        log "Shutdown scheduled successfully"
    else
        log "ERROR: Failed to schedule shutdown (sudo permission issue?)"
    fi
}

# Run main function
main
