# Install spotify discord chromium
snap install spotify discord chromium

curl -L -o ~/Downloads/slack-desktop-4.45.64-amd64.deb https://downloads.slack-edge.com/desktop-releases/linux/x64/4.45.64/slack-desktop-4.45.64-amd64.deb
sudo apt install ~/Downloads/slack-desktop-4.45.64-amd64.deb -y
sudo apt install --fix-broken -y

# Install steam
curl -L -o ~/Downloads/steam_latest.deb https://repo.steampowered.com/steam/archive/precise/steam_latest.deb
sudo apt install ~/Downloads/steam_latest.deb -y
sudo apt install --fix-broken -y

# Download ProtonMail Bridge
curl -L -o ~/Downloads/protonmail-bridge_3.21.2-1_amd64.deb https://proton.me/download/bridge/protonmail-bridge_3.21.2-1_amd64.deb
sudo apt install ~/Downloads/protonmail-bridge_3.21.2-1_amd64.deb
sudo apt install --fix-broken -y

# Install Zoom
curl -L -o ~/Downloads/zoom_amd64.deb https://zoom.us/client/latest/zoom_amd64.deb
sudo apt install ~/Downloads/zoom_amd64.deb -y
sudo apt install --fix-broken -y