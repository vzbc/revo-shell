import QtQuick
import QtQuick.Controls
import "../../"

// Info tooltip, it reveals a description in a popup on hover
Item {
    id: root

    property string text: ""

    readonly property real _maxTextWidth: Math.round(230 * UIScale.value)

    implicitWidth: Math.round(16 * UIScale.value)
    implicitHeight: implicitWidth

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: hoverHandler.hovered ? Colors.withAlpha(Colors.text, 0.14) : Colors.withAlpha(Colors.text, 0.08)
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "Material Icons"
            font.pixelSize: Math.round(11 * UIScale.value)
            color: Colors.textDim
        }
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TextMetrics {
        id: unwrappedMetrics
        text: root.text
        font.pixelSize: UIScale.fontCaption
    }

    ToolTip {
        visible: hoverHandler.hovered && root.text.length > 0
        delay: 250
        x: root.width / 2 - implicitWidth / 2
        y: -implicitHeight - UIScale.spacingXs
        padding: UIScale.spacingSm

        contentItem: Text {
            text: root.text
            color: Colors.text
            font.pixelSize: UIScale.fontCaption
            wrapMode: Text.WordWrap
            width: Math.min(unwrappedMetrics.width, root._maxTextWidth)
        }

        background: Rectangle {
            radius: UIScale.radiusSm
            color: Colors.bg
            border.color: Colors.outline
            border.width: 1
        }
    }
}
