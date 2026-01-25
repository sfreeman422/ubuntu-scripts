# GNOME to XFCE Support - Quick Reference

## What Changed?

All GNOME-specific code has been updated to automatically detect and support both GNOME and XFCE desktop environments.

## Key Files Modified

| File                                                   | Changes                                                    |
| ------------------------------------------------------ | ---------------------------------------------------------- |
| **lib/desktop-environment.sh** (NEW)                   | Desktop environment detection and theme management library |
| **scripts/theme-automation/theme-automation.sh**       | Now supports GNOME and XFCE theme switching                |
| **scripts/theme-automation/theme-automation-setup.sh** | Detects DE and installs appropriate dependencies           |
| **system/system-level-setup.sh**                       | Installs DE-specific tools and settings                    |
| **scripts/theme-automation/test-theme-automation.sh**  | Tests work with both GNOME and XFCE                        |

## How It Works

The system automatically detects your desktop environment by checking:

1. Environment variables (`DESKTOP_SESSION`, `XDG_CURRENT_DESKTOP`)
2. Availability of DE-specific commands (`gnome-shell`, `xfce4-session`)

Once detected, the appropriate commands are used:

- **GNOME**: Uses `gsettings` to manage themes
- **XFCE**: Uses `xfconf-query` to manage themes

## Themes Supported

### GNOME

- Light: Yaru
- Dark: Yaru-dark

### XFCE

- Light: Xfce
- Dark: Xfce-dark

## Installation & Usage

No changes needed! Just run the setup scripts as before:

```bash
# System setup (auto-detects your DE)
./system/system-level-setup.sh

# Theme automation setup
./scripts/theme-automation/theme-automation-setup.sh

# Run theme automation
./scripts/theme-automation/theme-automation.sh
```

## Desktop Environment Support

✅ **GNOME** - Fully supported
✅ **XFCE** - Fully supported
⚠️ **Other DEs** - Will skip DE-specific features gracefully

## If Something Goes Wrong

1. Check which DE is detected:

   ```bash
   ./scripts/theme-automation/theme-automation.sh --status
   ```

2. Run the test script to validate setup:

   ```bash
   ./scripts/theme-automation/test-theme-automation.sh
   ```

3. View detailed logs:
   ```bash
   tail -f ~/.theme-automation.log
   ```

## For Developers

The `lib/desktop-environment.sh` library provides helper functions for any script that needs to work with multiple desktop environments:

```bash
# Source the library
source lib/desktop-environment.sh

# Detect current DE
de=$(detect_desktop_environment)

# Check for specific DE
if is_desktop_environment "gnome"; then
    # GNOME-specific code
fi

# Set theme (works for both)
set_theme "light"

# Get current theme
current=$(get_current_theme)
```

See [XFCE_GNOME_SUPPORT.md](XFCE_GNOME_SUPPORT.md) for complete library documentation.
