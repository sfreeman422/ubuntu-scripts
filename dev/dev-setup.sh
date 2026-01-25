#!/bin/bash

# Development Tools Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

echo "========================================="
echo "Development Tools Setup Starting..."
echo "========================================="

# Install curl
echo "🌐 Installing curl..."
sudo apt install curl -y 
echo "✅ curl installed successfully"
echo ""

# Install Git
echo "📂 Installing Git version control..."
sudo apt install git -y 
echo "✅ Git installed successfully"
echo ""

#Install github-cli
echo "🐙 Installing GitHub CLI..."
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
&& sudo mkdir -p -m 755 /etc/apt/keyrings \
&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y
echo "✅ GitHub CLI installed successfully"
echo ""

# Install NVM
echo "📦 Installing Node Version Manager (NVM)..."
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
echo "✅ NVM downloaded and installed"
echo ""

# Set up NVM to run locally
echo "⚙️  Configuring NVM environment..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install latest LTS Node version
echo "🚀 Installing latest LTS Node.js version..."
nvm install --lts
echo "✅ Node.js LTS installed successfully"
echo ""

# Install pnpm
echo "📦 Installing pnpm package manager..."
curl -fsSL https://get.pnpm.io/install.sh | sh -
echo "✅ pnpm installed successfully"
echo ""

# Add npm -> pnpm aliases
echo "🔗 Adding npm to pnpm aliases..."
echo 'alias "npm i"="pnpm install"' >> ~/.zshrc
echo 'alias "npm install"="pnpm install"' >> ~/.zshrc
echo "✅ npm aliases added (npm i, npm install -> pnpm install)"
echo ""

# Install Claude Code
echo "🤖 Installing Claude Code CLI..."
curl -fsSL https://claude.ai/install.sh | sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
echo "✅ Claude Code installed successfully"
echo ""

# Install postgres
echo "🐘 Installing PostgreSQL database server..."
sudo apt install -y postgresql postgresql-contrib
echo "✅ PostgreSQL installed successfully"
echo ""

# Starts Postgres service
echo "🔄 Starting PostgreSQL service..."
sudo systemctl start postgresql.service
echo "✅ PostgreSQL service started"
echo ""

# Install dbeaver
echo "🗄️  Installing DBeaver database client..."
sudo snap install dbeaver-ce
echo "✅ DBeaver installed successfully"
echo ""

# Install Redis
echo "📊 Installing Redis in-memory database..."
echo "   - Adding Redis package repository..."
sudo apt-get install lsb-release curl gpg -y 
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
sudo chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
echo "   - Installing Redis..."
sudo apt-get update
sudo apt-get install -y redis
echo "✅ Redis installed successfully"
echo ""

# Install VS Code
echo "💻 Installing VS Code..."
echo "   - Adding VS Code apt repository..."
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
  curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
  echo "   - VS Code repository added."
else
  echo "   - VS Code repository already present, skipping addition."
fi
echo "   - Updating apt and installing VS Code..."
sudo apt update
sudo apt install -y code
echo "✅ VS Code installed successfully"
echo ""

# Set up docker
echo "🐳 Installing Docker container platform..."
echo "   - Removing old Docker packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
echo "   - Setting up Docker repository..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "   - Installing Docker Engine..."
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
echo "✅ Docker installed successfully"
echo ""

# Setup git config
echo "⚙️  Configuring Git global settings..."
git config --global pull.rebase true
git config --global user.name "Steve Freeman"
git config --global user.email "sfreeman422@protonmail.com"
echo "✅ Git configuration completed"
echo ""

# Install Insomnia (REST client) via apt
echo "🌩️  Installing Insomnia REST client..."
echo "   - Adding Insomnia apt repository and GPG key (if needed)..."
if [ ! -f /etc/apt/sources.list.d/insomnia.list ]; then
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://deb.insomnia.rest/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/insomnia-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/insomnia-archive-keyring.gpg] https://deb.insomnia.rest/ v1 main" | sudo tee /etc/apt/sources.list.d/insomnia.list > /dev/null
  echo "   - Insomnia repository added."
else
  echo "   - Insomnia repository already present, skipping addition."
fi
echo "   - Updating apt and installing Insomnia (insomnia)..."
sudo apt update
sudo apt install -y insomnia || sudo apt install -f -y
echo "✅ Insomnia installed successfully"
echo ""

# Install AWS CLI
echo "☁️  Installing AWS CLI..."
echo "   - Installing from snap store..."
sudo snap install aws-cli --classic
echo "✅ AWS CLI installed successfully"
echo ""

echo "========================================="
echo "🎉 Development Tools Setup Complete!"
echo "========================================="
echo ""
echo "📋 Summary of what was installed:"
echo "   ✓ curl - HTTP client"
echo "   ✓ Git - Version control"
echo "   ✓ GitHub CLI - GitHub integration"
echo "   ✓ NVM + Node.js LTS - JavaScript runtime"
echo "   ✓ pnpm - Fast, disk space efficient package manager"
echo "   ✓ npm aliases - npm i/install redirected to pnpm"
echo "   ✓ Claude Code - AI coding assistant CLI"
echo "   ✓ PostgreSQL - Database server"
echo "   ✓ DBeaver - Database client"
echo "   ✓ Redis - In-memory database"
echo "   ✓ VS Code - Code editor"
echo "   ✓ Docker - Container platform"
echo "   ✓ Insomnia - API client"
echo "   ✓ AWS CLI - Amazon Web Services CLI"
echo ""
echo "⚙️  Git configured with:"
echo "   - Rebase on pull: enabled"
echo "   - User: Steve Freeman <sfreeman422@protonmail.com>"
echo ""
echo "💡 Next steps:"
echo "   - Restart terminal to use NVM/Node.js"
echo "   - Run 'gh auth login' to authenticate GitHub CLI"
echo "   - Add your user to docker group: sudo usermod -aG docker $USER"
echo "   - Restart to apply docker group changes"
echo ""