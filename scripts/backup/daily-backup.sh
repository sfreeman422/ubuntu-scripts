#!/bin/bash

# Daily Home Directory Backup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

# Configuration
BACKUP_BASE_DIR="/media/steve/Backup/ubuntu-desktop"
SOURCE_DIR="/home/steve"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE_DIR/$DATE"
LOG_FILE="$BACKUP_DIR/backup.log"
MAX_BACKUPS=7  # Keep 7 days of backups
BACKUP_NAME="home_backup_$DATE.tar.gz"

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

log_message "Starting daily backup of home directory"

# Clean up old backups (keep only last MAX_BACKUPS)
log_message "Cleaning up old backup directories (keeping last $MAX_BACKUPS)"
cd "$BACKUP_BASE_DIR"

# Clean up old backup directories
find . -maxdepth 1 -type d ! -name "." -printf "%T@ %f\n" | \
    sort -nr | \
    tail -n +$((MAX_BACKUPS + 1)) | \
    while read timestamp dirname; do
        if [ -d "$dirname" ]; then
            rm -rf "$dirname"
            log_message "Removed old backup directory: $dirname"
        fi
    done

# Check available disk space and file system type
AVAILABLE_SPACE=$(df "$BACKUP_DIR" | awk 'NR==2{print $4}')
AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
FILESYSTEM=$(df -T "$BACKUP_DIR" | awk 'NR==2{print $2}')
REQUIRED_SPACE=5242880  # 5GB in KB

log_message "File system: $FILESYSTEM, Available space: ${AVAILABLE_GB}GB"

# Check for file system limitations
if [[ "$FILESYSTEM" == "vfat" || "$FILESYSTEM" == "fat32" ]]; then
    log_message "WARNING: FAT32 filesystem detected. Files cannot exceed 4GB."
    # Use split archives for FAT32
    SPLIT_SIZE="3G"
elif [[ "$FILESYSTEM" == "exfat" ]]; then
    log_message "exFAT filesystem detected. Should support large files."
    SPLIT_SIZE=""
else
    log_message "Native Linux filesystem detected."
    SPLIT_SIZE=""
fi

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    log_message "ERROR: Insufficient disk space. Available: ${AVAILABLE_GB}GB, Required: 5GB"
    exit 1
fi

log_message "Disk space check passed. Available: ${AVAILABLE_GB}GB"

