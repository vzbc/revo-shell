import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    anchors.fill: parent
    spacing: 16

    Text {
        text: "ON-SCREEN KEYBOARD"
        color: Config.textMain
        font.family: Config.sysFont
        font.pixelSize: Config.size(Config.fontSubhead)
        font.bold: true
    }

    // TOGGLE ROW
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: "Enable Keyboard Overlay"
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontBody)
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "Show a virtual on-screen keyboard overlay"
                color: Config.textMuted
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontCaption)
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            implicitWidth: 44; implicitHeight: 24; radius: 12
            color: (Config.showOsk !== false) ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: (Config.showOsk !== false) ? 22 : 2
                implicitWidth: 20; implicitHeight: 20; radius: 10
                color: (Config.showOsk !== false) ? Config.bgBase : Qt.rgba(255, 255, 255, 0.8)
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Config.showOsk = (Config.showOsk === false)
                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                    else if (typeof Config.save === "function") Config.save()
                }
            }
        }
    }

    // LAYOUT SELECTION BUTTONS
    Text {
        text: "KEYBOARD LAYOUT"
        color: Config.textMuted
        font.family: Config.sysFont
        font.pixelSize: Config.size(Config.fontCaption)
        font.bold: true
        Layout.topMargin: 6
    }

    RowLayout {
        spacing: 8

        Repeater {
            model: [
                { name: "Normal",  icon: "keyboard" },
                { name: "Minimal", icon: "keyboard_keys" },
                { name: "Gamer",   icon: "sports_esports" }
            ]

            delegate: Rectangle {
                id: layoutBtn
                implicitWidth: 130
                implicitHeight: 36
                radius: Config.cornerRadius / 2

                readonly property bool isCurrent: Config.oskLayout === modelData.name
                color: layoutBtn.isCurrent ? Qt.rgba(255, 255, 255, 0.12) : (btnHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03))
                border.width: layoutBtn.isCurrent ? 1 : 0
                border.color: Config.accent

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: modelData.icon
                        color: layoutBtn.isCurrent ? Config.accent : Config.textMuted
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 16
                    }

                    Text {
                        text: modelData.name
                        color: layoutBtn.isCurrent ? Config.accent : Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: layoutBtn.isCurrent
                        elide: Text.ElideRight
                    }
                }

                TapHandler {
                    onTapped: Config.oskLayout = modelData.name
                }
                HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    Item { Layout.fillHeight: true }
}