#!/bin/bash

# Backup Setup Script
# Sets up automated daily backups

SCRIPT_DIR="/home/steve/code/ubuntu-scripts"
BACKUP_SCRIPT="$SCRIPT_DIR/daily-backup.sh"

echo "Setting up automated daily backup..."

# Create scripts directory if it doesn't exist
mkdir -p ~/scripts

# Copy backup script to scripts directory
cp "$BACKUP_SCRIPT" ~/scripts/daily-backup.sh
chmod +x ~/scripts/daily-backup.sh

echo "Setting up cron job for daily backups at 2 AM..."

# Add cron job for daily backup at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * ~/scripts/daily-backup.sh") | crontab -

echo "Backup automation setup complete!"
echo ""
echo "Your backups will run daily at 2 AM and will:"
echo "- Backup your entire home directory to /media/steve/Backup/ubuntu-desktop"
echo "- Exclude cache files, downloads, and temporary files"
echo "- Keep 7 days of backups (automatically delete older ones)"
echo "- Log all activities to /media/steve/Backup/ubuntu-desktop/backup.log"
echo ""
echo "To run a backup manually: ~/scripts/daily-backup.sh"
echo "To check backup logs: cat /media/steve/Backup/ubuntu-desktop/backup.log"
echo ""
echo "Current cron jobs:"
crontab -l
