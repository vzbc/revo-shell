import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style search field (rounded, with magnifier icon).
 */
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    signal accepted()

    implicitHeight: 34
    implicitWidth: 240
    color: mouse.containsMouse ? "#333333" : "#2d2d2d"
    radius: 17
    border.color: input.activeFocus ? WinTheme.accent : "#3d3d3d"
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    HoverHandler {
        id: mouse
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 8

        MaterialSymbol {
            text: "search"
            iconSize: 16
            color: WinTheme.textSecondary
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            color: WinTheme.text
            clip: true
            selectByMouse: true
            font.pixelSize: 13
            selectionColor: WinTheme.accentDark
            onAccepted: root.accepted()

            Text {
                anchors.fill: parent
                visible: parent.text.length === 0
                text: root.placeholder
                color: WinTheme.textTertiary
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 13
            }
        }

        MaterialSymbol {
            visible: input.text.length > 0
            text: "close"
            iconSize: 14
            color: WinTheme.textSecondary
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: input.text = ""
            }
        }
    }
}
