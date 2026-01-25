# Architecture Overview

## Desktop Environment Abstraction Layer

```
┌─────────────────────────────────────────────────────────────┐
│                    User Scripts                              │
│  (system-level-setup.sh, theme-automation.sh, etc.)          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│         Desktop Environment Library (NEW)                    │
│         lib/desktop-environment.sh                           │
│                                                              │
│  • detect_desktop_environment()                             │
│  • is_desktop_environment()                                 │
│  • has_gnome() / has_xfce()                                 │
│  • get_current_theme()                                      │
│  • set_theme() - DE-agnostic theme setting                  │
│  • get_required_commands()                                  │
│  • check_required_commands()                                │
│  • install_missing_dependencies()                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        ▼                             ▼
┌──────────────────────┐      ┌──────────────────────┐
│   GNOME Backend      │      │   XFCE Backend       │
│                      │      │                      │
│  • gsettings         │      │  • xfconf-query      │
│  • Yaru themes       │      │  • Xfce themes      │
│  • GNOME Tweaks      │      │  • XFCE Tweaks      │
│  • GNOME extensions  │      │  • Xfwm4 config     │
└──────────────────────┘      └──────────────────────┘
```

## Detection Flow

```
detect_desktop_environment()
    │
    ├─► Check $DESKTOP_SESSION env var
    │   └─► Match: gnome, ubuntu, pop, xfce, xubuntu
    │
    ├─► Check $XDG_CURRENT_DESKTOP env var
    │   └─► Match: contains GNOME or XFCE
    │
    ├─► Check command availability
    │   ├─► gnome-shell? → return "gnome"
    │   └─► xfce4-session? → return "xfce"
    │
    └─► Fallback: return "generic"
```

## Theme Setting Flow

```
set_theme("light" or "dark")
    │
    ├─► Detect current DE
    │
    ├─► GNOME Path:
    │   ├─► gsettings set org.gnome.desktop.interface gtk-theme
    │   ├─► gsettings set icon-theme
    │   ├─► gsettings set cursor-theme
    │   ├─► gsettings set wm theme
    │   └─► gsettings set color-scheme
    │
    ├─► XFCE Path:
    │   ├─► xfconf-query /Net/ThemeName
    │   ├─► xfconf-query /Net/IconThemeName
    │   └─► xfconf-query /general/theme
    │
    └─► Configure Firefox (DE-agnostic)
```

## File Structure

```
ubuntu-scripts/
├── lib/
│   └── desktop-environment.sh (NEW)      ← Core library
│
├── scripts/
│   └── theme-automation/
│       ├── theme-automation.sh           ← Uses library
│       ├── theme-automation-setup.sh     ← Uses library
│       └── test-theme-automation.sh      ← Uses library
│
├── system/
│   └── system-level-setup.sh             ← Uses library
│
├── XFCE_GNOME_SUPPORT.md                 ← Full documentation
└── XFCE_GNOME_QUICK_REFERENCE.md         ← Quick guide
```

## Dependency Resolution

```
Script Startup
    │
    ├─► Detect desktop environment
    │
    ├─► Get required commands: get_required_commands()
    │   └─► curl, jq + DE-specific (gsettings or xfconf-query)
    │
    ├─► Check availability: check_required_commands()
    │   └─► If missing, offer auto-install
    │
    └─► Proceed with DE-specific operations
```

## Cross-Cutting Concerns

### Firefox Theme Configuration

- **Location**: Library function `set_firefox_theme()`
- **Status**: Works identically for both GNOME and XFCE
- **Implementation**: Modifies user.js preferences (DE-agnostic)

### Snap Application Theming

- **Status**: Handled via GTK theme settings
- **GNOME**: Uses color-scheme preference
- **XFCE**: Works through GTK theme propagation
- **Firefox**: Explicit user.js configuration

### Error Handling

- Missing dependencies: Graceful install or error message
- Unsupported DE: Clear error with guidance
- Missing commands: Feature skip with warning
- No GUI environment: Graceful exit

## Extensibility

To add support for another desktop environment (e.g., KDE Plasma):

1. Add detection to `detect_desktop_environment()`
2. Implement DE-specific theme functions
3. Add to case statements in `set_light_theme()` and `set_dark_theme()`
4. Update dependency checks in `get_required_commands()`
5. Test with all scripts

Example:

```bash
kde)
    # KDE Plasma uses kconfigrc
    kwriteconfig5 --file ~/.config/kdeglobals --group Colors:Window
    ;;
```

## Backward Compatibility

- ✅ All existing GNOME-based scripts continue to work
- ✅ No changes to public script interfaces
- ✅ No breaking changes to configuration files
- ✅ Graceful fallback for unsupported DEs
