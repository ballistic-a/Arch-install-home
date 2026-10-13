#!/usr/bin/env python3
"""Create Swedish holiday data for Caelestia and send next-day reminders."""
from __future__ import annotations

import argparse
import json
import subprocess
from datetime import date, datetime, timedelta
from pathlib import Path

HOME = Path.home()
DATA = HOME / ".local/state/caelestia/swedish-holidays.json"
NOTIFIED = HOME / ".local/state/arch-install-home/swedish-holidays-notified.json"


def easter(year: int) -> date:
    a = year % 19
    b, c = divmod(year, 100)
    d, e = divmod(b, 4)
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = divmod(c, 4)
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    day = (h + l - 7 * m + 114) % 31 + 1
    return date(year, month, day)


def first_weekday_on_or_after(day: date, weekday: int) -> date:
    return day + timedelta(days=(weekday - day.weekday()) % 7)


def holidays_for(year: int) -> list[tuple[date, str, str, bool]]:
    easter_day = easter(year)
    midsummer = first_weekday_on_or_after(date(year, 6, 20), 5)
    all_saints = first_weekday_on_or_after(date(year, 10, 31), 5)
    entries = [
        (date(year, 1, 1), "Nyårsdagen", "public", True),
        (date(year, 1, 6), "Trettondedag jul", "public", True),
        (easter_day - timedelta(days=3), "Skärtorsdagen", "observance", False),
        (easter_day - timedelta(days=2), "Långfredagen", "public", True),
        (easter_day - timedelta(days=1), "Påskafton", "customary_off", True),
        (easter_day, "Påskdagen", "public", True),
        (easter_day + timedelta(days=1), "Annandag påsk", "public", True),
        (date(year, 4, 30), "Valborgsmässoafton", "observance", False),
        (date(year, 5, 1), "Första maj", "public", True),
        (easter_day + timedelta(days=39), "Kristi himmelsfärdsdag", "public", True),
        (easter_day + timedelta(days=48), "Pingstafton", "customary_off", True),
        (easter_day + timedelta(days=49), "Pingstdagen", "public", True),
        (date(year, 6, 6), "Sveriges nationaldag", "public", True),
        (midsummer - timedelta(days=1), "Midsommarafton", "customary_off", True),
        (midsummer, "Midsommardagen", "public", True),
        (all_saints, "Alla helgons dag", "public", True),
        (date(year, 12, 24), "Julafton", "customary_off", True),
        (date(year, 12, 25), "Juldagen", "public", True),
        (date(year, 12, 26), "Annandag jul", "public", True),
        (date(year, 12, 31), "Nyårsafton", "customary_off", True),
    ]
    return entries


def build_data() -> dict[str, list[dict[str, object]]]:
    today = date.today()
    result: dict[str, list[dict[str, object]]] = {}
    for year in range(today.year - 2, today.year + 21):
        for day, name, kind, work_free in holidays_for(year):
            result.setdefault(day.isoformat(), []).append(
                {"name": name, "kind": kind, "workFree": work_free}
            )
    return result


def save_data() -> None:
    DATA.parent.mkdir(parents=True, exist_ok=True)
    DATA.write_text(json.dumps(build_data(), ensure_ascii=False, indent=2) + "\n")


def notify_tomorrow() -> None:
    save_data()
    tomorrow = date.today() + timedelta(days=1)
    events = build_data().get(tomorrow.isoformat(), [])
    if not events:
        return
    NOTIFIED.parent.mkdir(parents=True, exist_ok=True)
    try:
        state = json.loads(NOTIFIED.read_text())
    except (OSError, json.JSONDecodeError):
        state = {}
    if state.get("date") == tomorrow.isoformat():
        return
    names = ", ".join(event["name"] for event in events)
    day_off = any(event["workFree"] for event in events)
    detail = "Tomorrow is commonly work-free." if day_off else "Tomorrow is an observance."
    subprocess.run([
        "notify-send", "Swedish holiday tomorrow", f"{names}\n{detail}",
        "--app-name=Caelestia", "--icon=calendar",
    ], check=False)
    NOTIFIED.write_text(json.dumps({"date": tomorrow.isoformat()}, indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--notify", action="store_true", help="refresh data and notify about tomorrow")
    args = parser.parse_args()
    if args.notify:
        notify_tomorrow()
    else:
        save_data()


if __name__ == "__main__":
    main()
