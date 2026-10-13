# Arch Install Home

Portable Hyprland and Caelestia user settings, plus the steps to recreate this desktop on another Arch PC. Upstream Caelestia files and hardware-specific configuration stay separate from this shared profile.

## Quick setup

**This repository does not install Arch or hardware drivers.** After your Arch install script has set up a regular user, Hyprland, and an AUR helper (`paru` or `yay`), this repo can install Caelestia and apply its shared preferences.

1. Install Arch, including Hyprland and an AUR helper, using your Arch install script.
2. Clone this repository and run `./setup-caelestia.sh`.
3. Confirm installing `caelestia-cli`, review Caelestia's backup prompt and package confirmations, then review each shared settings and Dashboard change.
4. Choose whether to set up Spicetify, EasyEffects, Discord, Steam, and the optional WFHelper AppImage. The setup command installs the included presets and offers to add the Caelestia dashboard buttons.
5. Set up monitor layouts and GPU drivers for that PC using [per-machine notes](docs/per-machine.md).

The setup command uses Caelestia's official CLI installer for its packages and upstream configuration, offers HyprMod because two included settings belong to it, then runs this repo's settings installer. It offers optional Spicetify, EasyEffects, Discord, and Steam setup; settings changes are reviewed and backed up before replacement. The installer also offers targeted Dashboard and calendar edits to the installed Caelestia source: it removes the resource strip, expands the calendar into the freed width, keeps selecting a day from triggering a month transition, marks the selected date and today, and adds Swedish holidays. Official public holidays and customary days off get a distinct marker from observances; hovering shows the holiday name and category. A daily 18:00 timer can send a desktop reminder the evening before. Existing QML and reminder files are backed up before edits. The settings installer backs up existing regular files under `~/.config-backups/arch-install-home/` before replacement. It skips symlink files, symlink parent directories, and non-file destinations. The full setup does not choose a login manager, GPU drivers, or monitor outputs.

## Repository map

- `config/caelestia/`: shared Caelestia preferences and Swedish keyboard layout.
- `config/quickshell/wallpaper-selector/`: horizontal wallpaper carousel launched with Super+Alt+W.
- `config/hypr/`: HyprMod user settings.
- `config/spicetify/`: portable `text` theme and Marketplace custom app.
- `config/easyeffects/`: five portable output presets from the current setup.
- `scripts/`: personal update helpers, optional EasyEffects integration, the reviewed Caelestia Dashboard patch, and Swedish holiday data/reminders.
- `docs/`: setup, per-PC configuration, and the snapshot of the original machine.
- `host-local/`: ignored local-only files for the current PC. Nothing in this directory is included in Git.

No NVIDIA driver package or monitor output is part of the shared profile. Choose those for each PC and kernel; current setup notes are in `docs/per-machine.md`.

## Sensitive files

Never add private SSH keys, tokens, credentials, environment files, or application session state. Review `git status` and staged changes before committing or pushing.
