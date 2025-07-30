# Install curl
sudo apt install curl -y 

# Install Git
sudo apt install git -y 

# Install spotify
snap install spotify -y

# Install slack
snap install slack -y

# Install discord
snap install discord -y

# Download ProtonMail Bridge
curl -L -o ~/Downloads/protonmail-bridge_3.21.2-1_amd64.deb https://proton.me/download/bridge/protonmail-bridge_3.21.2-1_amd64.deb
sudo apt install ~/Downloads/protonmail-bridge_3.21.2-1_amd64.deb
sudo apt install --fix-broken -y