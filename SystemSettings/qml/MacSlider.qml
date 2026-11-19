import QtQuick
import QtQuick.Effects

Item {
    id: slider

    property real from: 0
    property real to: 1
    property real value: 0.5
    property string minLabel: ""
    property string maxLabel: ""
    signal moved(real value)

    height: minLabel.length || maxLabel.length ? 38 : 22

    function ratio() {
        if (to === from)
            return 0
        return (value - from) / (to - from)
    }

    function apply(px) {
        var r = Math.max(0, Math.min(1, px / track.width))
        value = from + r * (to - from)
        moved(value)
    }

    Item {
        id: track
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 22

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.sliderTrack
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(6, handle.x + handle.width / 2)
            height: 6
            radius: 3
            color: Theme.accent
        }

        RectangularShadow {
            anchors.fill: handle
            radius: handle.radius
            blur: 5
            offset.y: 1
            color: Theme.knobShadow
        }

        // pill-shaped glass knob (Tahoe); widens while dragging
        Rectangle {
            id: handle
            width: dragArea.pressed ? 28 : 22
            height: 16
            radius: 8
            color: Theme.knob
            anchors.verticalCenter: parent.verticalCenter
            x: slider.ratio() * (track.width - width)
            Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

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
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            onPressed: (mouse) => slider.apply(mouse.x)
            onPositionChanged: (mouse) => {
                if (pressed)
                    slider.apply(mouse.x)
            }
        }
    }

    Text {
        visible: slider.minLabel.length > 0
        anchors.top: track.bottom
        anchors.left: parent.left
        text: slider.minLabel
        font.family: Theme.fontText
        font.pixelSize: 11
        color: Theme.textSecondary
    }

    Text {
        visible: slider.maxLabel.length > 0
        anchors.top: track.bottom
        anchors.right: parent.right
        text: slider.maxLabel
        font.family: Theme.fontText
        font.pixelSize: 11
        color: Theme.textSecondary
    }
}
