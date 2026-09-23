import QtQuick

FocusScope {
    id: root

    required property QtObject theme
    required property url iconSource
    required property string accessibleName
    property color fill: "transparent"
    property color hoverOverlay: theme.alpha(theme.ink, 0.07)
    property string badgeText: ""
    property bool raised: false
    property int controlSize: theme.compactControlSize
    readonly property int buttonShadowOffset: raised ? theme.space1 : 0

    signal clicked()

    implicitWidth: controlSize + buttonShadowOffset
    implicitHeight: controlSize + buttonShadowOffset
    opacity: enabled ? 1 : 0.42
    activeFocusOnTab: enabled
    scale: tap.pressed ? theme.pressScale : 1
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
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
        visible: root.raised
        x: root.buttonShadowOffset
        y: root.buttonShadowOffset
        width: root.controlSize
        height: root.controlSize
        radius: root.theme.radiusControl
        color: root.theme.shadow
    }

    Rectangle {
        id: face

        width: root.controlSize
        height: root.controlSize
        radius: root.theme.radiusControl
        color: root.fill
        border.width: root.activeFocus ? root.theme.borderWidth : (root.raised ? root.theme.borderWidth : 0)
        border.color: root.activeFocus ? root.theme.focus : root.theme.ink

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.hoverOverlay
            opacity: hover.hovered && root.enabled ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.theme.motionFast
                    easing.type: root.theme.easingStandard
                }

            }

        }

        Image {
            anchors.centerIn: parent
            width: root.theme.iconSm
            height: root.theme.iconSm
            source: root.iconSource
            sourceSize.width: root.theme.iconSm
            sourceSize.height: root.theme.iconSm
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }

        Rectangle {
            visible: root.badgeText.length > 0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -4
            anchors.rightMargin: -4
            width: Math.max(16, badgeLabel.implicitWidth + 6)
            height: 16
            radius: 8
            color: root.theme.ink
            border.width: 1
            border.color: root.theme.surfaceRaised

            Text {
                id: badgeLabel

                anchors.centerIn: parent
                text: root.badgeText
                color: root.theme.surfaceRaised
                font.family: root.theme.fontFamily
                font.pixelSize: 8
                font.weight: Font.Bold
            }

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
