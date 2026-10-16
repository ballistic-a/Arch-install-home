#!/usr/bin/env bash

set -euo pipefail

mode="plan"
case "${1:-}" in
    "") ;;
    --apply) mode="apply" ;;
    --help|-h)
        printf 'Usage: %s [--apply]\nPreview by default; --apply reviews, backs up, and updates the Caelestia Dashboard and calendar.\n' "${0##*/}"
        exit 0
        ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac

if [[ -z "${HOME:-}" || "$HOME" == "/" || "${EUID:-1}" -eq 0 ]]; then
    printf 'ERROR: Run this as your regular user with a valid HOME.\n' >&2
    exit 1
fi
if [[ "$mode" == "apply" && ! -t 0 ]]; then
    printf 'ERROR: --apply needs an interactive terminal so the proposed QML changes can be reviewed.\n' >&2
    exit 1
fi

MODE="$mode" python3 - <<'PY'
from datetime import datetime
from difflib import unified_diff
from pathlib import Path
import os
import shutil
import sys

mode = os.environ["MODE"]
home = Path.home()
relative_targets = (Path("Dash.qml"), Path("dash/Calendar.qml"))
user_base = home / ".config/quickshell/caelestia/modules/dashboard"
system_base = Path("/etc/xdg/quickshell/caelestia/modules/dashboard")

# Prefer an existing user override. Otherwise support the system-wide layout
# used by the Arch caelestia-shell package.
if all((user_base / relative).is_file() for relative in relative_targets):
    base = user_base
    system_install = False
elif all((system_base / relative).is_file() for relative in relative_targets):
    base = system_base
    system_install = True
else:
    base = user_base
    system_install = False

targets = {relative: base / relative for relative in relative_targets}

def symlink_path(path: Path):
    if path.is_symlink():
        return path
    parent = path.parent
    while parent != home and parent != Path("/"):
        if parent.is_symlink():
            return parent
        parent = parent.parent
    return None

def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        sys.exit(f"ERROR: Caelestia {label} has an unexpected layout; no files were changed.")
    return text.replace(old, new, 1)

def transform_dash(text: str) -> str:
    resource_block = '''    Rect {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        Resources {
            id: resources
        }
    }

'''
    if resource_block in text:
        text = text.replace(resource_block, "", 1)
    elif "Resources {" in text or "resources.implicitWidth" in text:
        sys.exit("ERROR: Dashboard resource panel differs from the expected Caelestia layout; no files were changed.")

    old_span = '''        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: calendar.implicitHeight'''
    new_span = old_span.replace("Layout.columnSpan: 3", "Layout.columnSpan: 4")
    if new_span not in text:
        text = replace_once(text, old_span, new_span, "Dashboard calendar layout")
    return text

