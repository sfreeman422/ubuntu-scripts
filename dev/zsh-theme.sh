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
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
echo "⚙️  Configuring ZSH to use Powerlevel10k theme..."
echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc
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
