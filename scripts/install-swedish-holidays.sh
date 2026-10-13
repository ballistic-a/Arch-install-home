#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:-plan}"
if [[ "$mode" != "plan" && "$mode" != "--apply" ]]; then
    printf 'Usage: %s [--apply]\n' "${0##*/}" >&2
    exit 2
fi
if [[ -z "${HOME:-}" || "$HOME" == / || "${EUID:-1}" -eq 0 ]]; then
    printf 'ERROR: Run this as a regular user with a valid HOME.\n' >&2
    exit 1
fi
if [[ "$mode" == --apply && ! -t 0 ]]; then
    printf 'ERROR: --apply needs an interactive terminal to review the setup.\n' >&2
    exit 1
fi

data="$HOME/.local/state/caelestia/swedish-holidays.json"
program="$HOME/.local/share/arch-install-home/swedish-holidays.py"
service="$HOME/.config/systemd/user/arch-install-home-swedish-holidays.service"
timer="$HOME/.config/systemd/user/arch-install-home-swedish-holidays.timer"
printf 'Swedish holiday calendar and reminder plan:\n'
printf '  Holiday date data: %s\n' "$data"
printf '  Daily 18:00 reminder check: %s\n' "$timer"
printf '  Includes public holidays, commonly work-free eves, and observances.\n'
printf '  Requires notify-send (libnotify) for desktop reminders.\n'
if [[ "$mode" == plan ]]; then
    printf 'Preview only. The apply step backs up existing targets before replacing them.\n'
    exit 0
fi
read -r -p 'Install holiday markers and enable the daily reminder? [y/N] ' answer
if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    printf 'Cancelled. No files changed.\n'
    exit 0
fi

timestamp="$(date '+%Y-%m-%d_%H-%M-%S')-$$"
backup_root="$HOME/.config-backups/arch-install-home/$timestamp"
mkdir -p "$backup_root"
for target in "$data" "$program" "$service" "$timer"; do
    parent="$(dirname -- "$target")"
    current="$parent"
    while [[ "$current" != "$HOME" && "$current" != / ]]; do
        if [[ -L "$current" ]]; then
            printf '[SKIP] Symlink parent: %s\n' "$current"
            exit 1
        fi
        current="$(dirname -- "$current")"
    done
    if [[ -L "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
        printf '[SKIP] Unsafe existing destination: %s\n' "$target"
        exit 1
    fi
done

for target in "$data" "$program" "$service" "$timer"; do
    if [[ -f "$target" ]]; then
        relative="${target#"$HOME/"}"
        mkdir -p "$backup_root/$(dirname -- "$relative")"
        cp -a -- "$target" "$backup_root/$relative"
        printf '[BACKUP] %s\n' "$backup_root/$relative"
    fi
done

install -D -m 0644 "$repo_dir/scripts/swedish-holidays.py" "$program"
python3 "$program"
mkdir -p "$HOME/.config/systemd/user"
cat > "$service" <<EOF
[Unit]
Description=Refresh Swedish holiday calendar and send the next-day reminder

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 %h/.local/share/arch-install-home/swedish-holidays.py --notify
EOF
cat > "$timer" <<'EOF'
[Unit]
Description=Check for a Swedish holiday reminder each evening

[Timer]
OnCalendar=*-*-* 18:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now arch-install-home-swedish-holidays.timer
printf '[DONE] Holiday date data and daily reminder timer installed.\n'
printf 'Existing targets, if any, were backed up to %s.\n' "$backup_root"
