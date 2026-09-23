import QtQuick
import "Appearance.qml"

Item {
    id: root

    property real value: 0.5
    property real min: 0
    property real max: 1
    property color color: Appearance.fg
    property bool active: true

    signal changed()

    implicitHeight: 26
    implicitWidth: 220

    readonly property real frac: root.max > root.min ? (root.value - root.min) / (root.max - root.min) : 0

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: Qt.rgba(255, 255, 255, 0.18)

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, Math.min(1, root.frac)) * parent.width
            height: parent.height
            radius: 2
            color: root.color
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }

    Rectangle {
        id: thumb
        y: (parent.height - root.thumbSize) / 2
        x: Math.max(0, Math.min(1, root.frac)) * (parent.width - root.thumbSize)
        width: root.thumbSize
        height: root.thumbSize
        radius: root.thumbSize / 2
        color: "#ffffff"
        border.color: Qt.rgba(0, 0, 0, 0.12)
        border.width: 1
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    property real thumbSize: 14

    MouseArea {
        anchors.fill: parent
        enabled: root.active
        onPressed: (mouse) => root.setFromMouse(mouse.x)
        onPositionChanged: (mouse) => {
            if (pressed) root.setFromMouse(mouse.x);
        }
    }

    function setFromMouse(x) {
        const f = Math.max(0, Math.min(1, x / root.width));
        root.value = root.min + (root.max - root.min) * f;
        root.changed();
    }
}
