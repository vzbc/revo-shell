import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
    property real value: 0.0

    Layout.fillWidth: true
    implicitHeight: Math.round(4 * UIScale.value)
    radius: Math.round(2 * UIScale.value)
    color: Colors.surfaceHigh

    Rectangle {
        width: parent.width * value
        height: parent.height
        radius: parent.radius
        color: value > 0.9 ? Qt.rgba(1, 0.35, 0.2, 1) : Colors.accent
        Behavior on width {
            NumberAnimation {
                duration: Anim.fast
                easing.type: Easing.OutQuad
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }
}
