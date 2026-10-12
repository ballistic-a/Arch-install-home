# Setup on another Arch PC

This repository holds a Caelestia setup wrapper and user preferences, not a complete Arch installer or system image. Install Arch, hardware support, Hyprland, and an AUR helper (`paru` or `yay`) first. Then run `./setup-caelestia.sh` from the repo as your regular user. Do not copy `/etc` files from the original machine.

## 1. Install Caelestia

The setup script checks for Caelestia's CLI and offers to install `caelestia-cli` from the AUR if it is missing. It then runs the official `caelestia install` command, which installs the components and dependencies selected in its interactive setup, and finally offers this repo's four shared settings. The official Arch instructions use this same CLI package and command: [Caelestia dotfiles and CLI](https://github.com/caelestia-dots/caelestia).

The setup script does not pass `--noconfirm`; review AUR build prompts and package transactions. Caelestia deploys its own Hyprland configuration, so review the upstream installer's backup prompt before continuing if the Arch install script has already created Hyprland config files. Caelestia's configuration repo cautions against editing its managed `~/.config/hypr/` files directly; put personal changes in its user override files.

This wrapper does not configure the login manager, GPU driver, monitor outputs, or wallpaper. Configure those for the PC as needed.

## 2. Apply shared user settings

The setup wrapper runs this same settings installer after Caelestia succeeds. To review the settings without installing Caelestia, run:

```sh
./install.sh
./install.sh --apply
```

The installer manages only these paths:

| Repository file | Installed path | Purpose |
| --- | --- | --- |
| `config/caelestia/shell.json` | `~/.config/caelestia/shell.json` | Shared Caelestia preferences |
| `config/caelestia/hypr-user.lua` | `~/.config/caelestia/hypr-user.lua` | Shared Swedish keyboard layout |
| `config/hypr/hyprland-gui.lua` | `~/.config/hypr/hyprland-gui.lua` | HyprMod settings |
| `config/hypr/hyprmod/user_curves.json` | `~/.config/hypr/hyprmod/user_curves.json` | Custom HyprMod curve |

When an existing regular file differs, the installer shows a unified diff and asks before replacing it. It saves the previous file under `~/.config-backups/arch-install-home/`. Symlinks are skipped so the script cannot silently take over a file managed by another checkout.

The repo intentionally does not install `hyprland.lua`, Caelestia's generated Hyprland modules, or the Quickshell source tree. Those come from the installed upstream components. The shared Hyprland override only sets the keyboard layout; per-PC monitor and hardware choices remain local. Using the same Caelestia version and preferences should get the shared settings close, but matching the current appearance also depends on wallpaper, installed apps, theme choices, display layout, and the upstream files in use.

## 3. Set up each PC separately

Choose the correct display outputs, GPU driver, and kernel support for that computer. Follow [per-machine notes](per-machine.md). Keep those files outside the shared Git profile.

## 4. Check before logging in

Review the files changed by the upstream installer and this repository. Confirm Hyprland starts, Caelestia's shell starts, audio and screenshots work, and the current PC's monitor layout is correct before removing any old configuration checkout.
