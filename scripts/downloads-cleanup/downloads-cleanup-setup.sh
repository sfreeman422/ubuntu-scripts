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
(crontab -l ; echo "*/5 * * * * ~/scripts/downloads-cleanup.sh") | crontab -
echo "✅ Cron job configured successfully"
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