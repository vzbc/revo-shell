import QtQuick

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
            height: 5
            radius: 2.5
            color: Theme.sliderTrack
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: handle.x + handle.width / 2
            height: 5
            radius: 2.5
            color: Theme.accent
        }

        Rectangle {
            id: handle
            width: 16
            height: 16
            radius: 8
            color: "white"
            border.width: 1
            border.color: Theme.controlBorder
            anchors.verticalCenter: parent.verticalCenter
            x: slider.ratio() * (track.width - width)
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
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
        font.family: "SF Pro Text"
        font.pixelSize: 12
        color: Theme.btnText
    }

    Text {
        visible: slider.maxLabel.length > 0
        anchors.top: track.bottom
        anchors.right: parent.right
        text: slider.maxLabel
        font.family: "SF Pro Text"
        font.pixelSize: 12
        color: Theme.btnText
    }
}
