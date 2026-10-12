#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mode="plan"
case "${1:-}" in
    "") ;;
    --apply) mode="apply" ;;
    --help|-h) printf 'Usage: %s [--apply]\nPreview by default; --apply backs up and interactively installs the repo presets.\n' "${0##*/}"; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac

if [[ -z "${HOME:-}" || "$HOME" == "/" || "${EUID:-1}" -eq 0 ]]; then
    printf 'ERROR: Run this as your regular user with a valid home directory.\n' >&2
    exit 1
fi
if [[ "$mode" == apply && ! -t 0 ]]; then
    printf 'ERROR: --apply needs an interactive terminal for review.\n' >&2
    exit 1
fi

source_dir="$repo_dir/config/easyeffects/output"
target_dir="$HOME/.local/share/easyeffects/output"
for target in "$HOME/.local" "$HOME/.local/share" "$HOME/.local/share/easyeffects" "$target_dir"; do
    if [[ -L "$target" ]]; then
        printf 'ERROR: Refusing to write through symlink: %s\n' "$target" >&2
        exit 1
    fi
done
if [[ -e "$target_dir" && ! -d "$target_dir" ]]; then
    printf 'ERROR: Expected a directory at %s; left it untouched.\n' "$target_dir" >&2
    exit 1
fi
shopt -s nullglob
presets=("$source_dir"/*.json)
if (( ${#presets[@]} == 0 )); then
    printf 'ERROR: No preset JSON files found in %s\n' "$source_dir" >&2
    exit 1
fi

backup_root="$HOME/.config-backups/arch-install-home/easyeffects-$(date '+%Y-%m-%d_%H-%M-%S')-$$"
changed=0
for source in "${presets[@]}"; do
    destination="$target_dir/${source##*/}"
    if [[ -L "$destination" ]]; then
        printf '[SKIP] Symlink: %s\n' "$destination"
        continue
    fi
    if [[ -e "$destination" && ! -f "$destination" ]]; then
        printf '[SKIP] Not a regular file: %s\n' "$destination"
        continue
    fi
    if [[ -f "$destination" ]] && cmp -s -- "$source" "$destination"; then
        printf '[SAME] %s\n' "$destination"
        continue
    fi
    changed=$((changed + 1))
    if [[ "$mode" == plan ]]; then
        printf '[PLAN] %s %s\n' "$( [[ -f "$destination" ]] && printf 'replace' || printf 'create' )" "$destination"
        continue
    fi
    if [[ -f "$destination" ]]; then
        printf '\n--- Proposed change for %s ---\n' "$destination"
        if diff -u --label "current/${source##*/}" --label "repo/${source##*/}" "$destination" "$source"; then :; else diff_status=$?; [[ $diff_status -eq 1 ]] || exit "$diff_status"; fi
        answer=""
        read -r -p 'Back up and replace this preset? [y/N] ' answer
        if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            printf '[SKIP] Left %s unchanged.\n' "$destination"
            continue
        fi
        backup="$backup_root/${source##*/}"
        mkdir -p -- "$backup_root"
        cp -a -- "$destination" "$backup"
        printf '[BACKUP] %s\n' "$backup"
    else
        answer=""
        read -r -p "Create $destination? [y/N] " answer
        if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            printf '[SKIP] Did not create %s.\n' "$destination"
            continue
        fi
    fi
    mkdir -p -- "$target_dir"
    temporary="$destination.tmp.$$"
    install -m 0644 -- "$source" "$temporary"
    mv -f -- "$temporary" "$destination"
    printf '[DONE] %s\n' "$destination"
done
if [[ "$mode" == plan ]]; then
    printf '\nPreview only. Run %s --apply to review and install these presets.\n' "${0##*/}"
else
    printf '\nEasyEffects presets finished. Changed: %d.\n' "$changed"
fi
