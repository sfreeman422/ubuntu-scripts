# ubuntu-scripts

Automated first-time desktop setup for either Ubuntu or Omarchy.

This repository provides a guided, script-driven setup for:

- System packages and baseline configuration
- Development tooling (GitHub CLI, Node/NVM, PostgreSQL, Redis, Docker, VS Code, etc.)
- ZSH + Powerlevel10k theme setup
- Essential desktop applications
- Gaming tooling (Wine + Lutris)
- Theme automation (sunrise/sunset light-dark switching)
- Backup automation
- Downloads cleanup automation

## Supported Environments

- Ubuntu (validated: 24.04 and 26.04)
- GNOME desktop session
- Omarchy
- Hyprland / Omarchy desktop session

`main.sh` auto-detects the current operating system and dispatches to the matching OS-specific setup scripts.

## Repository Layout

- `main.sh` - Primary orchestrator for full setup and dry-run mode
- `os/ubuntu/` - Ubuntu-specific setup entrypoints
- `os/omarchy/` - Omarchy-specific setup entrypoints
- `system/system-level-setup.sh` - Ubuntu core system setup implementation
- `dev/dev-setup.sh` - Ubuntu developer tooling installation
- `dev/zsh-theme.sh` - Ubuntu Nerd Fonts + Powerlevel10k setup
- `app/app-setup.sh` - Ubuntu desktop app installs
- `scripts/gaming/gaming.sh` - Ubuntu Wine and Lutris setup
- `scripts/theme-automation/theme-automation-setup.sh` - Ubuntu GNOME theme automation install
- `scripts/theme-automation/omarchy-theme-automation.sh` - Omarchy theme automation runner
- `scripts/backup/backup-setup.sh` - Backup automation installer
- `scripts/downloads-cleanup/downloads-cleanup-setup.sh` - Downloads cleanup installer
- `scripts/ubuntu-dry-run.sh` - Ubuntu readiness checks (non-destructive)
- `scripts/ubuntu-gnome-smoke-test.sh` - Basic Ubuntu + GNOME preflight check
- `lib/os-detection.sh` - Shared OS detection helpers
- `lib/setup-common.sh` - Shared setup helpers

## Quick Start

From the repository root:

```bash
chmod +x main.sh
./main.sh
```

To override auto-detection explicitly:

```bash
./main.sh --os ubuntu
./main.sh --os omarchy
```

The setup is interactive and may prompt for:

- sudo authentication
- backup destination (optional backup step)

## Dry-Run Mode (Recommended First)

Use dry-run to validate readiness without making system changes:

```bash
./main.sh --dry-run
```

Strict dry-run treats warnings as failures (for CI-like gating):

```bash
./main.sh --dry-run --strict
```

Dry-run checks include:

- OS/session validation
- Required command availability
- Package visibility for the selected target
- Planned setup step preview
- Detailed check summary at the end

## Full Setup Flow

`main.sh` executes steps in order and fail-fasts on required step failures:

1. System level setup
2. Development tools setup
3. Shell and fonts setup
4. Application setup
5. Gaming setup
6. Theme automation setup
7. Backup automation setup (optional)
8. Downloads cleanup setup

Ubuntu steps are sourced from `os/ubuntu/`, while Omarchy-specific steps are sourced from `os/omarchy/`. Shared automation such as backup setup and downloads cleanup remains reusable across both targets, while shell/theme bootstrapping stays OS-specific.

At the end, a step result summary is printed with passed/skipped/failed states.

## Optional and Fallback Behavior

Some app installs are best-effort with fallbacks:

- Discord: apt first, then snap fallback
- Slack: direct .deb first, then snap fallback

If optional app endpoints are temporarily unavailable, core setup can still proceed.

## Useful Commands

Run smoke test:

```bash
./os/ubuntu/smoke-test.sh
./os/omarchy/smoke-test.sh
```

Show help:

```bash
./main.sh --help
```

## Notes and Safety

