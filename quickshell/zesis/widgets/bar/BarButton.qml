import QtQuick
import "../../"

Item {
    // Unconditional, never gate on visible here. See docs/qml-patterns.md #1
    implicitWidth: Math.round(30 * UIScale.value)
    implicitHeight: Math.round(30 * UIScale.value)

    property string icon: ""
    property bool active: false
    signal clicked

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }

    Text {
        anchors.centerIn: parent
        text: parent.icon
        font.pixelSize: Math.round(15 * UIScale.value)
        color: (mouseArea.containsMouse || active) ? Colors.accent : Colors.text
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }
}
