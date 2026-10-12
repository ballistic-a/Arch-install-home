# Arch Install Home

Portable Hyprland and Caelestia user settings, plus the steps to recreate this desktop on another Arch PC. Upstream Caelestia files and hardware-specific configuration stay separate from this shared profile.

## Quick setup

**This repository does not install Arch or hardware drivers.** After your Arch install script has set up a regular user, Hyprland, and an AUR helper (`paru` or `yay`), this repo can install Caelestia and apply its shared preferences.

1. Install Arch, including Hyprland and an AUR helper, using your Arch install script.
2. Clone this repository and run `./setup-caelestia.sh`.
3. Confirm installing `caelestia-cli`, review Caelestia's backup prompt and package confirmations, then review each shared settings change.
4. Set up monitor layouts and GPU drivers for that PC using [per-machine notes](docs/per-machine.md).

The setup command uses Caelestia's official CLI installer for its packages and upstream configuration, then runs this repo's settings installer. The settings installer backs up existing regular files under `~/.config-backups/arch-install-home/` before replacement. It skips symlinks and non-file destinations. The full setup does not choose GPU drivers or monitor outputs.

## Repository map

- `config/caelestia/`: shared Caelestia preferences and Swedish keyboard layout.
- `config/hypr/`: HyprMod user settings.
- `scripts/`: personal update and optional EasyEffects helpers.
- `docs/`: setup, per-PC configuration, and the snapshot of the original machine.
- `host-local/`: ignored local-only files for the current PC. Nothing in this directory is included in Git.

No NVIDIA driver package or monitor output is part of the shared profile. Choose those for each PC and kernel; current setup notes are in `docs/per-machine.md`.

## Sensitive files

Never add private SSH keys, tokens, credentials, environment files, or application session state. Review `git status` and staged changes before committing or pushing.
