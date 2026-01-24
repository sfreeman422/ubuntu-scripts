#!/bin/bash

# Backup Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")
# Sets up automated daily backups

echo "========================================="
echo "Backup Automation Setup Starting..."
echo "========================================="

# Get the script directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/daily-backup.sh"

# Prompt user for backup destination
echo "Please specify where to store backups:"
echo "(Default: /media/$USER/Backup/ubuntu-desktop)"
read -p "Backup destination: " BACKUP_DEST
BACKUP_DEST=${BACKUP_DEST:-/media/$USER/Backup/ubuntu-desktop}

echo ""
echo "Backing up from: $HOME"
echo "Backing up to: $BACKUP_DEST"
echo ""

echo "📁 Setting up automated daily backup system..."

# Create scripts directory if it doesn't exist
echo "   - Creating scripts directory..."
mkdir -p ~/scripts

# Copy backup script to scripts directory
echo "   - Installing backup script..."
cp "$BACKUP_SCRIPT" ~/scripts/daily-backup.sh
sed -i "s|BACKUP_BASE_DIR=.*|BACKUP_BASE_DIR=\"$BACKUP_DEST\"|" ~/scripts/daily-backup.sh
chmod +x ~/scripts/daily-backup.sh
echo "✅ Backup script installed to ~/scripts/daily-backup.sh"
echo ""

echo "⏰ Setting up cron job for daily backups at 2 AM..."

CRON_LINE="0 2 * * * ~/scripts/daily-backup.sh"
EXISTING_CRON=$(crontab -l 2>/dev/null || true)

if echo "$EXISTING_CRON" | grep -F "$CRON_LINE" > /dev/null; then
	echo "   - Cron job already exists, skipping creation"
else
	if [ -n "$EXISTING_CRON" ]; then
		printf "%s\n%s\n" "$EXISTING_CRON" "$CRON_LINE" | crontab -
	else
		echo "$CRON_LINE" | crontab -
	fi
	echo "✅ Cron job configured successfully"
fi
echo ""

echo "========================================="
echo "🎉 Backup Automation Setup Complete!"
echo "========================================="
echo ""
echo "📋 Backup Configuration:"
echo "   ✓ Daily backups scheduled for 2:00 AM"
echo "   ✓ Backup location: $BACKUP_DEST"
echo "   ✓ Retention: 7 days (older backups auto-deleted)"
echo "   ✓ Log file: $BACKUP_DEST/backup.log"
echo ""
echo "🗂️  What gets backed up:"
echo "   ✓ Entire home directory"
echo "   ✗ Cache files (excluded)"
echo "   ✗ Downloads folder (excluded)"
echo "   ✗ Temporary files (excluded)"
echo "   ✗ Browser caches (excluded)"
echo ""
echo "💡 Management commands:"
echo "   - Manual backup: ~/scripts/daily-backup.sh"
echo "   - Check logs: cat $BACKUP_DEST/backup.log"
echo "   - View schedule: crontab -l"
echo ""
echo "📅 Current cron jobs:"
crontab -l
