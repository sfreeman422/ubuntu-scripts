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

# Install postgres
echo "🐘 Installing PostgreSQL database server..."
sudo apt install postgresql postgresql-contrib
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
sudo apt-get install lsb-release curl gpg
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
sudo chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
echo "   - Installing Redis..."
sudo apt-get update
sudo apt-get install redis
echo "✅ Redis installed successfully"
echo ""

# install vscode
echo "💻 Installing Visual Studio Code..."
echo "   - Adding Microsoft repository..."
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
echo "   - Installing latest VS Code..."
sudo apt update
sudo apt install code -y
echo "✅ Visual Studio Code installed successfully"
echo ""

# Set up docker
echo "🐳 Installing Docker container platform..."
echo "   - Removing old Docker packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
echo "   - Setting up Docker repository..."
sudo apt-get update
sudo apt-get install ca-certificates curl
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

# Install bruno
echo "🌩️  Installing Bruno API client..."
echo "   - Adding Bruno repository..."
sudo mkdir -p /etc/apt/keyrings 
sudo apt update && sudo apt install gpg 
sudo gpg --list-keys 
sudo gpg --no-default-keyring --keyring /etc/apt/keyrings/bruno.gpg --keyserver keyserver.ubuntu.com --recv-keys 9FA6017ECABE0266 
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/bruno.gpg] http://debian.usebruno.com/ bruno stable" | sudo tee /etc/apt/sources.list.d/bruno.list 
echo "   - Installing Bruno..."
sudo apt update && sudo apt install bruno
echo "✅ Bruno installed successfully"
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
echo "   ✓ PostgreSQL - Database server"
echo "   ✓ DBeaver - Database client"
echo "   ✓ Redis - In-memory database"
echo "   ✓ Visual Studio Code - Code editor"
echo "   ✓ Docker - Container platform"
echo "   ✓ Bruno - API client"
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