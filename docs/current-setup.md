# Current setup inventory

This inventory describes the original machine observed on 2026-10-12. It is a reference, not an automated setup recipe. Its package inventory is kept in the ignored `host-local/this-pc/` directory.

## Desktop configuration sources

- `~/.config/hypr` and much of `~/.config/quickshell` are symlinked to `~/dotfiles/.config`.
- `~/dotfiles` is a separate 43PR/dotfiles checkout with local edits and an untracked Quickshell backup directory. Keep that checkout and its local changes intact while migrating.
- Caelestia's upstream shell tree is `~/.config/quickshell/caelestia`; install and update it using current upstream guidance.
- The user-owned Caelestia preferences are `~/.config/caelestia/shell.json` and `hypr-user.lua`; the latter is empty on the original PC. The shared profile adds the observed Swedish keyboard layout as a small user override.
- `~/.config/hypr/hyprland-gui.lua` and `hyprmod/user_curves.json` contain user-level HyprMod settings.
- The original PC's monitor files contained only `{}`. They are omitted; create local monitor settings on a PC only if it needs overrides.

## GPU and boot configuration

Driver packages, GPU diagnostics, and initramfs details are machine-specific. The original PC's notes are kept in ignored local files under `host-local/this-pc/`, not in the shared repo. Use [per-machine notes](per-machine.md) to choose drivers for another GPU and kernel. No `/etc` file is installed by this repository.

## Personal scripts

- `scripts/check-updates.sh` checks official Arch, AUR, and Flatpak updates.
- `scripts/easyeffects-presets.sh` edits the installed Caelestia media `Details.qml` after creating a timestamped backup. It depends on the upstream QML layout, so review its diff and backup before running it after an update.
- `~/create-eq-presets.sh` was excluded because the inspected file contains only a stray `i` and is not a usable script.

## Deliberately excluded

- SSH material, tokens, credentials, and application session state.
- The upstream Caelestia shell source tree and other upstream project files.
- Runtime Quickshell state, generated theme files, and monitor-specific settings in the tracked profile.
- `/etc` files. Those require a separate, explicit review before they become portable system configuration.
