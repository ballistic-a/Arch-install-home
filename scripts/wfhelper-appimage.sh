#!/usr/bin/env bash

set -euo pipefail
mode="plan"
case "${1:-}" in
    "") ;;
    --apply) mode="apply" ;;
    --help|-h) printf 'Usage: %s [--apply]\nPreview by default; --apply downloads WFHelper 2.1.1 to ~/Applications.\n' "${0##*/}"; exit 0 ;;
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

app_dir="$HOME/Applications"
app_path="$app_dir/WFHelper-2.1.1.AppImage"
url="https://github.com/WFHelper/WFHelper/releases/download/v2.1.1/WFHelper-2.1.1.AppImage"
if [[ -L "$app_dir" || -L "$app_path" ]]; then
    printf 'ERROR: Refusing to write through a symlink under %s.\n' "$HOME" >&2
    exit 1
fi
if [[ -e "$app_dir" && ! -d "$app_dir" ]]; then
    printf 'ERROR: Expected a directory at %s; left it untouched.\n' "$app_dir" >&2
    exit 1
fi
if [[ -e "$app_path" && ! -f "$app_path" ]]; then
    printf 'ERROR: Expected a regular file at %s; left it untouched.\n' "$app_path" >&2
    exit 1
fi

printf 'WFHelper release: 2.1.1\nDownload: %s\nDestination: %s\n' "$url" "$app_path"
if [[ -f "$app_path" ]]; then
    printf 'An existing copy will be backed up before replacement.\n'
fi
printf 'After download, the extraction command is:\n  cd %s && ./WFHelper-2.1.1.AppImage --appimage-extract\n' "$app_dir"
if [[ "$mode" == plan ]]; then
    printf '\nPreview only. Run %s --apply to download.\n' "${0##*/}"
    exit 0
fi

answer=""
read -r -p 'Download WFHelper 2.1.1 now? [y/N] ' answer
if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    printf 'Cancelled without downloading.\n'
    exit 0
fi
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    printf 'ERROR: Install curl or wget first.\n' >&2
    exit 1
fi

mkdir -p -- "$app_dir"
if [[ -f "$app_path" ]]; then
    backup="$HOME/.config-backups/arch-install-home/wfhelper-$(date '+%Y-%m-%d_%H-%M-%S')-$$/WFHelper-2.1.1.AppImage"
    mkdir -p -- "$(dirname -- "$backup")"
    cp -a -- "$app_path" "$backup"
    printf '[BACKUP] %s\n' "$backup"
fi
temporary="$app_path.tmp.$$"
trap 'rm -f -- "$temporary"' EXIT
if command -v curl >/dev/null 2>&1; then
    curl --fail --location --retry 3 --output "$temporary" "$url"
else
    wget --output-document="$temporary" "$url"
fi
chmod 0755 "$temporary"
mv -f -- "$temporary" "$app_path"
trap - EXIT
printf '[DONE] Downloaded executable: %s\n' "$app_path"
printf 'To extract it, run:\n  cd %s && ./WFHelper-2.1.1.AppImage --appimage-extract\n' "$app_dir"
