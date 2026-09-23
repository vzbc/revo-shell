import QtQuick

FocusScope {
    id: root

    required property QtObject theme
    property string label: "Button"
    property color fill: theme.peach
    property color foreground: theme.ink

    signal clicked()

    implicitWidth: Math.max(96, labelText.implicitWidth + theme.space8) + theme.shadowOffset
    implicitHeight: theme.controlHeight + theme.shadowOffset
    opacity: enabled ? 1 : 0.55
    activeFocusOnTab: enabled
    scale: tap.pressed ? theme.pressScale : 1
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onEnterPressed: {
        if (root.enabled)
            root.clicked();

    }
    Keys.onReturnPressed: {
        if (root.enabled)
            root.clicked();

    }
    Keys.onSpacePressed: {
        if (root.enabled)
            root.clicked();

    }

    Rectangle {
        x: root.theme.shadowOffset
        y: root.theme.shadowOffset
        width: root.width - root.theme.shadowOffset
        height: root.height - root.theme.shadowOffset
        radius: root.theme.radiusControl
        color: root.theme.shadow
    }

    Rectangle {
        id: face

        width: root.width - root.theme.shadowOffset
        height: root.height - root.theme.shadowOffset
        radius: root.theme.radiusControl
        color: root.enabled ? root.fill : root.theme.disabledFill
        border.width: root.theme.borderWidth
        border.color: root.activeFocus ? root.theme.focus : root.theme.ink

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.theme.borderWidth + 1
            radius: Math.max(0, parent.radius - root.theme.borderWidth - 1)
            color: hover.hovered && root.enabled ? root.theme.alpha(root.theme.ink, 0.06) : "transparent"
        }

        Text {
            id: labelText

            anchors.centerIn: parent
            text: root.label
            color: root.enabled ? root.foreground : root.theme.disabledInk
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.textSm
            font.weight: Font.DemiBold
        }

        HoverHandler {
            id: hover
        }

        TapHandler {
            id: tap

            enabled: root.enabled
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