def transform_calendar(text: str) -> str:
    text = replace_once(text, "import QtQuick.Controls\n", "import QtQuick.Controls\nimport Quickshell.Io\n", "calendar holiday file support")
    text = replace_once(text, "import qs.services\n", "import qs.services\nimport qs.utils\n", "calendar holiday paths")
    holiday_data = '''    property var holidayData: ({})

    function dateKey(value: date): string {
        return `${value.getFullYear()}-${String(value.getMonth() + 1).padStart(2, "0")}-${String(value.getDate()).padStart(2, "0")}`;
    }

    FileView {
        path: `${Paths.state}/swedish-holidays.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.holidayData = JSON.parse(text());
            } catch (error) {
                console.warn("Unable to read Swedish holiday calendar:", error);
                root.holidayData = {};
            }
        }
    }

'''
    # Caelestia 2.5.0 does not define `ready` in the upstream file;
    # insert holiday loading after the stable animOpacity property instead.
    text = replace_once(
        text,
        "    property real animOpacity: 1\n",
        "    property real animOpacity: 1\n" + holiday_data,
        "calendar holiday data",
    )
    text = replace_once(
        text,
        "    property date currentDate: screenState.dashboardDate\n",
        "    property date currentDate: new Date()\n    property bool ready: false\n",
        "calendar date state",
    )
    text = replace_once(
        text,
        "    readonly property int nonAnimCurrMonth: screenState.dashboardDate.getMonth()\n    readonly property int nonAnimCurrYear: screenState.dashboardDate.getFullYear()\n",
        "    readonly property int nonAnimCurrMonth: currentDate.getMonth()\n    readonly property int nonAnimCurrYear: currentDate.getFullYear()\n",
        "calendar month navigation",
    )

    selected_property = '''                    readonly property bool selected: model.date.getFullYear() === root.screenState.dashboardDate.getFullYear()
                        && model.date.getMonth() === root.screenState.dashboardDate.getMonth()
                        && model.date.getDate() === root.screenState.dashboardDate.getDate()
'''
    model_line = "                    required property var model\n"
    if selected_property not in text:
        text = replace_once(text, model_line, model_line + selected_property, "calendar selected date")
    holiday_properties = '''                    readonly property var holidays: root.holidayData[root.dateKey(model.date)] ?? []
                    readonly property bool workFree: holidays.some(holiday => holiday.workFree)
'''
    if holiday_properties not in text:
        text = replace_once(text, selected_property, selected_property + holiday_properties, "calendar holiday markers")

    selection_background = '''                    Rectangle {
                        anchors.centerIn: parent
                        width: text.implicitWidth + Tokens.padding.small * 2
                        height: text.implicitHeight + Tokens.padding.small * 2
                        radius: height / 2
                        color: dayItem.selected && !dayItem.model.today ? Colours.palette.m3secondaryContainer : "transparent"
                    }

'''
    height_line = "                    implicitHeight: text.implicitHeight + Tokens.padding.small\n"
    if selection_background not in text:
        text = replace_once(text, height_line, height_line + "\n" + selection_background, "calendar selected-date style")

    holiday_marker = '''                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        width: 4
                        height: 4
                        radius: 2
                        visible: dayItem.holidays.length > 0
                        color: dayItem.workFree ? Colours.palette.m3secondary : Colours.palette.m3tertiary
                    }

                    HoverHandler {
                        id: holidayHover
                    }

                    ToolTip.visible: holidayHover.hovered && dayItem.holidays.length > 0
                    ToolTip.text: dayItem.holidays.map(holiday => `${holiday.name}${holiday.workFree ? " · commonly work-free" : " · observance"}`).join("\\n")
                    ToolTip.delay: 400

'''
    if holiday_marker not in text:
        text = replace_once(text, "                    TapHandler {\n", holiday_marker + "                    TapHandler {\n", "calendar holiday tooltips")

    if "                            if (dayItem.selected && !dayItem.model.today)" not in text:
        text = replace_once(
            text,
            "                        color: {\n",
            "                        color: {\n                            if (dayItem.selected && !dayItem.model.today)\n                                return Colours.palette.m3onSecondaryContainer;\n\n",
            "calendar selected-date text",
        )

    init_and_helper = '''    Component.onCompleted: {
        currentDate = new Date(screenState.dashboardDate.getFullYear(), screenState.dashboardDate.getMonth(), 1);
        ready = true;
    }

    function setDate(value: date): void {
        const monthChanged = value.getMonth() !== currentDate.getMonth() || value.getFullYear() !== currentDate.getFullYear();
        screenState.dashboardDate = value;
        if (monthChanged)
            currentDate = new Date(value.getFullYear(), value.getMonth(), 1);
    }

'''
    if init_and_helper not in text:
        text = replace_once(text, "    property real animOpacity: 1\n\n", "    property real animOpacity: 1\n\n" + init_and_helper, "calendar date selection")

    text = replace_once(
        text,
        "            screenState.dashboardDate = new Date(nonAnimCurrYear, nonAnimCurrMonth - 1, 1);",
        "            setDate(new Date(nonAnimCurrYear, nonAnimCurrMonth - 1, 1));",
        "calendar previous-month navigation",
    )
    text = replace_once(
        text,
        "            screenState.dashboardDate = new Date(nonAnimCurrYear, nonAnimCurrMonth + 1, 1);",
        "            setDate(new Date(nonAnimCurrYear, nonAnimCurrMonth + 1, 1));",
        "calendar next-month navigation",
    )
    text = replace_once(
        text,
        "\n    onClicked: root.screenState.dashboardDate = new Date()",
        "\n    onClicked: root.setDate(new Date())",
        "calendar today reset",
    )
    text = replace_once(
        text,
        "\n                    onClicked: root.screenState.dashboardDate = new Date()",
        "\n                    onClicked: root.setDate(new Date())",
        "calendar today button",
    )
    text = replace_once(
        text,
        "                onClicked: root.screenState.dashboardDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth - 1, 1)",
        "                onClicked: root.setDate(new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth - 1, 1))",
        "calendar previous-month button",
    )
    text = replace_once(
        text,
        "                onClicked: root.screenState.dashboardDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth + 1, 1)",
        "                onClicked: root.setDate(new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth + 1, 1))",
        "calendar next-month button",
    )
    text = replace_once(
        text,
        "                        onTapped: root.screenState.dashboardDate = dayItem.model.date",
        "                        onTapped: root.setDate(dayItem.model.date)",
        "calendar day selection",
    )

    behavior = "    Behavior on currentDate {\n"
    if "    Behavior on currentDate {\n        enabled: root.ready\n" not in text:
        text = replace_once(text, behavior, behavior + "        enabled: root.ready\n\n", "calendar month animation")

    today_indicator = "                readonly property Item todayItem: grid.contentItem.children.find(c => c.model.today) ?? null\n"
    selected_indicator = '''                readonly property Item todayItem: grid.contentItem.children.find(c => {
                    const date = root.screenState.dashboardDate;
                    return c.model.date.getFullYear() === date.getFullYear()
                        && c.model.date.getMonth() === date.getMonth()
                        && c.model.date.getDate() === date.getDate();
                }) ?? null
'''
    if selected_indicator in text:
        text = text.replace(selected_indicator, today_indicator, 1)
    elif today_indicator not in text:
        sys.exit("ERROR: Caelestia today highlight differs from the expected calendar layout; no files were changed.")
    return text

