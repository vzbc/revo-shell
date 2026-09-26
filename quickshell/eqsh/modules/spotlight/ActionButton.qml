import Quickshell
import QtQuick
import qs
import qs.config
import qs.ui.controls.advanced
import qs.ui.controls.auxiliary
import qs.ui.controls.providers
import qs.ui.controls.primitives
import qs.ui.controls.windows

import "Rail.js" as Rail

Item {
    id: root

    required property bool actionsShown
    required property bool launcherVisible
    required property string textColor
    required property string glassColor

    property real railProgress: 0
    property real collapsedWidth: 600
    property real topOffset: 200
    property real expandedWidth: root.collapsedWidth - 4 * (root.circleD + root.circleGap)

    signal hoveredAction(string action)
    signal selectedAction(string action)

    property int position: 0
    property int iconSize: 32
    property string action: "applications"

    readonly property real circleD: 58
    readonly property real circleGap: 10
    readonly property real mainLeft: parent ? (parent.width / 2 - root.collapsedWidth / 2) : 0
    readonly property real expandedRight: root.mainLeft + root.expandedWidth
    readonly property real growth: Rail.growth(root.railProgress, root.position)
    readonly property real travel: Rail.travel(root.railProgress, root.position)
    readonly property real emerge: root.circleD * 0.3 * (Rail.growth(root.railProgress, 0) - 1)
    readonly property real firstCenter: root.expandedRight + root.circleGap + root.circleD / 2 + root.emerge
    readonly property real centerX: root.firstCenter + root.position * (root.circleD + root.circleGap) * root.travel
    property real positionX: root.centerX - root.circleD / 2

    z: 100
    visible: root.railProgress > 0.001
    anchors {
        left: parent.left
        leftMargin: root.positionX
        top: parent.top
        topMargin: root.topOffset
    }
    width: root.circleD
    height: root.circleD
    scale: root.growth
    opacity: Rail.iconAlpha(root.railProgress, root.position)

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: circleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
        border.color: circleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : "transparent"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    CFVI {
        anchors.centerIn: parent
        icon: `spotlight/${root.action}.svg`
        size: root.iconSize
        color: root.textColor
    }

    MouseArea {
        id: circleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hoveredAction(root.actionsShown && root.launcherVisible ? root.action : "")
        onExited: root.hoveredAction("")
        onClicked: root.selectedAction(root.action)
    }
}