- Backup and cleanup automation install cron jobs for your current user.
- Backup setup prompts for destination before enabling scheduled backup.
- Downloads cleanup removes files older than 30 days and prunes empty directories.
- Theme automation uses a user-level systemd timer.

## Troubleshooting

If setup stops early:

1. Re-run dry-run strict:

```bash
./main.sh --dry-run --strict
```

2. Fix reported failures.
3. Re-run full setup:

```bash
./main.sh
```

If a step fails, `main.sh` now stops on required-step errors and prints a step result summary so you can identify the failure point quickly.

## Maintainer Notes

Use this checklist when preparing support for a new Ubuntu release.

### 1) Update validated release list

- Update `is_supported_ubuntu_release()` in `lib/ubuntu-release.sh`.
- Keep previous LTS in the list while transition testing is in progress.
- Run both:
	- `./main.sh --dry-run`
	- `./main.sh --dry-run --strict`

### 2) Re-verify codename-based repositories

Key areas to check:

- Redis repository in `dev/dev-setup.sh`
- Docker repository in `dev/dev-setup.sh`
- WineHQ source selection in `scripts/gaming/gaming.sh`

If a provider lags codename support:

- Prefer helper-based codename fallback in `lib/ubuntu-release.sh`
- Keep strict dry-run focused on core blockers, not transient optional app endpoints

### 3) Re-verify direct package URLs

Check these endpoints in dry-run output and update if they change:

- Slack latest .deb
- Steam .deb
- Zoom .deb
- ProtonMail Bridge .deb
- Lutris release .deb

### 4) Keep install paths resilient and idempotent

- Use script-directory-relative paths for file copy operations.
- Avoid appending duplicate config lines on reruns.
- Keep optional app installs as best-effort with clear fallback behavior.

### 5) Validate ordering and failure behavior

- Required setup steps should fail-fast in `main.sh`.
- Optional steps should report skipped/failed clearly without hiding required-step failures.
- Ensure final step summary reflects actual outcomes.

### 6) Minimum verification before merge

Run shell syntax checks:

- `bash -n main.sh`
- `bash -n system/system-level-setup.sh`
- `bash -n dev/dev-setup.sh`
- `bash -n dev/zsh-theme.sh`
- `bash -n os/ubuntu/shell-setup.sh`
- `bash -n os/omarchy/shell-setup.sh`
- `bash -n app/app-setup.sh`
- `bash -n scripts/gaming/gaming.sh`
- `bash -n scripts/theme-automation/theme-automation-setup.sh`
- `bash -n scripts/backup/daily-backup.sh`
- `bash -n scripts/downloads-cleanup/downloads-cleanup-setup.sh`
- `bash -n scripts/downloads-cleanup/downloads-cleanup.sh`
- `bash -n scripts/ubuntu-dry-run.sh`
- `bash -n lib/ubuntu-release.sh`
- `bash -n lib/os-detection.sh`
- `bash -n lib/setup-common.sh`
- `bash -n os/ubuntu/system-level-setup.sh`
- `bash -n os/ubuntu/dev-setup.sh`
- `bash -n os/ubuntu/app-setup.sh`
- `bash -n os/ubuntu/gaming.sh`
- `bash -n os/ubuntu/theme-automation-setup.sh`
- `bash -n os/ubuntu/dry-run.sh`
- `bash -n os/ubuntu/smoke-test.sh`
- `bash -n os/omarchy/common.sh`
- `bash -n os/omarchy/system-level-setup.sh`
- `bash -n os/omarchy/dev-setup.sh`
- `bash -n os/omarchy/app-setup.sh`
- `bash -n os/omarchy/gaming.sh`
- `bash -n os/omarchy/theme-automation-setup.sh`
- `bash -n os/omarchy/dry-run.sh`
- `bash -n os/omarchy/smoke-test.sh`
- `bash -n scripts/theme-automation/omarchy-theme-automation.sh`

Then run:

- `./main.sh --dry-run --strict`

For release candidates, also validate full setup in a fresh Ubuntu VM snapshot before publishing changes.
