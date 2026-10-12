
#!/usr/bin/env bash

set -u

printf '\n=== Arch Linux Update Check ===\n\n'

# Official Arch repository packages
if command -v checkupdates >/dev/null 2>&1; then
    echo "--- Official repository updates ---"
    if updates=$(checkupdates 2>&1); then
        printf '%s\n' "$updates"
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
if command -v yay >/dev/null 2>&1; then
    echo "--- AUR updates (yay) ---"
    aur_updates=$(yay -Qua 2>&1)
    status=$?

    if [ -z "$aur_updates" ]; then
        echo "No AUR updates available."
    elif [ "$status" -ne 0 ]; then
        printf '%s\n' "$aur_updates"
        echo "AUR check failed (exit code: $status)."
    else
        printf '%s\n' "$aur_updates"
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
else
    echo "Flatpak is not installed; skipping check."
fi
