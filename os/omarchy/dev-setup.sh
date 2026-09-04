#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_omarchy

echo "========================================="
echo "Omarchy Development Tools Setup Starting..."
echo "========================================="

echo "🌐 Installing development package set..."
omarchy_install_packages github-cli postgresql redis docker docker-buildx docker-compose dbeaver visual-studio-code-bin insomnia-bin aws-cli-v2
echo "✅ Development packages installed successfully"
echo ""

echo "📦 Configuring Node.js LTS..."
if command -v mise >/dev/null 2>&1; then
    mise use -g node@lts
    echo "✅ Node.js LTS installed with mise"
elif command -v nvm >/dev/null 2>&1; then
    nvm install --lts
    echo "✅ Node.js LTS installed with nvm"
else
    echo "⚠️  Neither mise nor nvm is available. Skipping Node.js runtime setup."
fi
echo ""

echo "🔄 Enabling development services..."
sudo systemctl enable --now postgresql.service
sudo systemctl enable --now redis.service
sudo systemctl enable --now docker.service
echo "✅ Development services enabled"
echo ""

echo "⚙️  Configuring Git global settings..."
git config --global pull.rebase true
git config --global user.name "Steve Freeman"
git config --global user.email "sfreeman422@protonmail.com"
echo "✅ Git configuration completed"
echo ""

echo "========================================="
echo "🎉 Omarchy Development Tools Setup Complete!"
echo "========================================="
echo ""
echo "📋 Summary of what was installed/configured:"
echo "   ✓ GitHub CLI"
echo "   ✓ Node.js LTS"
echo "   ✓ PostgreSQL"
echo "   ✓ Redis"
echo "   ✓ Docker"
echo "   ✓ DBeaver"
echo "   ✓ VS Code"
echo "   ✓ Insomnia"
echo "   ✓ AWS CLI"
echo ""
echo "💡 Next steps:"
echo "   - Run 'gh auth login' to authenticate GitHub CLI"
echo "   - Use 'sudo docker' by default on Omarchy unless you explicitly enable sudoless Docker"
echo ""
