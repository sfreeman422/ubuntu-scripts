#!/bin/bash

# Ubuntu First-Time Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

for lib_file in "$SCRIPT_DIR/lib/ubuntu-release.sh" "$SCRIPT_DIR/lib/os-detection.sh"; do
    if [[ -f "$lib_file" ]]; then
        # shellcheck disable=SC1090
        source "$lib_file"
    fi
done

DRY_RUN=false
DRY_RUN_STRICT=false
REQUESTED_TARGET=""

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
    echo "Usage: $0 [--dry-run] [--strict] [--os ubuntu|omarchy] [--help]"
    echo ""
    echo "  --dry-run   Validate the detected setup target without installing anything"
    echo "  --strict    In dry-run mode, treat warnings as failures"
    echo "  --os        Override detected target (ubuntu or omarchy)"
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
        --os)
            shift
            if [[ $# -eq 0 ]]; then
                echo "❌ --os requires a value: ubuntu or omarchy"
                usage
                exit 1
            fi
            REQUESTED_TARGET="$1"
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

SETUP_TARGET="$(detect_setup_target "$REQUESTED_TARGET" 2>/dev/null || true)"
if [[ -z "$SETUP_TARGET" ]]; then
    echo "❌ Unable to determine a supported setup target from this machine."
    echo "   Supported targets: ubuntu, omarchy"
    echo "   Detected OS: $(get_os_pretty_name 2>/dev/null || echo unknown)"
    exit 1
fi

SETUP_DISPLAY_NAME="$(get_setup_display_name "$SETUP_TARGET")"
OS_SCRIPT_DIR="$SCRIPT_DIR/os/$SETUP_TARGET"

preflight_checks() {
    if [[ ! -d "$OS_SCRIPT_DIR" ]]; then
        echo "❌ Missing setup directory for target '$SETUP_TARGET': $OS_SCRIPT_DIR"
        exit 1
    fi

    case "$SETUP_TARGET" in
        ubuntu)
            if ! is_ubuntu_os; then
                echo "❌ Ubuntu target selected, but the current OS is $(get_os_pretty_name)"
                exit 1
            fi

            if ! command -v gnome-shell >/dev/null 2>&1; then
                echo "❌ GNOME Shell not detected. Ubuntu setup supports GNOME only."
                exit 1
            fi

            if declare -f is_supported_ubuntu_release >/dev/null 2>&1; then
                if is_supported_ubuntu_release; then
                    echo "✅ Ubuntu release $(get_ubuntu_version_id) is supported."
                else
                    echo "⚠️  Ubuntu release $(get_ubuntu_version_id) is not explicitly validated by this repo."
                    echo "   Supported Ubuntu targets: 24.04 and 26.04"
                    echo "   Continuing in best-effort mode..."
                fi
            fi
            ;;
        omarchy)
            if ! is_omarchy_os; then
                echo "❌ Omarchy target selected, but the current OS is $(get_os_pretty_name)"
                exit 1
            fi

            if ! command -v omarchy >/dev/null 2>&1; then
                echo "❌ Omarchy CLI not detected. This setup expects a full Omarchy environment."
                exit 1
            fi

            if ! command -v hyprctl >/dev/null 2>&1; then
                echo "❌ Hyprland tooling not detected. Omarchy setup expects the default Omarchy desktop session."
                exit 1
            fi

            echo "✅ Omarchy environment detected."
            ;;
        *)
            echo "❌ Unsupported setup target: $SETUP_TARGET"
            exit 1
            ;;
    esac
}

preflight_checks

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "🧪 Running dry-run validation mode..."
    if [[ "$DRY_RUN_STRICT" == "true" ]]; then
        echo "🔒 Strict mode enabled (warnings will fail the run)."
        bash "$OS_SCRIPT_DIR/dry-run.sh" --strict
    else
        bash "$OS_SCRIPT_DIR/dry-run.sh"
    fi
    exit $?
fi

