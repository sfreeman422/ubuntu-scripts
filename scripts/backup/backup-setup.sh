#!/bin/bash

# Backup Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")
# Sets up automated daily backups

echo "========================================="
echo "Backup Automation Setup Starting..."
echo "========================================="

SCRIPT_DIR="/home/steve/code/ubuntu-scripts/scripts/backup"
BACKUP_SCRIPT="$SCRIPT_DIR/daily-backup.sh"

echo "📁 Setting up automated daily backup system..."

# Create scripts directory if it doesn't exist
echo "   - Creating scripts directory..."
mkdir -p ~/scripts

# Copy backup script to scripts directory
echo "   - Installing backup script..."
cp "$BACKUP_SCRIPT" ~/scripts/daily-backup.sh
chmod +x ~/scripts/daily-backup.sh
echo "✅ Backup script installed to ~/scripts/daily-backup.sh"
echo ""

echo "⏰ Setting up cron job for daily backups at 2 AM..."

# Add cron job for daily backup at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * ~/scripts/daily-backup.sh") | crontab -
echo "✅ Cron job configured successfully"
echo ""

echo "========================================="
echo "🎉 Backup Automation Setup Complete!"
echo "========================================="
echo ""
echo "📋 Backup Configuration:"
echo "   ✓ Daily backups scheduled for 2:00 AM"
echo "   ✓ Backup location: /media/steve/Backup/ubuntu-desktop"
echo "   ✓ Retention: 7 days (older backups auto-deleted)"
echo "   ✓ Log file: /media/steve/Backup/ubuntu-desktop/backup.log"
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
echo "   - Check logs: cat /media/steve/Backup/ubuntu-desktop/backup.log"
echo "   - View schedule: crontab -l"
echo ""
echo "📅 Current cron jobs:"
crontab -l
