pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../"

Column {
    id: battBar

    property string label: ""
    property int level: 0
    property bool charging: false
    property bool dim: false

    width: parent.width
    spacing: Math.round(2 * UIScale.value)

    RowLayout {
        width: parent.width

        Text {
            text: battBar.label
            color: Colors.textDim
            opacity: battBar.dim ? 0.4 : 1.0
            font.pixelSize: UIScale.fontTiny
            font.weight: Font.Medium
            Layout.fillWidth: true
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
        }

        Text {
            text: (battBar.charging ? "󱐋 " : "") + battBar.level + "%"
            color: battBar.charging ? Colors.accent : Colors.text
            font.pixelSize: UIScale.fontTiny
            font.weight: Font.DemiBold
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: Math.round(3 * UIScale.value)
        radius: 2
        color: Colors.surfaceHigh

        Rectangle {
            width: parent.width * (battBar.level / 100)
            height: parent.height
            radius: parent.radius
            color: battBar.charging ? Colors.accent : (battBar.level <= 15 ? "#e05c5c" : battBar.level <= 30 ? "#e0a85c" : Colors.accent)
            Behavior on width {
                NumberAnimation {
                    duration: Anim.slow
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }
    }
}
