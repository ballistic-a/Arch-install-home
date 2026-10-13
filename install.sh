#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mode="plan"

usage() {
    printf 'Usage: %s [--apply]\n\n' "${0##*/}"
    printf 'Without --apply, show the plan without writing files.\n'
    printf 'With --apply, review each changed destination and back it up before replacement.\n'
    printf 'This copies shared user settings only; it does not install Arch, packages, Hyprland, or Caelestia.\n'
}

if (( $# > 1 )); then
    usage >&2
    exit 2
fi

case "${1:-}" in
    "") ;;
    --apply) mode="apply" ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac

if [[ -z "${HOME:-}" || "$HOME" == "/" ]]; then
    printf 'ERROR: HOME must point to a regular user home directory.\n' >&2
    exit 1
fi

if [[ "${EUID:-1}" -eq 0 ]]; then
    printf 'ERROR: Run this settings installer as your regular user, not as root.\n' >&2
    exit 1
fi

if [[ "$mode" == "apply" && ! -t 0 ]]; then
    printf 'ERROR: --apply needs an interactive terminal so each change can be reviewed.\n' >&2
    exit 1
fi

files=(
    "caelestia/shell.json"
    "caelestia/hypr-user.lua"
    "hypr/hyprland-gui.lua"
    "hypr/hyprmod/user_curves.json"
)

has_symlink_parent() {
    local parent
    parent="$(dirname -- "$1")"
    while [[ "$parent" != "$HOME" && "$parent" != "/" ]]; do
        if [[ -L "$parent" ]]; then
            return 0
        fi
        parent="$(dirname -- "$parent")"
    done
    return 1
}

timestamp="$(date '+%Y-%m-%d_%H-%M-%S')-$$"
backup_root="$HOME/.config-backups/arch-install-home/$timestamp"
changed=0
skipped=0

# Check every source before any destination can be changed.
for relative_path in "${files[@]}"; do
    source_file="$repo_dir/config/$relative_path"
    if [[ ! -f "$source_file" ]]; then
        printf '[ERROR] Missing repository file: %s\n' "$source_file" >&2
        exit 1
    fi
done

for relative_path in "${files[@]}"; do
    source_file="$repo_dir/config/$relative_path"
    destination="$HOME/.config/$relative_path"

    if has_symlink_parent "$destination"; then
        printf '[SKIP] A parent directory for %s is a symlink; will not write through it.\n' "$destination"
        skipped=$((skipped + 1))
        continue
    fi

    if [[ -L "$destination" ]]; then
        printf '[SKIP] %s is a symlink; review its owner and target manually.\n' "$destination"
        skipped=$((skipped + 1))
        continue
    fi

    if [[ -e "$destination" && ! -f "$destination" ]]; then
        printf '[SKIP] %s exists and is not a regular file.\n' "$destination"
        skipped=$((skipped + 1))
        continue
    fi

    if [[ -f "$destination" ]] && cmp -s -- "$source_file" "$destination"; then
        printf '[SAME] %s already matches the repository.\n' "$destination"
        continue
    fi

    if [[ "$mode" == "plan" ]]; then
        if [[ -f "$destination" ]]; then
            printf '[PLAN] Review and back up before replacing %s\n' "$destination"
        else
            printf '[PLAN] Create %s\n' "$destination"
        fi
        changed=$((changed + 1))
        continue
    fi

    if [[ -f "$destination" ]]; then
        printf '\n--- Proposed change for %s ---\n' "$destination"
        if diff -u --label "current/$relative_path" --label "repository/$relative_path" \
            "$destination" "$source_file"; then
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
            skipped=$((skipped + 1))
            continue
        fi

        backup="$backup_root/$relative_path"
        mkdir -p -- "$(dirname -- "$backup")"
        cp -a -- "$destination" "$backup"
        printf '[BACKUP] %s\n' "$backup"
    else
        answer=""
        read -r -p "Create $destination? [y/N] " answer
        if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            printf '[SKIP] Did not create %s.\n' "$destination"
            skipped=$((skipped + 1))
            continue
        fi
    fi

    temporary="$destination.tmp.$$"
    install -D -m 0644 -- "$source_file" "$temporary"
    mv -f -- "$temporary" "$destination"
    printf '[DONE] %s\n' "$destination"
    changed=$((changed + 1))
done

if [[ "$mode" == "plan" ]]; then
    printf '\nPreview only: no files were written. Run with --apply to review each proposed change.\n'
else
    printf '\nFinished. Updated or created: %d; skipped: %d.\n' "$changed" "$skipped"
fi

if [[ "$mode" == "plan" ]]; then
    bash "$repo_dir/scripts/install-wallpaper-selector.sh"
    bash "$repo_dir/scripts/install-caelestia-dashboard.sh"
    bash "$repo_dir/scripts/install-swedish-holidays.sh"
else
    bash "$repo_dir/scripts/install-wallpaper-selector.sh" --apply
    bash "$repo_dir/scripts/install-caelestia-dashboard.sh" --apply
    bash "$repo_dir/scripts/install-swedish-holidays.sh" --apply
fi
