# Update alias
echo 'alias uar="sudo apt update && sudo apt upgrade && sudo apt autoremove"' >> ~/.zshrc

# setup auto delete downloads after 30 days
mkdir -p ~/scripts
cp ./auto-delete-downloads-over-30.sh ~/scripts/downloads-cleanup.sh
chmod +x ~/scripts/downloads-cleanup.sh
(crontab -l ; echo "*/5 * * * * ~/scripts/downloads-cleanup.sh") | crontab -

