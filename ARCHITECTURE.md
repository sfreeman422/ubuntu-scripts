# Architecture Overview

## Desktop Environment Layer

The scripts are designed for Ubuntu with GNOME.

```
┌─────────────────────────────────────────────────────────────┐
│                    User Scripts                             │
│  (system-level-setup.sh, theme-automation.sh, etc.)        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│         Desktop Environment Library                         │
│         lib/gnome-environment.sh                            │
│                                                             │
│  • detect_desktop_environment()                             │
│  • is_desktop_environment()                                 │
│  • has_gnome()                                              │
│  • get_current_theme()                                      │
│  • set_theme()                                              │
│  • get_required_commands()                                  │
│  • check_required_commands()                                │
│  • install_missing_dependencies()                           │
└─────────────────────────────────────────────────────────────┘
```

## Detection Flow

```
detect_desktop_environment()
    │
    ├─► Check $DESKTOP_SESSION (gnome, ubuntu, pop)
    ├─► Check $XDG_CURRENT_DESKTOP (*GNOME*)
    ├─► Check command availability (gnome-shell)
    └─► Fallback: return "unknown"
```

## Theme Flow

```
set_theme("light" or "dark")
    │
    ├─► Validate GNOME environment
    ├─► Apply Yaru or Yaru-dark via gsettings
    └─► Apply GNOME color-scheme preference
```

## Key Paths

```
ubuntu-scripts/
├── lib/gnome-environment.sh
├── scripts/theme-automation/theme-automation.sh
├── scripts/theme-automation/theme-automation-setup.sh
├── scripts/theme-automation/test-theme-automation.sh
└── system/system-level-setup.sh
```

## Dependency Resolution

Required command set:

- `curl`
- `jq`
- `gsettings` (GNOME)

Scripts validate required commands at startup and either install missing items or fail with a clear GNOME-specific message.

## Cross-Cutting Concerns

- Firefox theming is handled in `set_firefox_theme()` and is independent of desktop-shell APIs.
- Snap theming is applied through GNOME `color-scheme` preferences.
- Unsupported desktop sessions are rejected with explicit errors in setup/runtime scripts.
