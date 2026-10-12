
#!/bin/bash
set -e

python - <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import sys

target = Path.home() / ".config/quickshell/caelestia"
details = target / "modules/dashboard/media/Details.qml"

if not details.is_file():
    sys.exit(f"ERROR: File not found: {details}")

text = details.read_text()

if "property string selectedPreset" in text:
    sys.exit("Preset code already exists. No changes made.")

if "import QtQuick.Layouts" not in text or not text.rstrip().endswith("}"):
    sys.exit("Unexpected QML structure. No changes made.")

backup = details.with_name(
    f"Details.qml.bak-{datetime.now():%Y%m%d-%H%M%S}"
)
shutil.copy2(details, backup)

text = text.replace(
    "import QtQuick.Layouts\n",
    "import QtQuick.Layouts\nimport Quickshell.Io\n",
    1
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
    1
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
details.write_text(text)

print("Added EasyEffects preset buttons.")
print(f"Backup saved to: {backup}")
print(f"Updated: {details}")
PY
