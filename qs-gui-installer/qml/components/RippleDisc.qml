// RippleDisc.qml — one expanding ripple circle
import QtQuick

Rectangle {
    id: disc

    property color color: "#ADD8E6"
    property real maxDiameter: 340

    width: 8
    height: 8
    radius: width / 2
    opacity: 0.5
    color: parent && parent.parent ? parent.color : "#ADD8E6"

    ParallelAnimation {
        running: true
        NumberAnimation { target: disc; property: "width"; to: disc.maxDiameter; duration: 620; easing.type: Easing.OutCubic }
        NumberAnimation { target: disc; property: "height"; to: disc.maxDiameter; duration: 620; easing.type: Easing.OutCubic }
        NumberAnimation { target: disc; property: "opacity"; to: 0; duration: 620 }
    }
}
