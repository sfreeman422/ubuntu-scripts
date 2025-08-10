# Ubuntu Theme Automation

Automatically switches Ubuntu between light and dark themes based on sunrise and sunset times for your location.

## Features

- **Location Detection**: Determines your location using IP geolocation (with fallback services)
- **Sunrise/Sunset API**: Uses sunrise-sunset.org API to get accurate solar times
- **Automatic Switching**: Light theme during day, dark theme during night
- **Caching**: Caches location and sunrise/sunset data to minimize API calls
- **Systemd Integration**: Runs automatically every 15 minutes using systemd timers
- **Manual Override**: Command-line options to force light or dark themes
- **Logging**: Detailed logs for troubleshooting

## Installation

The theme automation is included in the main Ubuntu setup script. To install manually:

```bash
cd scripts/theme-automation
./theme-automation-setup.sh
```

## Usage

### Automatic Mode

Once installed, the script runs automatically every 15 minutes and switches themes based on sunrise/sunset.

### Manual Controls

```bash
# Force light theme
./theme-automation.sh --light

# Force dark theme
./theme-automation.sh --dark

# Check current status
./theme-automation.sh --status

# Show help
./theme-automation.sh --help
```

### Service Management

```bash
# Start the timer
systemctl --user start theme-automation.timer

# Stop the timer
systemctl --user stop theme-automation.timer

# Check status
systemctl --user status theme-automation.timer

# Disable automatic switching
systemctl --user disable theme-automation.timer

# Enable automatic switching
systemctl --user enable theme-automation.timer
```

## Logs

View logs to see when theme switches occur:

```bash
tail -f ~/.theme-automation.log
```

## How It Works

1. **Location Detection**: The script first tries to get your location using IP geolocation services
2. **Sunrise/Sunset Calculation**: Uses your coordinates to fetch sunrise and sunset times from sunrise-sunset.org
3. **Theme Decision**: Compares current time with sunrise/sunset to determine if it's day or night
4. **Theme Application**: Sets appropriate Ubuntu theme using gsettings

## Supported Themes

- **Light**: Yaru (default Ubuntu light theme)
- **Dark**: Yaru-dark (default Ubuntu dark theme)

## Dependencies

- `curl` - For API requests
- `jq` - For JSON parsing
- `gsettings` - For changing GNOME settings
- GNOME desktop environment

## Fallback Behavior

If location or sunrise/sunset data cannot be retrieved:

- Falls back to simple time-based logic (6 AM - 6 PM = day)
- Continues to retry getting accurate data on subsequent runs

## Caching

- **Location**: Cached for 24 hours
- **Sunrise/Sunset**: Fetched daily
- Cache stored in `~/.cache/theme-automation/`

## Troubleshooting

### Theme not changing

1. Check if you're running GNOME desktop environment
2. Verify systemd timer is running: `systemctl --user status theme-automation.timer`
3. Check logs: `tail ~/.theme-automation.log`
4. Run manually: `./theme-automation.sh --status`

### Location not detected

- Ensure internet connection is available
- Check firewall settings for outbound HTTP requests
- Manually run: `curl -s "http://ipinfo.io/json"`

### Service not starting

- Reload systemd: `systemctl --user daemon-reload`
- Check service status: `systemctl --user status theme-automation.service`
- Ensure script is executable: `chmod +x theme-automation.sh`

## Privacy

This script uses IP-based geolocation services to determine your approximate location. The location data is cached locally and only used to fetch sunrise/sunset times. No personal data is transmitted beyond the standard IP address that web services see.
