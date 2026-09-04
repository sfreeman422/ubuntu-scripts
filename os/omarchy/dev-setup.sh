#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_omarchy

echo "========================================="
echo "Omarchy Development Tools Setup Starting..."
echo "========================================="

echo "🌐 Installing development package set..."
omarchy_install_packages github-cli postgresql valkey dbeaver visual-studio-code-bin insomnia-bin aws-cli-v2
echo "✅ Development packages installed successfully"
echo ""

echo "📦 Configuring Node.js LTS with mise..."
if command -v mise >/dev/null 2>&1; then
    mise use -g node@lts
    echo "✅ Node.js LTS installed with mise"
else
    echo "⚠️  mise is not available. Skipping Node.js runtime setup."
fi
echo ""

echo "🔄 Enabling development services..."
sudo systemctl enable --now postgresql.service
sudo systemctl enable --now valkey.service
echo "✅ PostgreSQL and Valkey services enabled"
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
echo "   ✓ Node.js LTS via mise"
echo "   ✓ PostgreSQL"
echo "   ✓ Valkey (Redis-compatible)"
echo "   ✓ Docker available via Omarchy base image"
echo "   ✓ DBeaver"
echo "   ✓ VS Code"
echo "   ✓ Insomnia"
echo "   ✓ AWS CLI"
echo ""
echo "💡 Next steps:"
echo "   - Run 'gh auth login' to authenticate GitHub CLI"
echo "   - Use 'sudo docker' by default on Omarchy unless you explicitly enable sudoless Docker"
echo "   - Prefer Omarchy's Docker DB workflow when provisioning local databases"
echo ""
