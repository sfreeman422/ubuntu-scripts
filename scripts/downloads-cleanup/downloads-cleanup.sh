#!/bin/bash

# Script to delete files and folders older than 30 days from Downloads folder
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

# Set the Downloads directory path
DOWNLOADS_DIR="$HOME/Downloads"

# Log file to track deletions
LOG_FILE="$HOME/scripts/downloads-cleanup.log"

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Validate the cleanup root before performing any destructive operation.
# Refuse symlinks or path surprises: this job may only operate on the literal
# $HOME/Downloads directory.
if [ ! -d "$DOWNLOADS_DIR" ]; then
    log_message "ERROR: Downloads directory does not exist: $DOWNLOADS_DIR"
    exit 1
fi

HOME_REAL=$(realpath -e -- "$HOME") || {
    log_message "ERROR: Unable to resolve home directory: $HOME"
    exit 1
}
DOWNLOADS_REAL=$(realpath -e -- "$DOWNLOADS_DIR") || {
    log_message "ERROR: Unable to resolve Downloads directory: $DOWNLOADS_DIR"
    exit 1
}

if [ "$DOWNLOADS_REAL" != "$HOME_REAL/Downloads" ]; then
    log_message "ERROR: Refusing cleanup because Downloads resolves outside the expected path: $DOWNLOADS_REAL"
    exit 1
fi

log_message "Starting cleanup of files older than 30 days in $DOWNLOADS_REAL"

# Count files and folders before deletion
BEFORE_COUNT=$(find "$DOWNLOADS_REAL" -xdev -mindepth 1 -type f | wc -l)
BEFORE_DIRS=$(find "$DOWNLOADS_REAL" -xdev -mindepth 1 -type d | wc -l)

log_message "Before cleanup: $BEFORE_COUNT files and $BEFORE_DIRS directories"

# Find and delete files older than 30 days
log_message "Deleting files older than 30 days..."
while IFS= read -r -d '' file; do
    if rm -f -- "$file"; then
        log_message "Deleted file: $file"
    else
        log_message "ERROR: Failed to delete file: $file"
    fi
done < <(find "$DOWNLOADS_REAL" -xdev -mindepth 1 -type f -mtime +30 -print0)

# Find and delete empty directories (after files are deleted)
log_message "Deleting empty directories (excluding Downloads root)..."
while IFS= read -r -d '' dir; do
    if rmdir -- "$dir" 2>/dev/null; then
        log_message "Deleted empty directory: $dir"
    fi
done < <(find "$DOWNLOADS_REAL" -xdev -mindepth 1 -depth -type d -empty -print0)

# Do not recursively delete non-empty directories by age.
# A parent directory can be old while containing recent files.

# Count files and folders after deletion
AFTER_COUNT=$(find "$DOWNLOADS_REAL" -xdev -mindepth 1 -type f | wc -l)
AFTER_DIRS=$(find "$DOWNLOADS_REAL" -xdev -mindepth 1 -type d | wc -l)

log_message "After cleanup: $AFTER_COUNT files and $AFTER_DIRS directories"
log_message "Cleanup completed. Removed $((BEFORE_COUNT - AFTER_COUNT)) files and $((BEFORE_DIRS - AFTER_DIRS)) directories"

# Show disk space freed (approximate)
if command -v du >/dev/null 2>&1; then
    CURRENT_SIZE=$(du -sh "$DOWNLOADS_REAL" 2>/dev/null | cut -f1)
    log_message "Current Downloads folder size: $CURRENT_SIZE"
fi

echo "Cleanup completed successfully. Check $LOG_FILE for details."