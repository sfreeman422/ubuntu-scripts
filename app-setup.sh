# Install spotify
snap install spotify -y

# Install slack
snap install slack -y

# Install discord
snap install discord -y

# Install steam
curl -L -o ~/Downloads/steam_latest.deb https://repo.steampowered.com/steam/archive/precise/steam_latest.deb
sudo apt install ~/Downloads/steam_latest.deb -y

# Download ProtonMail Bridge
curl -L -o ~/Downloads/protonmail-bridge_3.21.2-1_amd64.deb https://proton.me/download/bridge/protonmail-bridge_3.21.2-1_amd64.deb
sudo apt install ~/Downloads/protonmail-bridge_3.21.2-1_amd64.deb
sudo apt install --fix-broken -y