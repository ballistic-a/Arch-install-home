# Setup on another Arch PC

This repository holds a Caelestia setup wrapper and user preferences, not a complete Arch installer or system image. Install Arch, hardware support, Hyprland, and an AUR helper (`paru` or `yay`) first. Then run `./setup-caelestia.sh` from the repo as your regular user. Do not copy `/etc` files from the original machine.

## 1. Install Caelestia

The setup script checks for Caelestia's CLI and offers to install `caelestia-cli` from the AUR if it is missing. It then runs the official `caelestia install` command, which installs the components and dependencies selected in its interactive setup. Because two files in this repo are HyprMod settings, the script also offers to install the `hyprmod` AUR package. It then applies the repo's four shared settings. The official Arch instructions use the `caelestia-cli` AUR package followed by `caelestia install`: [Caelestia dotfiles and CLI](https://github.com/caelestia-dots/caelestia).

The setup script does not pass `--noconfirm`; review AUR build prompts and package transactions. Caelestia deploys its own Hyprland configuration, so review the upstream installer's backup prompt before continuing if the Arch install script has already created Hyprland config files. Caelestia's configuration repo cautions against editing its managed `~/.config/hypr/` files directly; put personal changes in its user override files.

After shared settings, the setup previews a small patch to Caelestia's upstream Dashboard files. It removes the narrow resource strip, lets the calendar use the freed width, separates date selection from month navigation so selecting a day in the current month does not animate the month, marks the selected date and today, and adds Swedish holiday dots with hover labels. Official public holidays and customary days off are marked in one color; observances that are not commonly work-free use another. A daily user timer can notify you at 18:00 the evening before a listed holiday. Run `bash scripts/install-caelestia-dashboard.sh` to preview the Dashboard edits separately or append `--apply` to review and apply them. Run `bash scripts/install-swedish-holidays.sh` to preview the holiday setup or append `--apply` to install it. Both installers save timestamped backups and skip symlinked paths. Restart Caelestia if its shell is already running when you apply a QML patch. If Caelestia updates those files, rerun the script and review the proposed changes.

The holiday list includes statutory Swedish public holidays plus commonly work-free eves (Påskafton, Pingstafton, Midsommarafton, Julafton, and Nyårsafton), as well as Skärtorsdagen and Valborgsmässoafton as observances. Whether an eve is a day off depends on the job and collective agreement; the marker describes customary practice, not an employment guarantee. See [the Swedish public-holidays law](https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/lag-1989253-om-allmanna-helgdagar_sfs-1989-253/) and [Verksamt's annual leave guidance](https://verksamt.se/en/employees-recruitment/leave/vacation-annual-leave).

This wrapper does not configure the login manager, GPU driver, monitor outputs, or supply wallpaper images. It adds a horizontal wallpaper carousel inspired by [43PR's wallpaper selector](https://github.com/43PR/dotfiles), opened with **Super+Alt+W**. The carousel reads image files from `~/Pictures/Wallpapers` and applies a selection through Caelestia, including its normal wallpaper-based theme updates. Make sure your Arch install script sets up a login manager or a way to start Hyprland from a TTY. Configure GPU and monitor choices for the PC separately.

### Spotify and Spicetify

The repo includes the current `text` theme and Marketplace custom app under `config/spicetify/`. After installing Spotify and opening it once to sign in, run `./setup-spicetify.sh` to preview the setup, then `./setup-spicetify.sh --apply` to install it. The apply step asks before changing anything, backs up existing theme, Marketplace, and Spicetify config files under `~/.config-backups/arch-install-home/`, configures the detected Spotify path, and runs `spicetify backup apply`. It detects `spotify-launcher` and the standard Arch `spotify` package. If Spicetify reports a permission error for a system package, grant access using Spicetify’s Linux setup guide; the repo script does not change system permissions. Restart Spotify afterward.

The Spicetify CLI is installed separately as `spicetify-cli` from the AUR if it is missing; the script offers that package installation interactively. It does not install or switch Spotify packages. Caelestia's optional Spotify component installs the AUR `spotify` client, Spicetify, Marketplace, and Caelestia's own Spotify theme; skip that component if you want to keep `spotify-launcher` and use this repo's `text` theme. The Caelestia installer and this repo's Spicetify setup are separate choices.

### EasyEffects

The repo includes the current `Flat`, `Rock`, `Jazz`, `Pop`, and `Bass Boost` output presets under `config/easyeffects/`. During `./setup-caelestia.sh`, choose EasyEffects to install the Arch package if needed, review and copy the presets with backups, then preview and approve the Caelestia dashboard buttons. The buttons invoke `easyeffects --load-preset` for those names. You can run `./setup-easyeffects.sh` for a preview or `./setup-easyeffects.sh --apply` to install presets by itself; the dashboard update is `scripts/easyeffects-presets.sh`.

Audio device routing and the current `easyeffectsrc` database stay per-PC because they name devices attached to the original computer. The shared presets contain the equalizer settings, without those device names.

### Discord and Steam

The main setup also offers Discord and Steam. Discord installs from the AUR through `paru` or `yay`; Steam installs from the official Arch repositories when `[multilib]` is enabled. The script checks what is already installed and asks before installing either package. Discord settings, account sessions, Steam credentials, library folders, and game data are deliberately excluded from the repo.

### WFHelper AppImage

The main setup optionally downloads the pinned WFHelper 2.1.1 AppImage into `~/Applications/WFHelper-2.1.1.AppImage`; the standalone script is `scripts/wfhelper-appimage.sh`. It downloads the AppImage, creates a WFHelper entry in the desktop application menu, and does not launch it automatically. You can open WFHelper from the menu without a terminal. WFHelper needs FUSE 2 (`libfuse.so.2`), provided on Arch by `fuse2`. The installer checks for this library and asks before installing it with `sudo pacman -Syu --needed fuse2` (which performs a full system update). To install it manually, use that command before running WFHelper. To extract the AppImage manually, run:

```sh
cd ~/Applications
./WFHelper-2.1.1.AppImage --appimage-extract
```

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
| `config/quickshell/wallpaper-selector/shell.qml` | `~/.local/share/arch-install-home/wallpaper-selector/shell.qml` | Visual wallpaper carousel |
| `scripts/install-caelestia-dashboard.sh` | `~/.config/quickshell/caelestia/modules/dashboard/{Dash.qml,dash/Calendar.qml}` | Reviewed Caelestia Dashboard and calendar patch |
| `scripts/swedish-holidays.py` | `~/.local/share/arch-install-home/swedish-holidays.py` | Generates holiday data and next-day reminders |
| Holiday date data | `~/.local/state/caelestia/swedish-holidays.json` | Calendar markers across past and future years |
| User timer and service | `~/.config/systemd/user/arch-install-home-swedish-holidays.{timer,service}` | Daily 18:00 holiday reminder check |

When an existing regular file differs, the installer shows a unified diff and asks before replacing it. It saves the previous file under `~/.config-backups/arch-install-home/`. Symlink files and any destination beneath a symlinked directory are skipped so the script cannot silently write through another checkout.

The repo intentionally does not install `hyprland.lua`, Caelestia's generated Hyprland modules, or replace the Quickshell source tree. Those come from the installed upstream components. It installs the standalone wallpaper selector and offers a small, reviewed patch to the upstream Dashboard files. The shared Hyprland override sets the keyboard layout and adds the selector shortcut; per-PC monitor and hardware choices remain local. Using the same Caelestia version and preferences should get the shared settings close, but matching the current appearance also depends on wallpaper, installed apps, theme choices, display layout, and the upstream files in use.

## 3. Set up each PC separately

Choose the correct display outputs, GPU driver, and kernel support for that computer. Follow [per-machine notes](per-machine.md). Keep those files outside the shared Git profile.

## 4. Check before logging in

Review the files changed by the upstream installer and this repository. Confirm Hyprland starts, Caelestia's shell starts, audio and screenshots work, and the current PC's monitor layout is correct before removing any old configuration checkout.
