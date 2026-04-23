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

declare -a STEP_LABELS=()
declare -a STEP_STATUSES=()

record_step_result() {
    local step_label="$1"
    local step_status="$2"
    STEP_LABELS+=("$step_label")
    STEP_STATUSES+=("$step_status")
}

print_setup_summary() {
    local i
    local total=${#STEP_LABELS[@]}
    local passed=0
    local skipped=0
    local failed=0

    echo ""
    echo "============================================="
    echo "📊 Setup Step Results"
    echo "============================================="

    for ((i = 0; i < total; i++)); do
        case "${STEP_STATUSES[$i]}" in
            passed)
                echo "✅ ${STEP_LABELS[$i]}"
                passed=$((passed + 1))
                ;;
            skipped)
                echo "⏭️  ${STEP_LABELS[$i]}"
                skipped=$((skipped + 1))
                ;;
            failed)
                echo "❌ ${STEP_LABELS[$i]}"
                failed=$((failed + 1))
                ;;
            *)
                echo "⚠️  ${STEP_LABELS[$i]} (unknown status: ${STEP_STATUSES[$i]})"
                ;;
        esac
    done

    echo ""
    echo "Summary: passed=$passed skipped=$skipped failed=$failed total=$total"
    echo ""
}

run_step() {
    local step_label="$1"
    local step_script="$2"
    local is_optional="${3:-false}"

    echo "$step_label"
    echo "---------------------------------------------"

    if [[ ! -x "$step_script" ]]; then
        echo "❌ Step script is missing or not executable: $step_script"
        record_step_result "$step_label" "failed"
        print_setup_summary
        if [[ "$is_optional" == "true" ]]; then
            echo "⏭️  Continuing because this step is optional"
            echo ""
            return 0
        fi
        exit 1
    fi

    if "$step_script"; then
        record_step_result "$step_label" "passed"
        echo ""
        return 0
    fi

    echo "❌ Step failed: $step_script"
    record_step_result "$step_label" "failed"
    if [[ "$is_optional" == "true" ]]; then
        echo "⏭️  Continuing because this step is optional"
        echo ""
        return 0
    fi

    echo "🛑 Setup stopped due to failure in required step."
    print_setup_summary
    exit 1
}

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

run_step "🔧 STEP 1/8: System Level Setup" "./system/system-level-setup.sh"
run_step "💻 STEP 2/8: Development Tools Setup" "./dev/dev-setup.sh"
run_step "🎨 STEP 3/8: ZSH Theme & Fonts Setup" "./dev/zsh-theme.sh"
run_step "📱 STEP 4/8: Application Setup" "./app/app-setup.sh"
run_step "🎮 STEP 5/8: Gaming Environment Setup" "./scripts/gaming/gaming.sh"
run_step "🎨 STEP 6/8: Theme Automation Setup" "./scripts/theme-automation/theme-automation-setup.sh"

# Backup setup
echo "💾 STEP 7/8: Backup Automation Setup"
echo "---------------------------------------------"
echo "⚠️  This will set up automated daily backups at 2:00 AM"
echo "   (You'll be prompted for backup destination)"
read -p "Do you want to proceed with backup automation setup? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_step "💾 STEP 7/8: Backup Automation Setup" "./scripts/backup/backup-setup.sh" "true"
else
    echo "⏭️  Skipping backup automation setup"
    record_step_result "💾 STEP 7/8: Backup Automation Setup" "skipped"
fi
echo ""

run_step "🗂️  STEP 8/8: Downloads Cleanup Setup" "./scripts/downloads-cleanup/downloads-cleanup-setup.sh"

print_setup_summary

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