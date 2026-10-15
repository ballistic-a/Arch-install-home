
#!/usr/bin/env bash

set -u

download_updates=0
update_system=0
case "${1:-}" in
    "") ;;
    --download|-d) download_updates=1 ;;
    --update|-u) update_system=1 ;;
    --help|-h)
        printf 'Usage: %s [--download | --update]\n' "${0##*/}"
        printf 'Check Arch, AUR, and Flatpak updates. --download caches Arch and Flatpak updates without installing them.\n'
        printf '%s\n' '--update installs Arch/AUR updates and then updates Flatpak applications.'
        exit 0
        ;;
    *)
        printf 'Unknown option: %s\nUsage: %s [--download | --update]\n' "$1" "${0##*/}" >&2
        exit 2
        ;;
esac

if [ "$update_system" -eq 1 ]; then
    printf '\n=== Arch Linux System Update ===\n\n'
    update_failed=0

    if command -v yay >/dev/null 2>&1; then
        echo "--- Updating Arch repository and AUR packages (yay) ---"
        if ! yay -Syu; then
            echo "Arch/AUR update failed."
            update_failed=1
        fi
    else
        echo "--- Updating Arch repository packages (pacman) ---"
        if ! sudo pacman -Syu; then
            echo "Arch update failed."
            update_failed=1
        fi
        echo "yay is not installed; AUR updates were skipped."
    fi

    if command -v flatpak >/dev/null 2>&1; then
        echo
        echo "--- Updating Flatpak applications ---"
        if ! flatpak update; then
            echo "Flatpak update failed."
            update_failed=1
        fi
    fi

    if [ "$update_failed" -ne 0 ]; then
        exit 1
    fi
    echo
    echo "System update finished."
    exit 0
fi

printf '\n=== Arch Linux Update Check ===\n\n'

# Official Arch repository packages
if command -v checkupdates >/dev/null 2>&1; then
    echo "--- Official repository updates ---"
    checkupdates_args=()
    if [ "$download_updates" -eq 1 ]; then
        checkupdates_args+=(--download)
    fi

    if updates=$(checkupdates "${checkupdates_args[@]}" 2>&1); then
        printf '%s\n' "$updates"
        if [ "$download_updates" -eq 1 ]; then
            echo "Official package updates downloaded to the pacman cache."
        fi
    else
        status=$?
        if [ "$status" -eq 2 ]; then
            echo "System is up to date."
        else
            printf '%s\n' "$updates"
            echo "Could not complete repository check."
        fi
    fi
else
    echo "Missing checkupdates. Install pacman-contrib:"
    echo "sudo pacman -S pacman-contrib"
fi

echo

# AUR packages
aur_updates_found=0
if command -v yay >/dev/null 2>&1; then
    echo "--- AUR updates (yay) ---"
    aur_updates=$(yay -Qua 2>&1)
    status=$?

    if [ "$status" -ne 0 ]; then
        printf '%s\n' "$aur_updates"
        echo "AUR check failed (exit code: $status)."
    elif [ -z "$aur_updates" ]; then
        echo "No AUR updates available."
    else
        printf '%s\n' "$aur_updates"
        aur_updates_found=1
    fi
else
    echo "yay is not installed; skipping AUR check."
fi

# Flatpak applications
if command -v flatpak >/dev/null 2>&1; then
    echo "--- Flatpak updates ---"

    flatpak_updates=$(flatpak remote-ls --updates 2>&1)
    status=$?

    if [ "$status" -ne 0 ]; then
        printf '%s\n' "$flatpak_updates"
        echo "Flatpak check failed (exit code: $status)."
    elif [ -z "$flatpak_updates" ]; then
        echo "No Flatpak updates available."
    else
        printf '%s\n' "$flatpak_updates"
    fi

    if [ "$download_updates" -eq 1 ] && [ "$status" -eq 0 ] && [ -n "$flatpak_updates" ]; then
        echo "Downloading Flatpak updates without installing them..."
        if ! flatpak update --no-deploy --assumeyes; then
            echo "Flatpak download failed."
        fi
    fi
else
    echo "Flatpak is not installed; skipping check."
fi

if [ "$download_updates" -eq 1 ] && [ "$aur_updates_found" -eq 1 ]; then
    echo "AUR updates need to be built from source; they were not downloaded by this option."
    echo "Use yay to review and build AUR updates when you are ready."
fi

echo
echo "Hint: run this script with --update to install available updates."
