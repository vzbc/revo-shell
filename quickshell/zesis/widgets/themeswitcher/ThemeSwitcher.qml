pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../"
import "../bar"
import "../shared"

Item {
    id: root
    focus: true

    Component.onCompleted: scanner.running = true
    Connections {
        target: ThemeState // qmllint disable incompatible-type
        function onWallpapersDirChanged() {
            scanner.running = true;
        }
    }

    ListModel {
        id: wallpapers
    }

    Process {
        id: scanner
        command: ["bash", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort > \"$2\"", "--", ThemeState.wallpapersDir, Quickshell.env("HOME") + "/.cache/zesis/wallpapers.txt"]
        stdout: StdioCollector {}
        onExited: () => listReader.reload()
    }

    FileView {
        id: listReader
        path: Quickshell.env("HOME") + "/.cache/zesis/wallpapers.txt"
        onLoaded: {
            var lines = text().split("\n");
            wallpapers.clear();
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line !== "")
                    wallpapers.append({
                        path: line
                    });
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: UIScale.radiusLg
        topLeftRadius: (BarConfig.side === "top" || BarConfig.side === "left") ? 0 : UIScale.radiusLg
        topRightRadius: (BarConfig.side === "top" || BarConfig.side === "right") ? 0 : UIScale.radiusLg
        bottomLeftRadius: (BarConfig.side === "bottom" || BarConfig.side === "left") ? 0 : UIScale.radiusLg
        bottomRightRadius: (BarConfig.side === "bottom" || BarConfig.side === "right") ? 0 : UIScale.radiusLg
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(16 * UIScale.value)
        spacing: Math.round(12 * UIScale.value)

        // Header row
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: I18n.t("wallpaper.popupTitle")
                color: Colors.text
                font.pixelSize: Math.round(16 * UIScale.value)
                font.weight: Font.DemiBold
            }

            Item {
                Layout.fillWidth: true
            }

            // Dark / Light pill toggle
            Rectangle {
                Layout.preferredWidth: Math.round(120 * UIScale.value)
                Layout.preferredHeight: Math.round(32 * UIScale.value)
                radius: Math.round(16 * UIScale.value)
                color: Colors.surface

                Rectangle {
                    id: pillSlider
                    width: Math.round(56 * UIScale.value)
                    height: Math.round(26 * UIScale.value)
                    radius: Math.round(13 * UIScale.value)
                    anchors.verticalCenter: parent.verticalCenter
                    x: ThemeState.palette === "dark" ? Math.round(3 * UIScale.value) : Math.round(61 * UIScale.value)
                    color: Colors.accent
                    Behavior on x {
                        NumberAnimation {
                            duration: Anim.medium
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("wallpaper.dark")
                        color: ThemeState.palette === "dark" ? Colors.bg : Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.medium
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("wallpaper.light")
                        color: ThemeState.palette === "light" ? Colors.bg : Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.medium
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ThemeState.togglePalette()
                }
            }
        }

        // Search bar
        StyledTextInput {
            id: searchField
            Layout.fillWidth: true
            showClearButton: true
            placeholder: I18n.t("wallpaper.searchPlaceholder")
        }

        // Wallpaper list
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(4 * UIScale.value)
            clip: true
            model: wallpapers

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            WheelHandler {
                onWheel: event => {
                    listView.contentY = Math.max(listView.originY, Math.min(listView.originY + listView.contentHeight - listView.height, listView.contentY - event.angleDelta.y * 0.5));
                }
            }

            delegate: WallpaperItem {
                required property string path
                wallpaperPath: path
                width: listView.width - Math.round(8 * UIScale.value)
                visible: searchField.text === "" || path.toLowerCase().includes(searchField.text.toLowerCase())
                height: visible ? implicitHeight : 0
            }

            Text {
                anchors.centerIn: parent
                visible: wallpapers.count === 0 && !scanner.running
                text: I18n.t("wallpaper.noneFoundIn", [ThemeState.wallpapersDir])
                color: Colors.textDim
                font.pixelSize: UIScale.fontSmall
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 9999
        propagateComposedEvents: true
        onPressed: mouse => {
            root.forceActiveFocus();
            mouse.accepted = false;
        }
    }
}
