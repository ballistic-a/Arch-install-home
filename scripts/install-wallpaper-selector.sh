#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mode="plan"
case "${1:-}" in
    "") ;;
    --apply) mode="apply" ;;
    --help|-h) printf 'Usage: %s [--apply]\nPreview by default; --apply reviews and installs the wallpaper selector.\n' "${0##*/}"; exit 0 ;;
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

source_file="$repo_dir/config/quickshell/wallpaper-selector/shell.qml"
destination="$HOME/.local/share/arch-install-home/wallpaper-selector/shell.qml"
destination_dir="$(dirname -- "$destination")"
keybind_file="$HOME/.config/caelestia/hypr-user.lua"
keybind_line='hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd("qs -p \"$HOME/.local/share/arch-install-home/wallpaper-selector/shell.qml\""))'
backup_root="$HOME/.config-backups/arch-install-home/wallpaper-selector-$(date '+%Y-%m-%d_%H-%M-%S')-$$"

if [[ ! -f "$source_file" ]]; then
    printf 'ERROR: Missing repository selector: %s\n' "$source_file" >&2
    exit 1
fi

for target in "$HOME/.local" "$HOME/.local/share" "$HOME/.local/share/arch-install-home" "$destination_dir" "$destination"; do
    if [[ -L "$target" ]]; then
        printf '[SKIP] Refusing to write through symlink: %s\n' "$target"
        exit 0
    fi
done
if [[ -L "$HOME/.config" || -L "$HOME/.config/caelestia" || -L "$keybind_file" ]]; then
    printf '[SKIP] Refusing to write through a symlink in the Caelestia user config path.\n'
    keybind_safe=0
elif [[ -e "$keybind_file" && ! -f "$keybind_file" ]]; then
    printf '[SKIP] %s exists and is not a regular file.\n' "$keybind_file"
    keybind_safe=0
else
    keybind_safe=1
fi
if [[ -e "$destination" && ! -f "$destination" ]]; then
    printf '[SKIP] %s exists and is not a regular file.\n' "$destination"
    exit 0
fi
if [[ -f "$destination" ]] && cmp -s -- "$source_file" "$destination"; then
    printf '[SAME] Wallpaper selector already matches the repository: %s\n' "$destination"
    exit 0
fi

if [[ "$mode" == plan ]]; then
    if [[ -f "$destination" ]]; then
        printf '[PLAN] Review and back up before replacing %s\n' "$destination"
    else
        printf '[PLAN] Create %s\n' "$destination"
    fi
    if (( keybind_safe )); then
        if [[ -f "$keybind_file" ]] && grep -Fq -- "$keybind_line" "$keybind_file"; then
            printf '[SAME] Shortcut already exists in %s\n' "$keybind_file"
        elif [[ -f "$keybind_file" ]]; then
            printf '[PLAN] Review and back up before adding the Super+Alt+W shortcut to %s\n' "$keybind_file"
        else
            printf '[PLAN] Create %s with only the Super+Alt+W shortcut\n' "$keybind_file"
        fi
    fi
    exit 0
fi

if [[ -f "$destination" ]]; then
    printf '\n--- Proposed wallpaper-selector change ---\n'
    if diff -u --label "current/$destination" --label "repository/wallpaper-selector/shell.qml" "$destination" "$source_file"; then
        :
    else
        diff_status=$?
        if [[ "$diff_status" -ne 1 ]]; then
            printf '[ERROR] Could not compare %s (diff exit %s).\n' "$destination" "$diff_status" >&2
            exit "$diff_status"
        fi
    fi
    printf '\n'
    answer=""
    read -r -p 'Back up and replace this file? [y/N] ' answer
    if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        printf '[SKIP] Left %s unchanged.\n' "$destination"
        exit 0
    fi
    mkdir -p -- "$backup_root"
    cp -a -- "$destination" "$backup_root/shell.qml"
    printf '[BACKUP] %s\n' "$backup_root/shell.qml"
else
    answer=""
    read -r -p "Create $destination? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        printf '[SKIP] Did not create %s.\n' "$destination"
        exit 0
    fi
fi

install -D -m 0644 -- "$source_file" "$destination.tmp.$$"
mv -f -- "$destination.tmp.$$" "$destination"
printf '[DONE] %s\n' "$destination"

if (( ! keybind_safe )); then
    printf 'The carousel is installed, but its shortcut was skipped; add the bind manually after reviewing the path.\n'
    exit 0
fi
if [[ -f "$keybind_file" ]] && grep -Fq -- "$keybind_line" "$keybind_file"; then
    printf '[SAME] Shortcut already exists in %s\n' "$keybind_file"
    exit 0
fi

keybind_tmp="$keybind_file.tmp.$$"
if [[ -f "$keybind_file" ]]; then
    cp -- "$keybind_file" "$keybind_tmp"
    printf '\n%s\n' "$keybind_line" >> "$keybind_tmp"
    printf '\n--- Proposed shortcut addition to %s ---\n' "$keybind_file"
    if diff -u --label 'current/hypr-user.lua' --label 'with wallpaper shortcut' "$keybind_file" "$keybind_tmp"; then
        :
    else
        diff_status=$?
        if [[ "$diff_status" -ne 1 ]]; then
            rm -f -- "$keybind_tmp"
            printf '[ERROR] Could not compare %s (diff exit %s).\n' "$keybind_file" "$diff_status" >&2
            exit "$diff_status"
        fi
    fi
    printf '\n'
    answer=""
    read -r -p 'Back up and add this shortcut to the existing Caelestia user config? [y/N] ' answer
    if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        rm -f -- "$keybind_tmp"
        printf '[SKIP] Left %s unchanged.\n' "$keybind_file"
        exit 0
    fi
    mkdir -p -- "$backup_root"
    cp -a -- "$keybind_file" "$backup_root/hypr-user.lua"
    printf '[BACKUP] %s\n' "$backup_root/hypr-user.lua"
else
    printf 'The keybind will be added to a new user config at %s.\n' "$keybind_file"
    answer=""
    read -r -p 'Create it with only the Super+Alt+W shortcut? [y/N] ' answer
    if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        printf '[SKIP] Did not create %s.\n' "$keybind_file"
        exit 0
    fi
    mkdir -p -- "$(dirname -- "$keybind_file")"
    printf '%s\n' "$keybind_line" > "$keybind_tmp"
fi

install -m 0644 -- "$keybind_tmp" "$keybind_file.new.$$"
mv -f -- "$keybind_file.new.$$" "$keybind_file"
rm -f -- "$keybind_tmp"
printf '[DONE] Added Super+Alt+W shortcut in %s\n' "$keybind_file"
