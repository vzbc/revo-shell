import QtQuick
import QtQuick.Effects

// macOS 27 switch: capsule track, pill-shaped glass knob that stretches
// while pressed (Liquid Glass "squish") and slides with a spring.
Item {
    id: toggle

    property bool checked: false
    property bool enabled2: true
    signal toggled(bool checked)

    width: 40
    height: 24
    opacity: enabled2 ? 1 : 0.45

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: toggle.checked ? Theme.accent : Theme.toggleOff

        Behavior on color {
            ColorAnimation { duration: 160 }
        }

        // inner shade on the track rim
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: toggle.checked ? Qt.rgba(0, 0, 0, 0.08) : (Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05))
        }
    }

    RectangularShadow {
        anchors.fill: knob
        radius: knob.radius
        blur: 4
        offset.y: 1
        color: Theme.knobShadow
    }

    Rectangle {
        id: knob
        readonly property real restW: 24
        readonly property real pressW: 28
        width: area.pressed ? pressW : restW
        height: 20
        radius: height / 2
        color: Theme.knob
        anchors.verticalCenter: parent.verticalCenter
        x: toggle.checked ? toggle.width - width - 2 : 2

        // glass highlight on the upper half of the knob
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1.5
            height: parent.height / 2
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.9) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
            }
        }

        Behavior on x {
            SpringAnimation { spring: 5; damping: 0.38; epsilon: 0.25 }
        }
        Behavior on width {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        enabled: toggle.enabled2
        onClicked: toggle.toggled(!toggle.checked)
    }
}
