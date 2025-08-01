echo "Starting Ubuntu First-Time Setup..."

./system/system-level-setup.sh
./dev/dev-setup.sh
./dev/zsh-theme.sh
./app/app-setup.sh
./scripts/backup-setup.sh
./scripts/downloads-cleanup-setup.sh
echo "Setup complete! Please reboot your system."