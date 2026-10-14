import Quickshell
import Quickshell.Wayland
import QtCore
import QtQuick
import Qt.labs.folderlistmodel

PanelWindow {
    id: root

    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property real uiScale: Math.max(0.7, Math.min(1.25, Screen.height / 1080))
    property real wheelRemainder: 0

    Settings {
        id: savedSettings
        category: "wallpaper-selector"
        property string lastWallpaperPath: ""
    }

    implicitWidth: Screen.width
    implicitHeight: Screen.height
    color: "transparent"
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function applyCurrent() {
        if (wallpapers.count < 1 || gallery.currentIndex < 0) return
        const path = wallpapers.get(gallery.currentIndex, "filePath")
        savedSettings.lastWallpaperPath = path
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path])
        Qt.quit()
    }

    function restoreCurrent() {
        if (wallpapers.count < 1) return

        for (let i = 0; i < wallpapers.count; i++) {
            if (wallpapers.get(i, "filePath") === savedSettings.lastWallpaperPath) {
                gallery.currentIndex = i
                return
            }
        }

        if (gallery.currentIndex < 0 || gallery.currentIndex >= wallpapers.count)
            gallery.currentIndex = Math.floor(wallpapers.count / 2)
    }

    function scrollByWheel(event): void {
        const angle = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
        const pixels = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.pixelDelta.x
        const delta = angle !== 0 ? angle / 120 : pixels / 32
        wheelRemainder += delta

        const steps = Math.trunc(wheelRemainder)
        if (steps !== 0 && gallery.count > 0) {
            gallery.currentIndex = Math.max(0, Math.min(gallery.count - 1,
                gallery.currentIndex - steps))
            wheelRemainder -= steps
        }
        event.accepted = true
    }

    FolderListModel {
        id: wallpapers
        folder: "file://" + root.wallpaperDir
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        sortField: FolderListModel.Name
        onCountChanged: root.restoreCurrent()
    }

    Item {
        id: overlay
        anchors.fill: parent

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.scrollByWheel(event)
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
            // Scrolling is handled by WheelHandler below so wheel input cannot
            // move contentX independently from currentIndex and snap back.
            interactive: false
            currentIndex: -1
            leftMargin: Math.max(0, (width - 300 * root.uiScale) / 2)
            rightMargin: leftMargin
            snapMode: ListView.NoSnap
            highlightRangeMode: ListView.NoHighlightRange
            highlightMoveDuration: 0

            Behavior on contentX {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < count)
                    positionViewAtIndex(currentIndex, ListView.Center)
            }

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

        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: wallpapers.count > 0 ? (gallery.currentIndex + 1) + " / " + wallpapers.count : ""
            color: "#8d93a2"
            font.pixelSize: 13 * root.uiScale
        }
    }
    }
}
