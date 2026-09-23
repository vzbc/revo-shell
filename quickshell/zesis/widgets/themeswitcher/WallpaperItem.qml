pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../"

Item {
    id: root

    required property string wallpaperPath

    readonly property bool selected: ThemeState.lastWallpaper === wallpaperPath
    readonly property string _baseName: wallpaperPath.substring(wallpaperPath.lastIndexOf("/") + 1)
    readonly property string _displayName: _baseName.replace(/\.[^.]+$/, "")
    readonly property string _ext: _baseName.includes(".") ? _baseName.split(".").pop().toUpperCase() : ""
    readonly property string _thumbPath: ThemeState.thumbsDir + "/" + _baseName + ".jpg"

    implicitHeight: Math.round(84 * UIScale.value)

    Rectangle {
        anchors.fill: parent
        radius: UIScale.radiusSm
        color: root.selected ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) : hoverArea.containsMouse ? Colors.surfaceHigh : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: UIScale.spacingSm
        spacing: Math.round(12 * UIScale.value)

        // Thumbnail
        Rectangle {
            implicitWidth: Math.round(120 * UIScale.value)
            implicitHeight: Math.round(68 * UIScale.value)
            radius: UIScale.radiusSm
            color: Colors.surface
            clip: true

            Image {
                id: thumb
                anchors.fill: parent
                source: "file://" + root._thumbPath
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 240
                sourceSize.height: 136
                asynchronous: true

                onStatusChanged: {
                    if (status === Image.Error && !thumbGen.running) {
                        thumbGen.running = true;
                    }
                }
            }

            // Loading placeholder
            Rectangle {
                anchors.fill: parent
                radius: UIScale.radiusSm
                color: Colors.surface
                visible: thumb.status !== Image.Ready

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.round(28 * UIScale.value)
                    height: Math.round(28 * UIScale.value)
                    radius: Math.round(14 * UIScale.value)
                    color: Colors.surfaceHigh
                }
            }
        }

        // Info column
        Column {
            Layout.fillWidth: true
            spacing: Math.round(4 * UIScale.value)

            Text {
                text: root._displayName
                color: Colors.text
                font.pixelSize: UIScale.fontSmall
                font.weight: Font.Medium
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root._ext
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
            }
        }

        // Selected dot
        Rectangle {
            implicitWidth: Math.round(8 * UIScale.value)
            implicitHeight: Math.round(8 * UIScale.value)
            radius: Math.round(4 * UIScale.value)
            color: Colors.accent
            opacity: root.selected ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.medium
                }
            }
        }
    }

    // Applying overlay
    Rectangle {
        anchors.fill: parent
        radius: UIScale.radiusSm
        color: Qt.rgba(0, 0, 0, 0.4)
        visible: ThemeState.applying && root.selected

        Text {
            anchors.centerIn: parent
            text: I18n.t("wallpaper.applying")
            color: Colors.text
            font.pixelSize: UIScale.fontCaption
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ThemeState.apply(root.wallpaperPath)
    }

    Process {
        id: thumbGen
        command: ["magick", root.wallpaperPath, "-resize", "240x136^", "-gravity", "Center", "-extent", "240x136", root._thumbPath]
        onExited: (code, status) => {
            if (code === 0) {
                thumb.source = "";
                thumb.source = "file://" + root._thumbPath;
            } else {
                // Fallback: load full image scaled by Qt
                thumb.source = "file://" + root.wallpaperPath;
            }
        }
    }
}
