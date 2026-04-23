#!/bin/bash

# ZSH Theme Setup Script
# Author: Steve Freeman  
# Date: $(date +"%Y-%m-%d")

echo "========================================="
echo "ZSH Theme & Fonts Setup Starting..."
echo "========================================="

# Install Nerd Fonts
echo "🔤 Installing Nerd Fonts collection..."
echo "   - Cloning Nerd Fonts repository..."
git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git 
echo "   - Installing fonts (this may take a few minutes)..."
cd nerd-fonts
./install.sh
cd ..
echo "   - Cleaning up temporary files..."
rm -rf ./nerd-fonts
echo "✅ Nerd Fonts installed successfully"
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
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
else
	echo "   - Powerlevel10k already cloned, skipping"
fi
echo "⚙️  Configuring ZSH to use Powerlevel10k theme..."
if grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"$' ~/.zshrc 2>/dev/null; then
	echo "   - ZSH theme already configured"
else
	sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc 2>/dev/null || true
	if ! grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"$' ~/.zshrc 2>/dev/null; then
		echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc
	fi
fi
echo "✅ Powerlevel10k theme installed and configured"
echo ""

echo "========================================="
echo "🎉 ZSH Theme Setup Complete!"
echo "========================================="
echo ""
echo "📋 What was installed:"
echo "   ✓ Nerd Fonts - Enhanced font collection with icons"
echo "   ✓ Powerlevel10k - Modern ZSH theme"
echo ""
echo "💡 Next steps:"
echo "   - Restart your terminal"
echo "   - The Powerlevel10k configuration wizard will run automatically"
echo "   - Choose your preferred prompt style and icons"
echo ""