if [[ "$DRY_RUN_STRICT" == "true" ]]; then
    echo "⚠️  --strict has no effect without --dry-run."
fi

echo "============================================="
echo "🚀 First-Time Setup Starting..."
echo "============================================="
echo ""
echo "This script will set up your system with:"
echo "   • System packages and configuration"
echo "   • Development tools and environment"
echo "   • ZSH with modern theme"
echo "   • Essential applications"
echo "   • Gaming environment (Wine & Lutris)"
echo "   • Automatic theme switching (light/dark)"
echo "   • Automated backup system"
echo "   • Downloads folder cleanup"
echo ""
echo "🖥️  Target environment: $SETUP_DISPLAY_NAME"
echo ""
echo "⏳ Estimated time: 15-30 minutes"
echo "💡 You may be prompted for sudo password during installation"
echo ""
read -p "Press Enter to continue..."
echo ""

run_step "🔧 STEP 1/8: System Level Setup" "$OS_SCRIPT_DIR/system-level-setup.sh"
run_step "💻 STEP 2/8: Development Tools Setup" "$OS_SCRIPT_DIR/dev-setup.sh"
run_step "🎨 STEP 3/8: Shell & Fonts Setup" "$OS_SCRIPT_DIR/shell-setup.sh"
run_step "📱 STEP 4/8: Application Setup" "$OS_SCRIPT_DIR/app-setup.sh"
run_step "🎮 STEP 5/8: Gaming Environment Setup" "$OS_SCRIPT_DIR/gaming.sh"
run_step "🎨 STEP 6/8: Theme Automation Setup" "$OS_SCRIPT_DIR/theme-automation-setup.sh"

# Backup setup
BACKUP_RAN=false
echo "💾 STEP 7/8: Backup Automation Setup"
echo "---------------------------------------------"
echo "⚠️  This will set up automated daily backups at 2:00 AM"
echo "   (You'll be prompted for backup destination)"
read -p "Do you want to proceed with backup automation setup? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_step "💾 STEP 7/8: Backup Automation Setup" "./scripts/backup/backup-setup.sh" "true"
    BACKUP_RAN=true
else
    echo "⏭️  Skipping backup automation setup"
    record_step_result "💾 STEP 7/8: Backup Automation Setup" "skipped"
fi
echo ""

run_step "🗂️  STEP 8/8: Downloads Cleanup Setup" "./scripts/downloads-cleanup/downloads-cleanup-setup.sh"

print_setup_summary

echo "============================================="
echo "🎉 First-Time Setup Complete!"
echo "============================================="
echo ""
echo "📋 Setup Summary:"
echo "   ✅ System packages updated and configured"
echo "   ✅ Development environment installed"
echo "   ✅ Modern ZSH theme configured"
echo "   ✅ Essential applications installed"
echo "   ✅ Gaming environment configured"
echo "   ✅ Automatic theme switching enabled"
if [[ "$BACKUP_RAN" == "true" ]]; then
    echo "   ✅ Automated backup system active"
else
    echo "   ⏭️  Automated backup system skipped"
fi
echo "   ✅ Downloads cleanup automation enabled"
echo ""
echo "🔄 IMPORTANT: Please reboot your system to ensure all changes take effect"
echo ""
echo "💡 Next steps after reboot:"
echo "   - ZSH and Powerlevel10k configuration will run automatically"
echo "   - Configure GitHub CLI: gh auth login"
if [[ "$SETUP_TARGET" == "ubuntu" ]]; then
    echo "   - Add yourself to docker group: sudo usermod -aG docker $USER (if Docker was installed)"
else
    echo "   - Continue using 'sudo docker' unless you explicitly enable sudoless Docker in Omarchy"
fi
echo "   - Set up ProtonMail Bridge if needed"
echo ""
echo "📚 Documentation and logs:"
echo "   - Backup logs: Check the directory you specified during setup"
echo "   - Cron jobs: crontab -l"
echo ""

read -p "Press Enter to finish setup..."