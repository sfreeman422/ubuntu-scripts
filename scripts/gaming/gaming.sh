#!/bin/bash

# Gaming Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"
if [[ -f "$LIB_DIR/ubuntu-release.sh" ]]; then
	# shellcheck disable=SC1091
	source "$LIB_DIR/ubuntu-release.sh"
fi

UBUNTU_CODENAME_VALUE="$(get_ubuntu_codename 2>/dev/null || echo "unknown")"
WINEHQ_CODENAME="$(get_winehq_codename "$UBUNTU_CODENAME_VALUE" 2>/dev/null || echo "noble")"

declare -A GAMING_RESULTS
GAMING_IDS=(wine lutris)
declare -A GAMING_LABELS=(
	[wine]="Wine|Windows compatibility layer"
	[lutris]="Lutris|Gaming platform manager"
)

record_gaming_result() {
	GAMING_RESULTS["$1"]="$2"
}

echo "========================================="
echo "Gaming Environment Setup Starting..."
echo "========================================="

# Add 32-bit architecture for Wine compatibility
echo "🏗️  Setting up 32-bit architecture support..."
sudo dpkg --add-architecture i386 
echo "✅ 32-bit architecture added successfully"
echo ""

# Set up Wine repository
echo "🍷 Installing Wine Windows compatibility layer..."
echo "   - Creating keyrings directory..."
sudo mkdir -pm755 /etc/apt/keyrings
echo "   - Adding Wine repository key..."
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
echo "   - Adding Wine repository sources..."
if [[ "$WINEHQ_CODENAME" != "$UBUNTU_CODENAME_VALUE" ]]; then
	echo "   - WineHQ source for '${UBUNTU_CODENAME_VALUE}' not found; using '${WINEHQ_CODENAME}'"
fi
sudo wget -NP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/${WINEHQ_CODENAME}/winehq-${WINEHQ_CODENAME}.sources"

echo "   - Updating package lists..."
echo "   - Installing Wine stable version..."
if sudo apt update && sudo apt install --install-recommends -y winehq-stable; then
	record_gaming_result wine true
	echo "✅ Wine installed successfully"
else
	record_gaming_result wine false
	echo "⚠️  Wine installation failed."
fi
echo ""

# Download the latest Lutris package from https://github.com/lutris/lutris/releases
# The command below references Lutris version v0.5.18 as an example; please verify you are installing the latest version:
echo "🎮 Installing Lutris gaming platform..."
echo "   - Downloading Lutris package..."
if wget -O ~/Downloads/lutris_0.5.18_all.deb https://github.com/lutris/lutris/releases/download/v0.5.18/lutris_0.5.18_all.deb; then
	echo "   - Installing Lutris package..."
	if sudo dpkg -i ~/Downloads/lutris_0.5.18_all.deb && sudo apt install --fix-broken -y; then
		record_gaming_result lutris true
		echo "✅ Lutris installed successfully"
	else
		record_gaming_result lutris false
		echo "⚠️  Lutris installation failed."
	fi
else
	record_gaming_result lutris false
	echo "⚠️  Lutris download failed."
fi
echo ""

echo "========================================="
echo "🎉 Gaming Environment Setup Complete!"
echo "========================================="
echo ""
echo "📋 Gaming tools installed:"
for gaming_id in "${GAMING_IDS[@]}"; do
	IFS='|' read -r gaming_name gaming_description <<< "${GAMING_LABELS[$gaming_id]}"
	if [[ "${GAMING_RESULTS[$gaming_id]:-false}" == "true" ]]; then
		echo "   ✓ $gaming_name - $gaming_description"
	else
		echo "   ⚠️  $gaming_name - installation failed or skipped"
	fi
done
echo "   ✓ 32-bit architecture support"
echo ""
echo "💡 Next steps:"
echo "   - Launch Lutris from applications menu"
echo "   - Configure Wine using 'winecfg' command"
echo "   - Install games through Lutris or Steam"
echo "   - Consider installing additional Wine dependencies as needed"
echo ""