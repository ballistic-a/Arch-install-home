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
applications_dir="$HOME/.local/share/applications"
desktop_path="$applications_dir/wfhelper.desktop"
url="https://github.com/WFHelper/WFHelper/releases/download/v2.1.1/WFHelper-2.1.1.AppImage"
for target in "$app_dir" "$app_path" "$HOME/.local" "$HOME/.local/share" "$applications_dir" "$desktop_path"; do
    if [[ -L "$target" ]]; then
        printf 'ERROR: Refusing to write through symlink: %s\n' "$target" >&2
        exit 1
    fi
done
if [[ -e "$app_dir" && ! -d "$app_dir" ]]; then
    printf 'ERROR: Expected a directory at %s; left it untouched.\n' "$app_dir" >&2
    exit 1
fi
if [[ -e "$app_path" && ! -f "$app_path" ]]; then
    printf 'ERROR: Expected a regular file at %s; left it untouched.\n' "$app_path" >&2
    exit 1
fi
if [[ -e "$applications_dir" && ! -d "$applications_dir" ]]; then
    printf 'ERROR: Expected a directory at %s; left it untouched.\n' "$applications_dir" >&2
    exit 1
fi
if [[ -e "$desktop_path" && ! -f "$desktop_path" ]]; then
    printf 'ERROR: Expected a regular desktop entry at %s; left it untouched.\n' "$desktop_path" >&2
    exit 1
fi

printf 'WFHelper release: 2.1.1\nDownload: %s\nDestination: %s\nDesktop shortcut: %s\n' "$url" "$app_path" "$desktop_path"
if [[ -f "$app_path" || -f "$desktop_path" ]]; then
    printf 'Existing AppImage or desktop shortcut files will be backed up before replacement.\n'
fi
printf 'After download, WFHelper will be available in the application menu. To extract it manually, run:\n  cd %s && ./WFHelper-2.1.1.AppImage --appimage-extract\n' "$app_dir"
if [[ "$mode" == plan ]]; then
    printf '\nPreview only. Run %s --apply to download and create the menu shortcut.\n' "${0##*/}"
    exit 0
fi

answer=""
read -r -p 'Download WFHelper 2.1.1 now? [y/N] ' answer
if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    printf 'Cancelled without downloading.\n'
    exit 0
fi

if ! ldconfig -p 2>/dev/null | grep -F 'libfuse.so.2' >/dev/null; then
    printf '\nWFHelper requires FUSE 2 (libfuse.so.2) to run. On Arch, this is provided by the fuse2 package.\n'
    printf 'Installing it with the recommended Arch command will also perform a full system upgrade.\n'
    answer=""
    read -r -p 'Run sudo pacman -Syu --needed fuse2 now? [y/N] ' answer
    if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        printf 'Cancelled WFHelper setup. Install fuse2 with `sudo pacman -Syu fuse2`, then rerun this script.\n'
        exit 0
    fi
    if ! command -v pacman >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
        printf 'ERROR: pacman and sudo are required to install fuse2 on Arch.\n' >&2
        exit 1
    fi
    sudo pacman -Syu --needed fuse2
    if ! ldconfig -p 2>/dev/null | grep -F 'libfuse.so.2' >/dev/null; then
        printf 'ERROR: libfuse.so.2 is still unavailable after installing fuse2. WFHelper was not downloaded.\n' >&2
        exit 1
    fi
fi

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    printf 'ERROR: Install curl or wget first.\n' >&2
    exit 1
fi

mkdir -p -- "$app_dir"
backup_root="$HOME/.config-backups/arch-install-home/wfhelper-$(date '+%Y-%m-%d_%H-%M-%S')-$$"
if [[ -f "$app_path" ]]; then
    backup="$backup_root/WFHelper-2.1.1.AppImage"
    mkdir -p -- "$backup_root"
    cp -a -- "$app_path" "$backup"
    printf '[BACKUP] %s\n' "$backup"
fi
if [[ -f "$desktop_path" ]]; then
    backup="$backup_root/wfhelper.desktop"
    mkdir -p -- "$backup_root"
    cp -a -- "$desktop_path" "$backup"
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

mkdir -p -- "$applications_dir"
desktop_temporary="$desktop_path.tmp.$$"
exec_path="${app_path//%/%%}"
{
    printf '[Desktop Entry]\n'
    printf 'Type=Application\n'
    printf 'Name=WFHelper\n'
    printf 'Comment=Warframe companion\n'
    printf 'Exec="%s"\n' "$exec_path"
    printf 'TryExec="%s"\n' "$exec_path"
    printf 'Icon=applications-games\n'
    printf 'Terminal=false\n'
    printf 'Categories=Game;Utility;\n'
    printf 'StartupNotify=true\n'
} > "$desktop_temporary"
chmod 0644 "$desktop_temporary"
mv -f -- "$desktop_temporary" "$desktop_path"
printf '[DONE] Downloaded executable: %s\n' "$app_path"
printf '[DONE] Application-menu shortcut: %s\n' "$desktop_path"
printf 'Launch WFHelper from your application menu. To extract it manually, run:\n  cd %s && ./WFHelper-2.1.1.AppImage --appimage-extract\n' "$app_dir"