proposed = {}
originals = {}
for relative, destination in targets.items():
    link = symlink_path(destination)
    if link is not None:
        print(f"[SKIP] Caelestia path contains a symlink ({link}); no files changed.")
        sys.exit(0)

missing = [path for path in targets.values() if not path.is_file()]
if len(missing) == len(targets):
    print("[SKIP] Caelestia Dashboard files were not found in either the user config or /etc/xdg; install Caelestia before applying this optional patch.")
    sys.exit(0)
if missing:
    sys.exit(f"ERROR: Expected Caelestia file is missing: {missing[0]}\nNo files were changed.")

for relative, destination in targets.items():
    originals[relative] = destination.read_text()

proposed[Path("Dash.qml")] = transform_dash(originals[Path("Dash.qml")])
proposed[Path("dash/Calendar.qml")] = transform_calendar(originals[Path("dash/Calendar.qml")])
changed = [path for path in targets if proposed[path] != originals[path]]
if not changed:
    print("[SAME] Dashboard resource strip, expanded calendar, date selection, and today's highlight are already installed.")
    sys.exit(0)

for relative in changed:
    print(f"\n--- Proposed change for {targets[relative]} ---")
    print("".join(unified_diff(
        originals[relative].splitlines(True),
        proposed[relative].splitlines(True),
        fromfile=f"current/{relative}",
        tofile=f"repository/{relative}",
    )), end="")

backup_suffix = "quickshell/caelestia/modules/dashboard"
if system_install:
    backup_suffix = "etc/xdg/quickshell/caelestia/modules/dashboard"
backup_root = home / ".config-backups/arch-install-home" / f"{datetime.now():%Y-%m-%d_%H-%M-%S}-{os.getpid()}" / backup_suffix
print(f"\nBackups will be saved under: {backup_root}")
if system_install:
    print("System package files will be updated using sudo and may be replaced by a future Caelestia package update.")
if mode == "plan":
    print("Preview only. Run install.sh --apply or scripts/install-caelestia-dashboard.sh --apply to review and apply.")
    sys.exit(0)

answer = input("Apply these Caelestia Dashboard and calendar changes? [y/N] ").strip().lower()
if answer not in {"y", "yes"}:
    print("Cancelled. No files changed.")
    sys.exit(0)

for relative in changed:
    destination = targets[relative]
    backup = backup_root / relative
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(destination, backup)

    if system_install:
        # Stage the reviewed file in the user's backup directory, then use
        # sudo install rather than changing ownership or permissions in /etc.
        temporary = backup.parent / (destination.name + f".new-{os.getpid()}")
        temporary.write_text(proposed[relative])
        shutil.copystat(destination, temporary)
        try:
            import subprocess
            subprocess.run(
                ["sudo", "install", "-o", "root", "-g", "root", "-m", "0644", str(temporary), str(destination)],
                check=True,
            )
        finally:
            temporary.unlink(missing_ok=True)
    else:
        temporary = destination.with_name(destination.name + f".tmp-{os.getpid()}")
        temporary.write_text(proposed[relative])
        shutil.copystat(destination, temporary)
        temporary.replace(destination)

    print(f"[BACKUP] {backup}")
    print(f"[DONE] {destination}")
PY
