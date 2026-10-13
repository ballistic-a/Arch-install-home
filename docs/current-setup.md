# Current setup inventory

This inventory describes the original machine observed on 2026-10-12. It is a reference, not an automated setup recipe. Its package inventory is kept in the ignored `host-local/this-pc/` directory.

## Application packages

Discord and Steam were installed on the original PC. Their local account/session data and Steam library are not part of the shared setup; the installer offers the packages on a new Arch PC.

## Desktop configuration sources

- `~/.config/hypr` and much of `~/.config/quickshell` are symlinked to `~/dotfiles/.config`.
- `~/dotfiles` is a separate 43PR/dotfiles checkout with local edits and an untracked Quickshell backup directory. Keep that checkout and its local changes intact while migrating.
- Caelestia's upstream shell tree is `~/.config/quickshell/caelestia`; install and update it using current upstream guidance.
- `scripts/install-caelestia-dashboard.sh` applies the reviewed dashboard/calendar changes to that upstream tree with timestamped backups; the repo does not replace the full shell source.
- The user-owned Caelestia preferences are `~/.config/caelestia/shell.json` and `hypr-user.lua`; the latter is empty on the original PC. The shared profile adds the observed Swedish keyboard layout as a small user override.
- `~/.config/hypr/hyprland-gui.lua` and `hyprmod/user_curves.json` contain user-level HyprMod settings.
- The original PC's monitor files contained only `{}`. They are omitted; create local monitor settings on a PC only if it needs overrides.

## GPU and boot configuration

Driver packages, GPU diagnostics, and initramfs details are machine-specific. The original PC's notes are kept in ignored local files under `host-local/this-pc/`, not in the shared repo. Use [per-machine notes](per-machine.md) to choose drivers for another GPU and kernel. No `/etc` file is installed by this repository.

## Personal scripts

- `scripts/check-updates.sh` checks official Arch, AUR, and Flatpak updates.
- `config/easyeffects/output/` now carries the five current output presets. `scripts/easyeffects-presets.sh` previews and asks before adding the preset buttons to Caelestia media `Details.qml`, with a timestamped backup. The device database and input/output device names stay local to each PC.
- The Caelestia Dashboard patch removes its resource strip, expands the calendar into the freed width, prevents selecting a date in the current month from animating the month, and highlights today's date.
- The calendar can show Swedish statutory holidays, customary work-free eves, and observances with separate marker colors; a user timer can send the evening-before desktop reminder. Whether an eve is a day off depends on the workplace.
- `~/create-eq-presets.sh` was excluded because the inspected file contains only a stray `i` and is not a usable script.
- WFHelper 2.1.1 is an optional AppImage download; the repo downloads it only when selected and prints the `--appimage-extract` command.

## Deliberately excluded

- SSH material, tokens, credentials, and application session state.
- The upstream Caelestia shell source tree and other upstream project files.
- Runtime Quickshell state, generated theme files, and monitor-specific settings in the tracked profile.
- `/etc` files. Those require a separate, explicit review before they become portable system configuration.
