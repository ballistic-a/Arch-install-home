#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID:-1}" -eq 0 ]]; then
    printf 'ERROR: Run this setup as your regular user, not as root.\n' >&2
    exit 1
fi

if [[ ! -t 0 ]]; then
    printf 'ERROR: Caelestia setup is interactive and needs a terminal.\n' >&2
    exit 1
fi

if [[ ! -r /etc/arch-release ]]; then
    printf 'ERROR: This setup command is for Arch Linux.\n' >&2
    exit 1
fi

aur_helper=""
if command -v paru >/dev/null 2>&1; then
    aur_helper="paru"
elif command -v yay >/dev/null 2>&1; then
    aur_helper="yay"
fi

if [[ -z "$aur_helper" ]]; then
    printf 'ERROR: Install paru or yay first. Caelestia uses AUR packages during setup.\n' >&2
    exit 1
fi

if ! command -v caelestia >/dev/null 2>&1; then
    printf 'Caelestia CLI is missing. It will be installed from the AUR with %s.\n' "$aur_helper"
    printf 'The AUR helper will show its package build and installation prompts.\n\n'
    answer=""
    read -r -p 'Install caelestia-cli now? [y/N] ' answer
    if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        printf 'Cancelled without installing anything.\n'
        exit 0
    fi

    "$aur_helper" -S --needed caelestia-cli
fi

if ! command -v caelestia >/dev/null 2>&1; then
    printf 'ERROR: The caelestia command is still unavailable after the CLI install.\n' >&2
    exit 1
fi

printf '\nNext, the official Caelestia installer will install its selected packages and deploy its upstream configuration.\n'
printf 'Review its backup prompt and every package confirmation. Existing Hyprland settings may be replaced by Caelestia settings.\n\n'
answer=""
read -r -p 'Run `caelestia install` now? [y/N] ' answer
if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    printf 'Cancelled before running the Caelestia installer.\n'
    exit 0
fi

caelestia install

if ! command -v hyprmod >/dev/null 2>&1; then
    if [[ -n "$aur_helper" ]]; then
        printf '\nThis repo includes two HyprMod settings files. HyprMod is a separate AUR application.\n\n'
        answer=""
        read -r -p "Install HyprMod with $aur_helper? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            "$aur_helper" -S --needed hyprmod
        fi
    fi
fi

printf '\nCaelestia finished. The repository settings installer will now show and ask about each shared preference.\n\n'
bash "$repo_dir/install.sh" --apply

if [[ -d "$HOME/.local/share/spotify-launcher/install/usr/share/spotify" || -d "/opt/spotify" ]]; then
    printf '\nThe repo includes a portable Spicetify theme and Marketplace app for Spotify.\n'
    answer=""
    read -r -p 'Set up Spicetify now? [y/N] ' answer
    if [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        bash "$repo_dir/setup-spicetify.sh" --apply
    fi
else
    printf '\nInstall Spotify first, then run ./setup-spicetify.sh to apply the included theme and Marketplace app.\n'
fi

printf '\nThe repo also includes your five EasyEffects output presets and the Caelestia dashboard preset buttons.\n'
answer=""
read -r -p 'Set up EasyEffects now? [y/N] ' answer
if [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    if ! command -v easyeffects >/dev/null 2>&1; then
        if command -v sudo >/dev/null 2>&1; then
            privilege="sudo"
        elif command -v doas >/dev/null 2>&1; then
            privilege="doas"
        else
            printf 'ERROR: Install EasyEffects with pacman first; sudo or doas is not available.\n' >&2
            exit 1
        fi
        "$privilege" pacman -S --needed easyeffects
    fi
    if command -v easyeffects >/dev/null 2>&1; then
        bash "$repo_dir/setup-easyeffects.sh" --apply
        bash "$repo_dir/scripts/easyeffects-presets.sh" --apply
    else
        printf 'EasyEffects is not installed; skipped its preset setup.\n'
    fi
fi

printf '\nThe repo can also install Discord and Steam without copying account or game data.\n'
answer=""
read -r -p 'Set up Discord and Steam now? [y/N] ' answer
if [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    bash "$repo_dir/setup-apps.sh" --apply
fi

printf '\nThe repo includes an optional WFHelper 2.1.1 AppImage downloader.\n'
answer=""
read -r -p 'Download WFHelper now? [y/N] ' answer
if [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    bash "$repo_dir/scripts/wfhelper-appimage.sh" --apply
fi

printf "\nSetup complete. Configure this PC's GPU driver and monitor layout using docs/per-machine.md.\n"
