#!/bin/bash

# ZSH Theme Setup Script
# Author: Steve Freeman  
# Date: $(date +"%Y-%m-%d")

declare -A THEME_RESULTS
THEME_IDS=(nerd-fonts powerlevel10k)
declare -A THEME_LABELS=(
	[nerd-fonts]="Nerd Fonts|Enhanced font collection with icons"
	[powerlevel10k]="Powerlevel10k|Modern ZSH theme"
)

record_theme_result() {
	THEME_RESULTS["$1"]="$2"
}

echo "========================================="
echo "ZSH Theme & Fonts Setup Starting..."
echo "========================================="

# Install Nerd Fonts
echo "🔤 Installing Nerd Fonts collection..."
echo "   - Cloning Nerd Fonts repository..."
if git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git && (cd nerd-fonts && ./install.sh); then
	record_theme_result nerd-fonts true
	echo "✅ Nerd Fonts installed successfully"
else
	record_theme_result nerd-fonts false
	echo "⚠️  Nerd Fonts installation failed."
fi
echo "   - Cleaning up temporary files..."
rm -rf ./nerd-fonts
echo ""

# Install Powerlevel10k theme
echo "🎨 Installing Powerlevel10k ZSH theme..."
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [[ ! -d "$ZSH_CUSTOM_DIR/themes" ]]; then
	echo "❌ Oh My Zsh themes directory not found at $ZSH_CUSTOM_DIR/themes"
	echo "   Run system setup first to install Oh My Zsh."
	exit 1
fi

if [[ ! -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]]; then
	if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k"; then
		echo "⚠️  Powerlevel10k download failed."
	fi
else
	echo "   - Powerlevel10k already cloned, skipping"
fi
echo "⚙️  Configuring ZSH to use Powerlevel10k theme..."
if [[ -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]] && grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"$' ~/.zshrc 2>/dev/null; then
	echo "   - ZSH theme already configured"
elif [[ -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]]; then
	sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc 2>/dev/null || true
	if ! grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"$' ~/.zshrc 2>/dev/null; then
		echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc
	fi
fi
if [[ -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]] && grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"$' ~/.zshrc 2>/dev/null; then
	record_theme_result powerlevel10k true
	echo "✅ Powerlevel10k theme installed and configured"
else
	record_theme_result powerlevel10k false
	echo "⚠️  Powerlevel10k installation or configuration failed."
fi
echo ""

echo "========================================="
echo "🎉 ZSH Theme Setup Complete!"
echo "========================================="
echo ""
echo "📋 What was installed:"
for theme_id in "${THEME_IDS[@]}"; do
	IFS='|' read -r theme_name theme_description <<< "${THEME_LABELS[$theme_id]}"
	if [[ "${THEME_RESULTS[$theme_id]:-false}" == "true" ]]; then
		echo "   ✓ $theme_name - $theme_description"
	else
		echo "   ⚠️  $theme_name - installation failed or skipped"
	fi
done
echo ""
echo "💡 Next steps:"
echo "   - Restart your terminal"
echo "   - The Powerlevel10k configuration wizard will run automatically"
echo "   - Choose your preferred prompt style and icons"
echo ""
