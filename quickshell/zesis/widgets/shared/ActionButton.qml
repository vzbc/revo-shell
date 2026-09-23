import QtQuick
import "../../"

// Small accent-tinted pill button. Auto-sizes to its label (with a floor
// matching the original fixed-size button this was extracted from), so it
// also works for longer labels like "Re-scatter (new random)".
Item {
    id: root
    signal activated

    property string label: ""
    property bool ghost: false

    readonly property real _minWidth: Math.round(58 * UIScale.value)
    implicitWidth: Math.max(_minWidth, labelText.implicitWidth + UIScale.spacingMd * 2)
    implicitHeight: Math.round(32 * UIScale.value)
    opacity: root.enabled ? 1.0 : 0.4
    Behavior on opacity {
        NumberAnimation {
            duration: Anim.fast
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: UIScale.radiusSm
        color: root.ghost ? (hoverHandler.hovered ? Colors.withAlpha(Colors.text, 0.08) : "transparent") : (hoverHandler.hovered ? Colors.withAlpha(Colors.accent, 0.28) : Colors.withAlpha(Colors.accent, 0.14))
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }

        Text {
            id: labelText
            anchors.centerIn: parent
            text: root.label
            color: root.ghost ? Colors.muted : Colors.accent
            font.pixelSize: UIScale.fontSmall
            font.weight: Font.DemiBold
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.enabled
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
