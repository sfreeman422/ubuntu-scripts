#!/bin/bash

# Script to delete files and folders older than 30 days from Downloads folder
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

# Set the Downloads directory path
DOWNLOADS_DIR="/home/steve/Downloads"

# Log file to track deletions
LOG_FILE="/home/steve/scripts/downloads-cleanup.log"

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if Downloads directory exists
if [ ! -d "$DOWNLOADS_DIR" ]; then
    log_message "ERROR: Downloads directory does not exist: $DOWNLOADS_DIR"
    exit 1
fi

log_message "Starting cleanup of files older than 30 days in $DOWNLOADS_DIR"

# Count files and folders before deletion
BEFORE_COUNT=$(find "$DOWNLOADS_DIR" -mindepth 1 -type f | wc -l)
BEFORE_DIRS=$(find "$DOWNLOADS_DIR" -mindepth 1 -type d | wc -l)

log_message "Before cleanup: $BEFORE_COUNT files and $BEFORE_DIRS directories"

# Find and delete files older than 30 days
log_message "Deleting files older than 30 days..."
find "$DOWNLOADS_DIR" -type f -mtime +30 -exec rm -f {} \; -print | while read file; do
    log_message "Deleted file: $file"
done

# Find and delete empty directories (after files are deleted)
log_message "Deleting empty directories..."
find "$DOWNLOADS_DIR" -type d -empty -delete -print | while read dir; do
    log_message "Deleted empty directory: $dir"
done

# Find and delete directories older than 30 days (that are not empty)
log_message "Deleting directories older than 30 days..."
find "$DOWNLOADS_DIR" -type d -mtime +30 -exec rm -rf {} \; -print 2>/dev/null | while read dir; do
    log_message "Deleted directory: $dir"
done

# Count files and folders after deletion
AFTER_COUNT=$(find "$DOWNLOADS_DIR" -mindepth 1 -type f | wc -l)
AFTER_DIRS=$(find "$DOWNLOADS_DIR" -mindepth 1 -type d | wc -l)

log_message "After cleanup: $AFTER_COUNT files and $AFTER_DIRS directories"
log_message "Cleanup completed. Removed $((BEFORE_COUNT - AFTER_COUNT)) files and $((BEFORE_DIRS - AFTER_DIRS)) directories"

# Show disk space freed (approximate)
if command -v du >/dev/null 2>&1; then
    CURRENT_SIZE=$(du -sh "$DOWNLOADS_DIR" 2>/dev/null | cut -f1)
    log_message "Current Downloads folder size: $CURRENT_SIZE"
fi

echo "Cleanup completed successfully. Check $LOG_FILE for details."