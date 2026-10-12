#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mode="plan"

usage() {
    printf 'Usage: %s [--apply]\n\n' "${0##*/}"
    printf 'Without --apply, show the planned changes. With --apply, back up existing Spicetify files, install the repo theme and Marketplace app, and apply them to Spotify.\n'
}

case "${1:-}" in
    "") ;;
    --apply) mode="apply" ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

if [[ -z "${HOME:-}" || "$HOME" == "/" || "${EUID:-1}" -eq 0 ]]; then
    printf 'ERROR: Run this as your regular user with a valid home directory.\n' >&2
    exit 1
fi

if [[ "$mode" == "apply" && ! -t 0 ]]; then
    printf 'ERROR: --apply needs an interactive terminal so you can review the change.\n' >&2
    exit 1
fi

spotify_path="$HOME/.local/share/spotify-launcher/install/usr/share/spotify"
if [[ ! -d "$spotify_path" ]]; then
    spotify_path="/opt/spotify"
fi
theme_source="$repo_dir/config/spicetify/Themes/text"
marketplace_source="$repo_dir/config/spicetify/CustomApps/marketplace"
theme_target="$HOME/.config/spicetify/Themes/text"
marketplace_target="$HOME/.config/spicetify/CustomApps/marketplace"
config_target="$HOME/.config/spicetify/config-xpui.ini"

for required in "$theme_source/color.ini" "$theme_source/user.css" "$marketplace_source/manifest.json" "$marketplace_source/extension.js" "$marketplace_source/index.js" "$marketplace_source/style.css"; do
    if [[ ! -f "$required" ]]; then
        printf 'ERROR: Required repo file is missing: %s\n' "$required" >&2
        exit 1
    fi
done

if [[ ! -d "$spotify_path" ]]; then
    printf 'ERROR: Spotify client not found. Install spotify-launcher or the Arch spotify package first.\n' >&2
    exit 1
fi
if [[ ! -f "$HOME/.config/spotify/prefs" ]]; then
    printf 'ERROR: Spotify preferences not found. Launch Spotify, sign in, leave it open briefly, then retry.\n' >&2
    exit 1
fi

for target in "$HOME/.config" "$HOME/.config/spicetify" "$HOME/.config/spicetify/Themes" "$theme_target" "$HOME/.config/spicetify/CustomApps" "$marketplace_target"; do
    if [[ -L "$target" ]]; then
        printf 'ERROR: Refusing to write through symlink: %s\n' "$target" >&2
        exit 1
    fi
done
for target in "$theme_target" "$marketplace_target"; do
    if [[ -e "$target" && ! -d "$target" ]]; then
        printf 'ERROR: Expected a directory at %s; left it untouched.\n' "$target" >&2
        exit 1
    fi
done
if [[ -e "$config_target" && ! -f "$config_target" ]]; then
    printf 'ERROR: Expected a regular file at %s; left it untouched.\n' "$config_target" >&2
    exit 1
fi
if [[ -L "$config_target" && ! -f "$config_target" ]]; then
    printf 'ERROR: The Spicetify config link is broken: %s\n' "$config_target" >&2
    exit 1
fi

aur_helper=""
spicetify_missing=0
if ! command -v spicetify >/dev/null 2>&1; then
    spicetify_missing=1
    if command -v paru >/dev/null 2>&1; then aur_helper="paru"; elif command -v yay >/dev/null 2>&1; then aur_helper="yay"; fi
    if [[ -z "$aur_helper" ]]; then
        printf 'ERROR: spicetify is missing; install spicetify-cli from the AUR first (paru/yay required).\n' >&2
        exit 1
    fi
fi

backup_root="$HOME/.config-backups/arch-install-home/spicetify-$(date '+%Y-%m-%d_%H-%M-%S')-$$"
printf 'Spotify client: %s\n' "$spotify_path"
printf 'Theme: text (Monochrome)\nMarketplace app: enabled\n'
if (( spicetify_missing )); then printf 'Spicetify CLI will be installed with %s.\n' "$aur_helper"; fi
if [[ -e "$theme_target" ]]; then printf 'Theme files will be backed up to %s/Themes/text\n' "$backup_root"; fi
if [[ -e "$marketplace_target" ]]; then printf 'Marketplace files will be backed up to %s/CustomApps/marketplace\n' "$backup_root"; fi
if [[ -e "$config_target" ]]; then printf 'Spicetify config will be backed up to %s/config-xpui.ini\n' "$backup_root"; fi
printf 'Spicetify will then set spotify_path and apply the theme and Marketplace to Spotify.\n'

if [[ "$mode" == "plan" ]]; then
    printf '\nPreview only. Run %s --apply to review and apply.\n' "${0##*/}"
    exit 0
fi

read -r -p 'Proceed with this backed-up Spicetify setup? [y/N] ' answer
if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    printf 'Cancelled without changing Spicetify files.\n'
    exit 0
fi

backup_needed=0
for target in "$theme_target" "$marketplace_target" "$config_target"; do
    [[ -e "$target" ]] && backup_needed=1
done
if (( spicetify_missing )); then
    read -r -p "Install spicetify-cli using $aur_helper? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        printf 'Cancelled before changing Spicetify files.\n'
        exit 0
    fi
    "$aur_helper" -S --needed spicetify-cli
fi

if (( backup_needed )); then
    mkdir -p -- "$backup_root"
    if [[ -e "$theme_target" ]]; then
        mkdir -p -- "$backup_root/Themes" "$backup_root/legacy-links/Themes"
        cp -RLp -- "$theme_target" "$backup_root/Themes/text"
        mv -- "$theme_target" "$backup_root/legacy-links/Themes/text"
    fi
    if [[ -e "$marketplace_target" ]]; then
        mkdir -p -- "$backup_root/CustomApps" "$backup_root/legacy-links/CustomApps"
        cp -RLp -- "$marketplace_target" "$backup_root/CustomApps/marketplace"
        mv -- "$marketplace_target" "$backup_root/legacy-links/CustomApps/marketplace"
    fi
    if [[ -L "$config_target" ]]; then
        cp -L -p -- "$config_target" "$backup_root/config-xpui.ini"
        mkdir -p -- "$backup_root/legacy-links"
        mv -- "$config_target" "$backup_root/legacy-links/config-xpui.ini"
        cp -p -- "$backup_root/config-xpui.ini" "$config_target"
    elif [[ -e "$config_target" ]]; then
        cp -a -- "$config_target" "$backup_root/config-xpui.ini"
    fi
    printf '[BACKUP] %s\n' "$backup_root"
fi

mkdir -p -- "$theme_target" "$marketplace_target"
cp -a -- "$theme_source/." "$theme_target/"
cp -a -- "$marketplace_source/." "$marketplace_target/"
spicetify config spotify_path "$spotify_path" prefs_path "$HOME/.config/spotify/prefs" current_theme text color_scheme Monochrome custom_apps marketplace
spicetify backup apply

printf '\nSpicetify applied. Restart Spotify to see the theme and Marketplace tab.\n'
if (( backup_needed )); then printf 'Backup: %s\n' "$backup_root"; fi
