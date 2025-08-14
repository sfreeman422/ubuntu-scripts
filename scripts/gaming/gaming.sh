sudo dpkg --add-architecture i386 
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources

sudo apt update 
sudo apt install --install-recommends winehq-stable -y

# Download the latest Lutris package from https://github.com/lutris/lutris/releases
# The command below references Lutris version v0.5.18 as an example; please verify you are installing the latest version:
wget -O ~/Downloads/lutris_0.5.18_all.deb https://github.com/lutris/lutris/releases/download/v0.5.18/lutris_0.5.18_all.deb
sudo dpkg -i ~/Downloads/lutris_0.5.18_all.deb
sudo apt install --fix-broken -y