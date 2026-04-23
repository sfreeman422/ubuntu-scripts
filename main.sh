#!/bin/bash

# Ubuntu First-Time Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

UBUNTU_LIB="$SCRIPT_DIR/lib/ubuntu-release.sh"
if [[ -f "$UBUNTU_LIB" ]]; then
    # shellcheck disable=SC1090
    source "$UBUNTU_LIB"
fi

DRY_RUN=false
DRY_RUN_STRICT=false

usage() {
    echo "Usage: $0 [--dry-run] [--strict] [--help]"
    echo ""
    echo "  --dry-run   Validate Ubuntu + GNOME readiness without installing anything"
    echo "  --strict    In dry-run mode, treat warnings as failures"
    echo "  --help      Show this help"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --strict)
            DRY_RUN_STRICT=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

preflight_checks() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            echo "❌ This setup is intended for Ubuntu only. Detected: ${PRETTY_NAME:-unknown}"
            exit 1
        fi
    else
        echo "❌ Unable to verify OS. /etc/os-release not found."
        exit 1
    fi

    if ! command -v gnome-shell >/dev/null 2>&1; then
        echo "❌ GNOME Shell not detected. This setup supports Ubuntu with GNOME only."
        exit 1
    fi

    if declare -f is_supported_ubuntu_release >/dev/null 2>&1; then
        if is_supported_ubuntu_release; then
            echo "✅ Ubuntu release $(get_ubuntu_version_id) is supported."
        else
            echo "⚠️  Ubuntu release $(get_ubuntu_version_id) is not explicitly validated by this repo."
            echo "   Supported targets: 24.04 and 26.04"
            echo "   Continuing in best-effort mode..."
        fi
    fi
}

preflight_checks

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "🧪 Running dry-run validation mode..."
    if [[ "$DRY_RUN_STRICT" == "true" ]]; then
        echo "🔒 Strict mode enabled (warnings will fail the run)."
        bash "$SCRIPT_DIR/scripts/ubuntu-dry-run.sh" --strict
    else
        bash "$SCRIPT_DIR/scripts/ubuntu-dry-run.sh"
    fi
    exit $?
fi

if [[ "$DRY_RUN_STRICT" == "true" ]]; then
    echo "⚠️  --strict has no effect without --dry-run."
fi

echo "============================================="
echo "🚀 Ubuntu First-Time Setup Starting..."
echo "============================================="
echo ""
echo "This script will set up your Ubuntu system with:"
echo "   • System packages and configuration"
echo "   • Development tools and environment"
echo "   • ZSH with modern theme"
echo "   • Essential applications"
echo "   • Gaming environment (Wine & Lutris)"
echo "   • Automatic theme switching (light/dark)"
echo "   • Automated backup system"
echo "   • Downloads folder cleanup"
echo ""
echo "🖥️  Target environment: Ubuntu + GNOME"
echo ""
echo "⏳ Estimated time: 15-30 minutes"
echo "💡 You may be prompted for sudo password during installation"
echo ""
read -p "Press Enter to continue..."
echo ""

# System-level setup
echo "🔧 STEP 1/8: System Level Setup"
echo "---------------------------------------------"
./system/system-level-setup.sh
echo ""

# Development setup  
echo "💻 STEP 2/8: Development Tools Setup"
echo "---------------------------------------------"
./dev/dev-setup.sh
echo ""

# ZSH theme setup
echo "🎨 STEP 3/8: ZSH Theme & Fonts Setup"
echo "---------------------------------------------"
./dev/zsh-theme.sh
echo ""

# Application setup
echo "📱 STEP 4/8: Application Setup"
echo "---------------------------------------------"
./app/app-setup.sh
echo ""

# Gaming setup
echo "🎮 STEP 5/8: Gaming Environment Setup"
echo "---------------------------------------------"
./scripts/gaming/gaming.sh
echo ""

# Theme automation setup
echo "🎨 STEP 6/8: Theme Automation Setup"
echo "---------------------------------------------"
./scripts/theme-automation/theme-automation-setup.sh
echo ""

# Backup setup
echo "💾 STEP 7/8: Backup Automation Setup"
echo "---------------------------------------------"
echo "⚠️  This will set up automated daily backups at 2:00 AM"
echo "   (You'll be prompted for backup destination)"
read -p "Do you want to proceed with backup automation setup? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./scripts/backup/backup-setup.sh
else
    echo "⏭️  Skipping backup automation setup"
fi
echo ""

# Downloads cleanup setup
echo "🗂️  STEP 8/8: Downloads Cleanup Setup"
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
echo "   ✅ Gaming environment configured"
echo "   ✅ Automatic theme switching enabled"
echo "   ✅ Automated backup system active"
echo "   ✅ Downloads cleanup automation enabled"
echo ""
echo "🔄 IMPORTANT: Please reboot your system to ensure all changes take effect"
echo ""
echo "💡 Next steps after reboot:"
echo "   - ZSH and Powerlevel10k configuration will run automatically"
echo "   - Configure GitHub CLI: gh auth login"
echo "   - Add yourself to docker group: sudo usermod -aG docker $USER (if Docker was installed)"
echo "   - Set up ProtonMail Bridge if needed"
echo ""
echo "📚 Documentation and logs:"
echo "   - Backup logs: Check the directory you specified during setup"
echo "   - Cron jobs: crontab -l"
echo ""

read -p "Press Enter to finish setup..."