#!/bin/bash

# Ubuntu First-Time Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

echo "============================================="
echo "🚀 Ubuntu First-Time Setup Starting..."
echo "============================================="
echo ""
echo "This script will set up your Ubuntu system with:"
echo "   • System packages and configuration"
echo "   • Development tools and environment"
echo "   • ZSH with modern theme"
echo "   • Essential applications"
echo "   • Automatic theme switching (light/dark)"
echo "   • Automated backup system"
echo "   • Downloads folder cleanup"
echo ""
echo "⏳ Estimated time: 15-30 minutes"
echo "💡 You may be prompted for sudo password during installation"
echo ""
read -p "Press Enter to continue..."
echo ""

# System-level setup
echo "🔧 STEP 1/6: System Level Setup"
echo "---------------------------------------------"
./system/system-level-setup.sh
echo ""

# Development setup  
echo "💻 STEP 2/6: Development Tools Setup"
echo "---------------------------------------------"
./dev/dev-setup.sh
echo ""

# ZSH theme setup
echo "🎨 STEP 3/6: ZSH Theme & Fonts Setup"
echo "---------------------------------------------"
./dev/zsh-theme.sh
echo ""

# Application setup
echo "📱 STEP 4/7: Application Setup"
echo "---------------------------------------------"
./app/app-setup.sh
echo ""

# Theme automation setup
echo "🎨 STEP 5/7: Theme Automation Setup"
echo "---------------------------------------------"
./scripts/theme-automation/theme-automation-setup.sh
echo ""

# Backup setup
echo "💾 STEP 6/7: Backup Automation Setup"
echo "---------------------------------------------"
./scripts/backup/backup-setup.sh
echo ""

# Downloads cleanup setup
echo "🗂️  STEP 7/7: Downloads Cleanup Setup"
echo "---------------------------------------------"
./scripts/downloads-cleanup/downloads-cleanup-setup.sh
echo ""

echo "============================================="
echo "🎉 Ubuntu First-Time Setup Complete!"
echo "============================================="
echo ""
echo "📋 Setup Summary:"
echo "   ✅ System packages updated and configured"
echo "   ✅ Development environment installed"
echo "   ✅ Modern ZSH theme configured"
echo "   ✅ Essential applications installed"
echo "   ✅ Automatic theme switching enabled"
echo "   ✅ Automated backup system active"
echo "   ✅ Downloads cleanup automation enabled"
echo ""
echo "🔄 IMPORTANT: Please reboot your system to ensure all changes take effect"
echo ""
echo "💡 Next steps after reboot:"
echo "   - ZSH and Powerlevel10k configuration will run automatically"
echo "   - Configure GitHub CLI: gh auth login"
echo "   - Add yourself to docker group: sudo usermod -aG docker $USER"
echo "   - Set up ProtonMail Bridge if needed"
echo ""
echo "📚 Documentation and logs:"
echo "   - Backup logs: /media/steve/Backup/ubuntu-desktop/backup.log"
echo "   - Cron jobs: crontab -l"
echo ""

read -p "Press Enter to finish setup..."