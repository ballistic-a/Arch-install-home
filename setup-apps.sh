#!/usr/bin/env bash

set -euo pipefail
mode="plan"
case "${1:-}" in
    "") ;;
    --apply) mode="apply" ;;
    --help|-h) printf 'Usage: %s [--apply]\nPreview by default; --apply offers to install Discord and Steam.\n' "${0##*/}"; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac

if [[ -z "${HOME:-}" || "$HOME" == "/" || "${EUID:-1}" -eq 0 ]]; then
    printf 'ERROR: Run this as your regular user with a valid home directory.\n' >&2
    exit 1
fi
if [[ "$mode" == apply && ! -t 0 ]]; then
    printf 'ERROR: --apply needs an interactive terminal.\n' >&2
    exit 1
fi
if [[ ! -r /etc/arch-release ]]; then
    printf 'ERROR: This package setup is for Arch Linux.\n' >&2
    exit 1
fi

aur_helper=""
if command -v paru >/dev/null 2>&1; then aur_helper="paru"; elif command -v yay >/dev/null 2>&1; then aur_helper="yay"; fi
privilege=""
if command -v sudo >/dev/null 2>&1; then privilege="sudo"; elif command -v doas >/dev/null 2>&1; then privilege="doas"; fi

package_installed() { pacman -Qq "$1" >/dev/null 2>&1; }
multilib_enabled() {
    awk '
        /^\[multilib\][[:space:]]*$/ { in_multilib=1; next }
        /^\[/ { in_multilib=0 }
        in_multilib && /^[[:space:]]*(Include|Server)[[:space:]]*=/ { found=1 }
        END { exit !found }
    ' /etc/pacman.conf
}
confirm() {
    local prompt="$1" answer=""
    read -r -p "$prompt [y/N] " answer
    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

if package_installed discord; then
    printf '[SAME] Discord is installed.\n'
elif [[ "$mode" == plan ]]; then
    printf '[PLAN] Install AUR package discord using %s.\n' "${aur_helper:-an AUR helper (paru or yay)}"
elif [[ -z "$aur_helper" ]]; then
    printf 'SKIP: Discord needs an AUR helper (paru or yay).\n'
elif confirm "Install Discord from the AUR with $aur_helper?"; then
    "$aur_helper" -S --needed discord
fi

if package_installed steam; then
    printf '[SAME] Steam is installed.\n'
elif ! multilib_enabled; then
    printf 'SKIP: Steam needs the [multilib] repository enabled in /etc/pacman.conf. Enable it and run this setup again.\n'
elif [[ "$mode" == plan ]]; then
    printf '[PLAN] Install official repository package steam using %s.\n' "${privilege:-sudo or doas}"
elif [[ -z "$privilege" ]]; then
    printf 'SKIP: Install Steam with pacman; sudo or doas is not available.\n'
elif confirm "Install Steam from the official repository with $privilege?"; then
    "$privilege" pacman -S --needed steam
fi
