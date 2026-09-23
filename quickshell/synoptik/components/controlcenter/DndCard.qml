import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."

Rectangle {
    id: root

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.alignment: Qt.AlignTop
    implicitHeight: 64
    radius: Config.cornerRadius

    color: cardHover.hovered ? Qt.rgba(Config.bgBase.r, Config.bgBase.g, Config.bgBase.b, 1.0) : Qt.rgba(0, 0, 0, 0.25)
    Behavior on color { ColorAnimation { duration: 150 } }

    // Bind directly to your root NotificationServer instance
    property bool dndActive: notifServer.dnd

    TapHandler {
        onTapped: root.toggleDnd()
    }

    HoverHandler {
        id: cardHover
        cursorShape: Qt.PointingHandCursor
    }

    function toggleDnd() {
        notifServer.dnd = !notifServer.dnd
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Rectangle {
            implicitWidth: 44
            implicitHeight: 44
            radius: Config.cornerRadius / 2
            color: root.dndActive ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: root.dndActive ? "notifications_off" : "notifications"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 22
                color: root.dndActive ? Config.bgBase : Config.textMuted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: "Do Not Disturb"
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontCaption)
                font.bold: true
                color: Config.textMain
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.dndActive ? "On" : "Off"
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontMicro)
                color: Config.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}