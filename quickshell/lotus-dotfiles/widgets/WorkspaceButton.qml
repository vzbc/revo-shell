import QtQuick

FocusScope {
    id: root

    required property QtObject theme
    required property int workspaceId
    property bool active: false
    property bool occupied: false
    property bool urgent: false
    property int windowCount: 0

    signal clicked()

    implicitWidth: 26
    implicitHeight: 30
    activeFocusOnTab: true
    scale: tap.pressed ? root.theme.pressScale : 1
    Accessible.role: Accessible.Button
    Accessible.name: "Workspace " + workspaceId + (active ? ", active" : "") + (windowCount > 0 ? ", " + windowCount + (windowCount === 1 ? " window" : " windows") : ", empty")
    Keys.onEnterPressed: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusControl
        color: root.active ? root.theme.green : (root.urgent ? root.theme.coral : (hover.hovered ? root.theme.alpha(root.theme.peach, 0.55) : "transparent"))
        border.width: root.active || root.urgent || root.activeFocus ? 1 : 0
        border.color: root.activeFocus ? root.theme.focus : root.theme.ink

        Text {
            anchors.centerIn: parent
            visible: root.active || root.occupied || hover.hovered || root.activeFocus
            text: String(root.workspaceId)
            color: root.theme.ink
            font.family: root.theme.fontFamily
            font.pixelSize: root.workspaceId === 10 ? 9 : root.theme.textXs
            font.weight: root.active ? Font.Bold : Font.DemiBold
        }

        Rectangle {
            anchors.centerIn: parent
            visible: !root.active && !root.occupied && !hover.hovered && !root.activeFocus
            width: 5
            height: 5
            radius: 3
            color: root.theme.outlineSoft
        }

        Rectangle {
            visible: root.urgent
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 3
            anchors.topMargin: 3
            width: 5
            height: 5
            radius: 3
            color: root.theme.surfaceRaised
            border.width: 1
            border.color: root.theme.ink
        }

        HoverHandler {
            id: hover
        }

        TapHandler {
            id: tap

            onTapped: root.clicked()
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: root.theme.motionFast
            easing.type: root.theme.easingStandard
        }

    }

}
