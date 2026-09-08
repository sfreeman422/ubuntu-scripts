#!/bin/bash

# Development Tools Setup Script
# Author: Steve Freeman
# Date: $(date +"%Y-%m-%d")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
if [[ -f "$LIB_DIR/ubuntu-release.sh" ]]; then
  # shellcheck disable=SC1091
  source "$LIB_DIR/ubuntu-release.sh"
fi

UBUNTU_CODENAME_VALUE="$(get_ubuntu_codename 2>/dev/null || echo "unknown")"

declare -A TOOL_RESULTS
TOOL_IDS=(curl git github-cli nvm-node postgresql dbeaver redis vscode docker insomnia aws-cli)
declare -A TOOL_LABELS=(
  [curl]="curl|HTTP client"
  [git]="Git|Version control"
  [github-cli]="GitHub CLI|GitHub integration"
  [nvm-node]="NVM + Node.js LTS|JavaScript runtime"
  [postgresql]="PostgreSQL|Database server"
  [dbeaver]="DBeaver|Database client"
  [redis]="Redis|In-memory database"
  [vscode]="VS Code|Code editor"
  [docker]="Docker|Container platform"
  [insomnia]="Insomnia|API client"
  [aws-cli]="AWS CLI|Amazon Web Services CLI"
)

record_tool_result() {
  TOOL_RESULTS["$1"]="$2"
}

install_apt_tool() {
  local tool_id="$1"
  local tool_name="$2"
  shift 2

  if sudo apt install -y "$@"; then
    record_tool_result "$tool_id" true
    echo "✅ $tool_name installed successfully"
  else
    record_tool_result "$tool_id" false
    echo "⚠️  $tool_name installation failed."
  fi
}

print_tool_summary() {
  local tool_id tool_name tool_description

  for tool_id in "${TOOL_IDS[@]}"; do
    IFS='|' read -r tool_name tool_description <<< "${TOOL_LABELS[$tool_id]}"
    if [[ "${TOOL_RESULTS[$tool_id]:-false}" == "true" ]]; then
      echo "   ✓ $tool_name - $tool_description"
    else
      echo "   ⚠️  $tool_name - installation failed or skipped"
    fi
  done
}

echo "========================================="
echo "Development Tools Setup Starting..."
echo "========================================="

# Install curl
echo "🌐 Installing curl..."
install_apt_tool curl "curl" curl
echo ""

# Install Git
echo "📂 Installing Git version control..."
install_apt_tool git "Git" git
echo ""

#Install github-cli
echo "🐙 Installing GitHub CLI..."
if ! {
  (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y
}; then
  echo "❌ GitHub CLI installation failed"
  record_tool_result github-cli false
  exit 1
fi
record_tool_result github-cli true
echo "✅ GitHub CLI installed successfully"
echo ""

# Install NVM
echo "📦 Installing Node Version Manager (NVM)..."
if ! wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
  echo "❌ NVM installation failed"
  record_tool_result nvm-node false
  exit 1
fi
echo "✅ NVM downloaded and installed"
echo ""

# Set up NVM to run locally
echo "⚙️  Configuring NVM environment..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install latest LTS Node version
echo "🚀 Installing latest LTS Node.js version..."
if ! command -v nvm >/dev/null 2>&1; then
  echo "❌ nvm command not available after installation"
  record_tool_result nvm-node false
  exit 1
fi

if ! nvm install --lts; then
  echo "❌ Node.js LTS installation failed"
  record_tool_result nvm-node false
  exit 1
fi
echo "✅ Node.js LTS installed successfully"
record_tool_result nvm-node true
echo ""


# Install postgres
echo "🐘 Installing PostgreSQL database server..."
install_apt_tool postgresql "PostgreSQL" postgresql postgresql-contrib
echo ""

# Starts Postgres service
echo "🔄 Starting PostgreSQL service..."
if [[ "${TOOL_RESULTS[postgresql]:-false}" == "true" ]] && sudo systemctl start postgresql.service; then
  echo "✅ PostgreSQL service started"
else
  echo "⚠️  PostgreSQL service was not started."
fi
echo ""

# Install dbeaver
echo "🗄️  Installing DBeaver database client..."
if command -v snap >/dev/null 2>&1; then
  if sudo snap install dbeaver-ce --classic; then
    record_tool_result dbeaver true
    echo "✅ DBeaver installed successfully"
  else
    echo "❌ DBeaver installation failed"
    record_tool_result dbeaver false
    exit 1
  fi
else
  record_tool_result dbeaver false
  echo "⚠️  snap not found. Skipping DBeaver installation."
fi
echo ""

# Install Redis
echo "📊 Installing Redis in-memory database..."
echo "   - Adding Redis package repository..."
if sudo apt-get install -y curl gpg \
  && curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg \
  && sudo chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb ${UBUNTU_CODENAME_VALUE} main" | sudo tee /etc/apt/sources.list.d/redis.list >/dev/null \
  && sudo apt-get update \
  && sudo apt-get install -y redis; then
  record_tool_result redis true
  echo "✅ Redis installed successfully"
else
  record_tool_result redis false
  echo "⚠️  Redis installation failed."
fi
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
if sudo apt update && sudo apt install -y code; then
  record_tool_result vscode true
  echo "✅ VS Code installed successfully"
else
  record_tool_result vscode false
  echo "⚠️  VS Code installation failed."
fi
echo ""

# Set up docker
echo "🐳 Installing Docker container platform..."
echo "   - Removing old Docker packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
echo "   - Setting up Docker repository..."
sudo apt-get update
if ! sudo apt-get install -y ca-certificates curl; then
  echo "⚠️  Docker prerequisites installation failed."
fi
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  ${UBUNTU_CODENAME_VALUE} stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "   - Installing Docker Engine..."
if sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
  record_tool_result docker true
  echo "✅ Docker installed successfully"
else
  record_tool_result docker false
  echo "⚠️  Docker installation failed."
fi
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
if sudo apt update && sudo apt install -y insomnia; then
  record_tool_result insomnia true
elif sudo apt install -f -y && sudo apt install -y insomnia; then
  record_tool_result insomnia true
fi
if [[ "${TOOL_RESULTS[insomnia]:-false}" == "true" ]]; then
  echo "✅ Insomnia installed successfully"
else
  record_tool_result insomnia false
  echo "⚠️  Insomnia installation failed."
fi
echo ""

# Install AWS CLI
echo "☁️  Installing AWS CLI..."
echo "   - Installing from apt repository..."
install_apt_tool aws-cli "AWS CLI" awscli
echo ""

echo "========================================="
echo "🎉 Development Tools Setup Complete!"
echo "========================================="
echo ""
echo "📋 Summary of what was installed:"
print_tool_summary
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