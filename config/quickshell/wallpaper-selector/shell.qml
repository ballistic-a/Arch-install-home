import Quickshell
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel

PanelWindow {
    id: root

    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property real uiScale: Math.max(0.7, Math.min(1.25, Screen.height / 1080))

    implicitWidth: Screen.width
    implicitHeight: Screen.height
    color: "transparent"
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function applyCurrent() {
        if (wallpapers.count < 1 || gallery.currentIndex < 0) return
        const path = wallpapers.get(gallery.currentIndex, "filePath")
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path])
        Qt.quit()
    }

    FolderListModel {
        id: wallpapers
        folder: "file://" + root.wallpaperDir
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        sortField: FolderListModel.Name
    }

    Rectangle {
        anchors.fill: parent
        color: "#bf080b12"

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 24 * root.uiScale

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Choose a wallpaper"
            color: "#f5f5f7"
            font.pixelSize: 30 * root.uiScale
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: wallpapers.count > 0
                  ? "← / → or scroll to browse   ·   Enter or click to apply   ·   Esc to close"
                  : "Add images to  " + root.wallpaperDir
            color: "#bdc1ca"
            font.pixelSize: 14 * root.uiScale
        }

        ListView {
            id: gallery
            width: parent.width
            height: 350 * root.uiScale
            orientation: ListView.Horizontal
            model: wallpapers
            spacing: 18 * root.uiScale
            clip: true
            focus: true
            currentIndex: Math.max(0, Math.floor(count / 2))
            leftMargin: Math.max(0, (width - 300 * root.uiScale) / 2)
            rightMargin: leftMargin
            snapMode: ListView.SnapToItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - 150 * root.uiScale
            preferredHighlightEnd: width / 2 + 150 * root.uiScale

            delegate: Item {
                id: tile
                required property int index
                required property string fileName
                required property string filePath
                property bool selected: ListView.isCurrentItem

                width: 300 * root.uiScale
                height: gallery.height
                scale: selected ? 1 : 0.78
                opacity: selected ? 1 : 0.58
                Behavior on scale { NumberAnimation { duration: 180 } }
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 8 * root.uiScale
                    radius: 16 * root.uiScale
                    color: "#20232c"
                    border.width: tile.selected ? 3 : 1
                    border.color: tile.selected ? "#d5bcff" : "#454957"
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5 * root.uiScale
                        source: "file://" + filePath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: gallery.currentIndex = index
                    onClicked: {
                        gallery.currentIndex = index
                        root.applyCurrent()
                    }
                }
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Left) {
                    currentIndex = Math.max(0, currentIndex - 1)
                } else if (event.key === Qt.Key_Right) {
                    currentIndex = Math.min(count - 1, currentIndex + 1)
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.applyCurrent()
                } else if (event.key === Qt.Key_Escape) {
                    Qt.quit()
                } else {
                    return
                }
                event.accepted = true
            }

            WheelHandler {
                onWheel: event => {
                    gallery.currentIndex = Math.max(0, Math.min(gallery.count - 1,
                        gallery.currentIndex + (event.angleDelta.y < 0 ? 1 : -1)))
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: wallpapers.count > 0 ? (gallery.currentIndex + 1) + " / " + wallpapers.count : ""
            color: "#8d93a2"
            font.pixelSize: 13 * root.uiScale
        }
    }
}
