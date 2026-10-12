#!/usr/bin/env bash
set -euo pipefail

mode="plan"
case "${1:-}" in
    "") ;;
    --apply) mode="apply" ;;
    --help|-h) printf 'Usage: %s [--apply]\nPreview by default; --apply reviews, backs up, and adds the Caelestia preset buttons.\n' "${0##*/}"; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
if [[ "$mode" == apply && ! -t 0 ]]; then
    printf 'ERROR: --apply needs an interactive terminal for review.\n' >&2
    exit 1
fi
MODE="$mode" python - <<'PY'
from datetime import datetime
from difflib import unified_diff
from pathlib import Path
import os
import shutil
import sys

mode = os.environ["MODE"]
target = Path.home() / ".config/quickshell/caelestia"
details = target / "modules/dashboard/media/Details.qml"
if not details.is_file():
    sys.exit(f"ERROR: File not found: {details}")
parent = details.parent
while parent != Path.home() and parent != Path("/"):
    if parent.is_symlink():
        sys.exit(f"ERROR: Refusing to write through symlink directory: {parent}")
    parent = parent.parent
if details.is_symlink():
    sys.exit(f"ERROR: Refusing to replace symlink: {details}")
original = details.read_text()
if "property string selectedPreset" in original:
    sys.exit("Preset buttons already exist. No changes made.")
if "import QtQuick.Layouts" not in original or "    id: root\n" not in original or not original.rstrip().endswith("}"):
    sys.exit("Unexpected QML structure. No changes made.")
text = original
if "import Quickshell.Io" not in text:
    text = text.replace(
        "import QtQuick.Layouts\n",
        "import QtQuick.Layouts\nimport Quickshell.Io\n",
        1,
    )
text = text.replace(
    "    id: root\n",
    '''    id: root

    property string selectedPreset: "Flat"

    Process {
        id: presetProcess
        command: ["easyeffects", "--load-preset", "Flat"]
    }
''',
    1,
)
buttons = '''
    StyledText {
        Layout.topMargin: Tokens.spacing.large
        text: "EQUALIZER PRESET"
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.medium
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Tokens.spacing.extraSmall
        columnSpacing: Tokens.spacing.extraSmall

        Repeater {
            model: ["Flat", "Rock", "Jazz", "Pop", "Bass Boost"]

            delegate: Rectangle {
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 10

                color: root.selectedPreset === modelData
                    ? Colours.palette.m3primaryContainer : "transparent"
                border.width: 1
                border.color: root.selectedPreset === modelData
                    ? Colours.palette.m3primary : Colours.palette.m3outline

                StyledText {
                    anchors.fill: parent
                    text: modelData
                    color: root.selectedPreset === modelData
                        ? Colours.palette.m3onPrimaryContainer
                        : Colours.palette.m3onSurface
                    font: Tokens.font.label.medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedPreset = modelData
                        presetProcess.command = [
                            "easyeffects", "--load-preset", modelData
                        ]
                        presetProcess.running = true
                    }
                }
            }
        }
    }
'''
text = text.rstrip()[:-1] + buttons + "\n}\n"
diff = "".join(unified_diff(original.splitlines(True), text.splitlines(True), fromfile="current/Details.qml", tofile="repo/Details.qml"))
print(diff)
backup = details.with_name(f"Details.qml.bak-{datetime.now():%Y%m%d-%H%M%S}-{os.getpid()}")
print(f"Backup will be saved to: {backup}")
if mode == "plan":
    print("Preview only. Run scripts/easyeffects-presets.sh --apply to review and apply.")
    sys.exit(0)
answer = input("Apply this Caelestia dashboard change? [y/N] ").strip().lower()
if answer not in {"y", "yes"}:
    print("Cancelled. No files changed.")
    sys.exit(0)
shutil.copy2(details, backup)
details.write_text(text)
print(f"Backup saved to: {backup}")
print(f"Updated: {details}")
PY