# Create exclusion list for items we don't want to backup
EXCLUDE_FILE="$BACKUP_DIR/exclude.txt"
cat > "$EXCLUDE_FILE" << EOF
.cache
.local/share/Trash
.local/share/Steam
.thumbnails
Downloads
.mozilla/firefox/*/Cache*
.config/google-chrome/*/Cache*
.config/chromium/*/Cache*
.config/Code/logs
.config/Code/CachedData
.config/Code/User/workspaceStorage
.config/Code/User/History
node_modules
.npm
.yarn/cache
.gradle
.docker
.virtualbox
.vagrant
.steam
.bun
.rustup
.cargo/registry
.go/pkg
.local/share/virtualenv
.vscode/extensions
*.log
*.tmp
*~
.DS_Store
Thumbs.db
core
*.core
*.pid
.git/objects/pack/*.pack
.git/objects/pack/*.idx
Games
snap
EOF

log_message "Created exclusion list with $(wc -l < "$EXCLUDE_FILE") exclusion patterns"

# Log what will be excluded (for debugging)
log_message "Checking which large directories will be excluded:"
# Read exclude file and check directories (skip patterns with wildcards)
while IFS= read -r exclude_pattern; do
    # Skip empty lines, comments, and patterns with wildcards
    [[ -z "$exclude_pattern" || "$exclude_pattern" =~ ^# || "$exclude_pattern" =~ [\*\?] ]] && continue
    
    if [ -d "$SOURCE_DIR/$exclude_pattern" ]; then
        SIZE=$(du -sh "$SOURCE_DIR/$exclude_pattern" 2>/dev/null | cut -f1)
        log_message "  Found $exclude_pattern (${SIZE}) - will be excluded from backup"
    fi
done < "$EXCLUDE_FILE"

# Verify source directory is intact
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "ERROR: Source directory $SOURCE_DIR does not exist!"
    exit 1
fi

log_message "Source directory verification passed: $SOURCE_DIR exists and is accessible"

# Count files before backup
TOTAL_FILES=$(find "$SOURCE_DIR" -type f | wc -l)
log_message "Total files in source directory: $TOTAL_FILES"

# Create the backup with progress indication
log_message "Creating backup: $BACKUP_NAME"

# Check if backup directory is accessible
if [ ! -w "$BACKUP_DIR" ]; then
    log_message "ERROR: Cannot write to backup directory: $BACKUP_DIR"
    exit 1
fi

# Estimate backup size first
log_message "Estimating backup size..."

# First try using tar for size estimation
log_message "Attempting primary size estimation method..."
ESTIMATED_SIZE=$(tar --exclude-from="$EXCLUDE_FILE" \
                    --exclude="$BACKUP_DIR" \
                    --totals \
                    --warning=no-file-changed \
                    --warning=no-file-removed \
                    --dry-run \
                    -cf /dev/null \
                    -C "$SOURCE_DIR" . 2>&1 | \
                grep "Total bytes written:" | \
                awk '{print $4}' | \
                tr -d '()')

if [[ -n "$ESTIMATED_SIZE" && "$ESTIMATED_SIZE" -gt 0 ]]; then
    ESTIMATED_GB=$((ESTIMATED_SIZE / 1024 / 1024 / 1024))
    log_message "Estimated backup size (with exclusions): ${ESTIMATED_GB}GB"
else
    # Fallback: calculate manually with exclusions from exclude file
    log_message "Using fallback size estimation method..."
    
    # Create temporary find command script
    FIND_SCRIPT=$(mktemp)
    echo '#!/bin/bash' > "$FIND_SCRIPT"
    echo "cd '$SOURCE_DIR'" >> "$FIND_SCRIPT"
    echo -n "find . -type f " >> "$FIND_SCRIPT"
    
    # Add exclusions from exclude file
    while IFS= read -r pattern; do
        # Skip empty lines and comments
        [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
        echo -n "-not -path '*/$pattern' -not -path '*/$pattern/*' " >> "$FIND_SCRIPT"
    done < "$EXCLUDE_FILE"
    
    echo "-exec du -b {} + 2>/dev/null" >> "$FIND_SCRIPT"
    chmod +x "$FIND_SCRIPT"
    
    # Execute the find command
    ESTIMATED_SIZE=$("$FIND_SCRIPT" | awk '{sum+=$1} END {print sum}')
    rm -f "$FIND_SCRIPT"
    
    if [[ -n "$ESTIMATED_SIZE" && "$ESTIMATED_SIZE" -gt 0 ]]; then
        ESTIMATED_GB=$((ESTIMATED_SIZE / 1024 / 1024 / 1024))
        log_message "Estimated backup size (with exclusions): ${ESTIMATED_GB}GB"
    else
        log_message "WARNING: Both size estimation methods failed. Proceeding with backup anyway."
        ESTIMATED_GB=0
    fi
fi

# Choose backup method based on file system and size
if [[ "$FILESYSTEM" == "vfat" || "$FILESYSTEM" == "fat32" ]] && [[ "$ESTIMATED_GB" -gt 3 ]]; then
    log_message "Using split archives due to FAT32 file system limitations"
    BACKUP_BASE="${BACKUP_DIR}/home_backup_${DATE}"
    
    # SAFETY: Verify source directory before backup
    log_message "Pre-backup verification: Checking Downloads directory exists"
    if [ -d "$SOURCE_DIR/Downloads" ]; then
        DOWNLOADS_COUNT=$(find "$SOURCE_DIR/Downloads" -type f 2>/dev/null | wc -l)
        log_message "Downloads directory contains $DOWNLOADS_COUNT files (this should remain unchanged)"
    fi
    
    # Create backup with split using simpler method
    log_message "Creating compressed tar archive and splitting..."
    log_message "Command: tar --exclude-from=$EXCLUDE_FILE --exclude=$BACKUP_DIR -cf - -C $SOURCE_DIR . | gzip | split"
    
    if timeout 3600 tar --exclude-from="$EXCLUDE_FILE" \
           --exclude="$BACKUP_DIR" \
           --warning=no-file-changed \
           --warning=no-file-removed \
           -cf - \
           -C "$SOURCE_DIR" . 2>"$BACKUP_DIR/tar_errors.log" | \
       gzip | \
       split -b 3G - "$BACKUP_BASE.tar.gz.part"; then
        
        # Count and rename split files
        PART_COUNT=$(ls "$BACKUP_BASE.tar.gz.part"* | wc -l)
        log_message "Created $PART_COUNT archive parts"
        
        BACKUP_SIZE=$(du -sh "$BACKUP_BASE.tar.gz.part"* 2>/dev/null | awk '{sum+=$1} END {print sum}')
        log_message "Split backup completed successfully. Total size: ${BACKUP_SIZE}"
        BACKUP_NAME="home_backup_${DATE}.tar.gz.part*"
        IS_SPLIT=true
        
        # SAFETY: Verify source directory after backup
        log_message "Post-backup verification: Checking Downloads directory still exists"
        if [ -d "$SOURCE_DIR/Downloads" ]; then
            DOWNLOADS_COUNT_AFTER=$(find "$SOURCE_DIR/Downloads" -type f 2>/dev/null | wc -l)
            log_message "Downloads directory still contains $DOWNLOADS_COUNT_AFTER files"
            if [ "$DOWNLOADS_COUNT" != "$DOWNLOADS_COUNT_AFTER" ]; then
                log_message "WARNING: Downloads file count changed during backup!"
            fi
        else
            log_message "ERROR: Downloads directory was deleted during backup process!"
            exit 1
        fi
    else
        log_message "ERROR: Split backup failed or timed out after 1 hour"
        if [ -f "$BACKUP_DIR/tar_errors.log" ]; then
            log_message "Tar error details:"
            cat "$BACKUP_DIR/tar_errors.log" >> "$LOG_FILE"
        fi
        exit 1
    fi
else
    # Create regular single-file backup
    log_message "Creating single archive file"
    IS_SPLIT=false
    
    # SAFETY: Verify source directory before backup
    log_message "Pre-backup verification: Checking Downloads directory exists"
    if [ -d "$SOURCE_DIR/Downloads" ]; then
        DOWNLOADS_COUNT=$(find "$SOURCE_DIR/Downloads" -type f 2>/dev/null | wc -l)
        log_message "Downloads directory contains $DOWNLOADS_COUNT files (this should remain unchanged)"
    fi
    
    log_message "Command: tar --exclude-from=$EXCLUDE_FILE --exclude=$BACKUP_DIR -czf $BACKUP_DIR/$BACKUP_NAME -C $SOURCE_DIR ."
    
    if timeout 3600 tar --exclude-from="$EXCLUDE_FILE" \
           --exclude="$BACKUP_DIR" \
           --warning=no-file-changed \
           --warning=no-file-removed \
           -czf "$BACKUP_DIR/$BACKUP_NAME" \
           -C "$SOURCE_DIR" . 2>"$BACKUP_DIR/tar_errors.log"; then
        
        BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
        log_message "Backup completed successfully. Size: $BACKUP_SIZE"
        
        # SAFETY: Verify source directory after backup
        log_message "Post-backup verification: Checking Downloads directory still exists"
        if [ -d "$SOURCE_DIR/Downloads" ]; then
            DOWNLOADS_COUNT_AFTER=$(find "$SOURCE_DIR/Downloads" -type f 2>/dev/null | wc -l)
            log_message "Downloads directory still contains $DOWNLOADS_COUNT_AFTER files"
            if [ "$DOWNLOADS_COUNT" != "$DOWNLOADS_COUNT_AFTER" ]; then
                log_message "WARNING: Downloads file count changed during backup!"
            fi
        else
            log_message "ERROR: Downloads directory was deleted during backup process!"
            exit 1
        fi
    else
        log_message "ERROR: Regular backup failed or timed out after 1 hour"
        if [ -f "$BACKUP_DIR/tar_errors.log" ]; then
            log_message "Tar error details:"
            cat "$BACKUP_DIR/tar_errors.log" >> "$LOG_FILE"
        fi
        exit 1
    fi
fi

# Check for any warnings in the error log
if [ -s "$BACKUP_DIR/tar_errors.log" ]; then
    log_message "Tar warnings (non-critical):"
    while read line; do
        log_message "  $line"
    done < "$BACKUP_DIR/tar_errors.log"
fi
rm -f "$BACKUP_DIR/tar_errors.log"

# Test backup integrity
log_message "Testing backup integrity..."
if [[ "$IS_SPLIT" == true ]]; then
    # Test split backup integrity
    BACKUP_BASE="${BACKUP_DIR}/home_backup_${DATE}"
    log_message "Testing split archive integrity..."
    if cat "$BACKUP_BASE.tar.gz.part"* | tar -tzf - >/dev/null 2>&1; then
        log_message "Split backup integrity test passed"
    else
        log_message "ERROR: Split backup integrity test failed"
        log_message "To manually restore: cat home_backup_${DATE}.tar.gz.part* | tar -xzf -"
        exit 1
    fi
else
    # Test regular backup integrity
    if tar -tzf "$BACKUP_DIR/$BACKUP_NAME" >/dev/null 2>&1; then
        log_message "Backup integrity test passed"
    else
        log_message "ERROR: Backup integrity test failed"
        exit 1
    fi
fi

# Show backup statistics
TOTAL_BACKUP_DIRS=$(ls -1d "$BACKUP_BASE_DIR"/*/ 2>/dev/null | wc -l)
CURRENT_BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
TOTAL_BACKUP_SIZE=$(du -sh "$BACKUP_BASE_DIR" | cut -f1)
log_message "Backup statistics: $TOTAL_BACKUP_DIRS backup directories, Current backup: $CURRENT_BACKUP_SIZE, Total size: $TOTAL_BACKUP_SIZE"

# Send notification (if desktop environment available)
if command -v notify-send >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
    notify-send "Backup Complete" "Home directory backup completed successfully. Size: $BACKUP_SIZE"
fi

log_message "Daily backup completed successfully"

# Add restore instructions to log
if [[ "$IS_SPLIT" == true ]]; then
    log_message "To restore split backup: mkdir -p /tmp/restore && cd /tmp/restore && cat $BACKUP_DIR/home_backup_${DATE}.tar.gz.part* | tar --no-same-owner --no-same-permissions -xzf -"
else
    log_message "To restore backup: mkdir -p /tmp/restore && cd /tmp/restore && tar --no-same-owner --no-same-permissions -xzf $BACKUP_DIR/$BACKUP_NAME"
fi

# Optional: Upload to cloud storage (uncomment and configure as needed)
# log_message "Uploading to cloud storage..."
# rsync -avz "$BACKUP_DIR/$BACKUP_NAME" user@remote-server:/path/to/remote/backups/
# log_message "Cloud upload completed"

echo "Backup completed. Check $LOG_FILE for details."
