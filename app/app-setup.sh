#!/bin/bash

# Application Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

declare -A APP_RESULTS
APP_IDS=(spotify chromium discord slack steam protonmail-bridge zoom lm-studio)
declare -A APP_LABELS=(
	[spotify]="Spotify|Music streaming"
	[chromium]="Chromium|Web browser"
	[discord]="Discord|Chat and voice communication"
	[slack]="Slack|Team communication"
	[steam]="Steam|Gaming platform"
	[protonmail-bridge]="ProtonMail Bridge|Email client bridge"
	[zoom]="Zoom|Video conferencing"
	[lm-studio]="LM Studio|Local AI models"
)

record_app_result() {
	APP_RESULTS["$1"]="$2"
}

install_apt_app() {
	local app_id="$1"
	local app_name="$2"
	local package_name="$3"

	echo "Installing $app_name..."
	if sudo apt install -y "$package_name"; then
		record_app_result "$app_id" true
		echo "✅ $app_name installed successfully"
	else
		record_app_result "$app_id" false
		echo "⚠️  $app_name installation failed."
	fi
	echo ""
}

install_deb_package() {
	local app_name="$1"
	local download_url="$2"
	local package_path="$3"

	echo "   - Downloading $app_name package..."
	if ! curl -fL -o "$package_path" "$download_url"; then
		echo "⚠️  $app_name download failed."
		return 1
	fi

	echo "   - Installing $app_name package..."
	if sudo apt install -y "$package_path" && sudo apt install --fix-broken -y; then
		return 0
	fi

	echo "⚠️  $app_name installation failed."
	return 1
}

install_discord() {
	if apt-cache show discord >/dev/null 2>&1; then
		echo "   - Installing Discord via apt..."
		if sudo apt install -y discord; then
			return 0
		fi
		echo "⚠️  Discord apt installation failed. Trying snap fallback..."
	fi

	if command -v snap >/dev/null 2>&1; then
		echo "   - Discord apt package unavailable; installing via snap..."
		if sudo snap install discord; then
			return 0
		fi
	fi

	echo "⚠️  Discord installation failed or no supported installer is available."
	return 1
}

echo "========================================="
echo "Application Setup Starting..."
echo "========================================="

echo "📱 Installing core applications via apt..."
install_apt_app spotify "Spotify" spotify-client
install_apt_app chromium "Chromium" chromium-browser

# Install Discord with apt->snap fallback
echo "💬 Installing Discord..."
if install_discord; then
	record_app_result discord true
	echo "✅ Discord installed successfully"
else
	record_app_result discord false
	echo "⚠️  Discord installation was skipped or failed. You can install it manually later."
fi
echo ""

# Install Slack (direct .deb)
echo "💬 Installing Slack..."
if install_deb_package "Slack" "https://downloads.slack-edge.com/desktop-releases/linux/x64/slack-desktop-latest-amd64.deb" "$HOME/Downloads/slack-desktop-latest.deb"; then
	record_app_result slack true
	echo "✅ Slack installed successfully (.deb)"
elif command -v snap >/dev/null 2>&1; then
	echo "   - Slack .deb unavailable; installing Slack via snap..."
	if sudo snap install slack; then
		record_app_result slack true
		echo "✅ Slack installed successfully (snap)"
	else
		record_app_result slack false
		echo "⚠️  Slack snap installation failed."
	fi
else
	record_app_result slack false
	echo "⚠️  Slack download failed and snap is unavailable. Skipping Slack installation."
fi
echo ""

# Install steam
echo "🎮 Installing Steam gaming platform..."
if install_deb_package "Steam" "https://repo.steampowered.com/steam/archive/precise/steam_latest.deb" "$HOME/Downloads/steam_latest.deb"; then
	record_app_result steam true
	echo "✅ Steam installed successfully"
else
	record_app_result steam false
fi
echo ""

# Download ProtonMail Bridge
echo "📧 Installing ProtonMail Bridge..."
if install_deb_package "ProtonMail Bridge" "https://proton.me/download/bridge/protonmail-bridge_3.21.2-1_amd64.deb" "$HOME/Downloads/protonmail-bridge_3.21.2-1_amd64.deb"; then
	record_app_result protonmail-bridge true
	echo "✅ ProtonMail Bridge installed successfully"
else
	record_app_result protonmail-bridge false
fi
echo ""

# Install Zoom
echo "📹 Installing Zoom video conferencing..."
if install_deb_package "Zoom" "https://zoom.us/client/latest/zoom_amd64.deb" "$HOME/Downloads/zoom_amd64.deb"; then
	record_app_result zoom true
	echo "✅ Zoom installed successfully"
else
	record_app_result zoom false
fi
echo ""

# Install LM Studio
echo "🤖 Installing LM Studio..."
if curl -fsSL https://lmstudio.ai/install.sh | bash; then
	record_app_result lm-studio true
	echo "✅ LM Studio installed successfully"
else
	record_app_result lm-studio false
	echo "⚠️  LM Studio installation failed. You can install it manually from https://lmstudio.ai/download"
fi
echo ""

echo "========================================="
echo "🎉 Application Setup Complete!"
echo "========================================="
echo ""
echo "📋 Applications installed:"
for app_id in "${APP_IDS[@]}"; do
	IFS='|' read -r app_name app_description <<< "${APP_LABELS[$app_id]}"
	if [[ "${APP_RESULTS[$app_id]:-false}" == "true" ]]; then
		echo "   ✓ $app_name - $app_description"
	else
		echo "   ⚠️  $app_name - installation failed or skipped"
	fi
done
echo ""
echo "💡 Quick tips:"
echo "   - Launch apps from the applications menu"
echo "   - Steam may require additional setup on first run"
echo "   - ProtonMail Bridge needs login configuration"
echo "   - LM Studio may need a shell restart before the lmstudio command is available"
echo ""