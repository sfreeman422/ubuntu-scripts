# ubuntu-scripts

Automated first-time Ubuntu desktop setup for a GNOME-based environment.

This repository provides a guided, script-driven setup for:

- System packages and baseline configuration
- Development tooling (GitHub CLI, Node/NVM, PostgreSQL, Redis, Docker, VS Code, etc.)
- ZSH + Powerlevel10k theme setup
- Essential desktop applications
- Gaming tooling (Wine + Lutris)
- Theme automation (sunrise/sunset light-dark switching)
- Backup automation
- Downloads cleanup automation

## Supported Environment

- Ubuntu (validated: 24.04 and 26.04)
- GNOME desktop session

The scripts are Ubuntu + GNOME focused and may not behave correctly on other distributions or desktop environments.

## Repository Layout

- `main.sh` - Primary orchestrator for full setup and dry-run mode
- `system/system-level-setup.sh` - Core system setup
- `dev/dev-setup.sh` - Developer tooling installation
- `dev/zsh-theme.sh` - Nerd Fonts + Powerlevel10k setup
- `app/app-setup.sh` - Desktop app installs
- `scripts/gaming/gaming.sh` - Wine and Lutris setup
- `scripts/theme-automation/theme-automation-setup.sh` - Theme automation install
- `scripts/backup/backup-setup.sh` - Backup automation installer
- `scripts/downloads-cleanup/downloads-cleanup-setup.sh` - Downloads cleanup installer
- `scripts/ubuntu-dry-run.sh` - Readiness checks (non-destructive)
- `scripts/ubuntu-gnome-smoke-test.sh` - Basic Ubuntu + GNOME preflight check
- `ARCHITECTURE.md` - Project architecture details

## Quick Start

From the repository root:

```bash
chmod +x main.sh
./main.sh
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

- OS and GNOME validation
- Required command availability
- External repository/download reachability
- Apt package visibility
- Planned setup step preview
- Detailed check summary at the end

## Full Setup Flow

`main.sh` executes steps in order and fail-fasts on required step failures:

1. System level setup
2. Development tools setup
3. ZSH theme and fonts setup
4. Application setup
5. Gaming setup
6. Theme automation setup
7. Backup automation setup (optional)
8. Downloads cleanup setup

At the end, a step result summary is printed with passed/skipped/failed states.

## Optional and Fallback Behavior

Some app installs are best-effort with fallbacks:

- Discord: apt first, then snap fallback
- Slack: direct .deb first, then snap fallback

If optional app endpoints are temporarily unavailable, core setup can still proceed.

## Useful Commands

Run smoke test:

```bash
./scripts/ubuntu-gnome-smoke-test.sh
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
- `bash -n app/app-setup.sh`
- `bash -n scripts/gaming/gaming.sh`
- `bash -n scripts/theme-automation/theme-automation-setup.sh`
- `bash -n scripts/backup/daily-backup.sh`
- `bash -n scripts/downloads-cleanup/downloads-cleanup-setup.sh`
- `bash -n scripts/downloads-cleanup/downloads-cleanup.sh`
- `bash -n scripts/ubuntu-dry-run.sh`
- `bash -n lib/ubuntu-release.sh`

Then run:

- `./main.sh --dry-run --strict`

For release candidates, also validate full setup in a fresh Ubuntu VM snapshot before publishing changes.
