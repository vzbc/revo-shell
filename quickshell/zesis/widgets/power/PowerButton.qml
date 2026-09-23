import QtQuick
import "../../"

// Single icon-over-label card used by PowerMenu.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool armed: false
    signal activated

    readonly property real _size: Math.round(88 * UIScale.value)
    implicitWidth: _size
    implicitHeight: _size + UIScale.spacingSm + labelText.implicitHeight

    Rectangle {
        id: circle
        width: root._size
        height: root._size
        radius: width / 2
        color: root.armed ? Colors.withAlpha(Colors.accent, 0.22) : (hoverHandler.hovered ? Colors.surfaceHigh : Colors.surface)
        border.color: root.armed ? Colors.accent : Colors.outline
        border.width: root.armed ? 2 : 1
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Anim.fast
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.pixelSize: Math.round(30 * UIScale.value)
            color: root.armed ? Colors.accent : Colors.text
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }

        scale: mouseArea.pressed ? 0.95 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: Anim.micro
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: hoverHandler
        }
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activated()
        }
    }

    Text {
        id: labelText
        anchors.top: circle.bottom
        anchors.topMargin: UIScale.spacingSm
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.armed ? "Confirm?" : root.label
        color: root.armed ? Colors.accent : Colors.text
        font.pixelSize: UIScale.fontLead
        font.weight: Font.Medium
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }
}
