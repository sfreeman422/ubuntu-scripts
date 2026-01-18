#!/bin/bash

# Downloads Cleanup Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")
# Sets up automated cleanup of Downloads folder

echo "========================================="
echo "Downloads Cleanup Automation Setup..."
echo "========================================="

echo "🗂️  Setting up automated Downloads folder cleanup..."

# setup auto delete downloads after 30 days
echo "   - Creating scripts directory..."
mkdir -p ~/scripts

echo "   - Installing cleanup script..."
cp ./downloads-cleanup.sh ~/scripts/downloads-cleanup.sh
chmod +x ~/scripts/downloads-cleanup.sh

echo "⏰ Setting up cron job to run every 5 minutes..."
CRON_LINE="*/5 * * * * ~/scripts/downloads-cleanup.sh"
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
echo "🎉 Downloads Cleanup Setup Complete!"
echo "========================================="
echo ""
echo "📋 Configuration:"
echo "   ✓ Automatic cleanup every 5 minutes"
echo "   ✓ Removes files older than 30 days"
echo "   ✓ Preserves Downloads folder structure"
echo "   ✓ Script location: ~/scripts/downloads-cleanup.sh"
echo ""
echo "💡 Management commands:"
echo "   - Manual cleanup: ~/scripts/downloads-cleanup.sh"
echo "   - View schedule: crontab -l"
echo ""