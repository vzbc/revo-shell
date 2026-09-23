import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property string label
    required property url iconSource
    property bool selected: false

    signal clicked()

    implicitHeight: 42
    activeFocusOnTab: enabled
    scale: tap.pressed ? theme.pressScale : 1
    Accessible.role: Accessible.Button
    Accessible.name: label + (selected ? ". Current device" : ". Select device")
    Keys.onEnterPressed: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusControl
        color: root.selected ? root.theme.alpha(root.theme.green, 0.66) : (hover.hovered ? root.theme.alpha(root.theme.peach, 0.24) : root.theme.surfaceRaised)
        border.width: root.theme.borderWidth
        border.color: root.activeFocus ? root.theme.focus : root.theme.ink

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.theme.space3
            anchors.rightMargin: root.theme.space3
            spacing: root.theme.space2

            Image {
                Layout.preferredWidth: root.theme.iconSm
                Layout.preferredHeight: root.theme.iconSm
                source: root.iconSource
                sourceSize.width: root.theme.iconSm
                sourceSize.height: root.theme.iconSm
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            Text {
                Layout.fillWidth: true
                text: root.label
                color: root.theme.ink
                elide: Text.ElideRight
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textXs
                font.weight: root.selected ? Font.Bold : Font.Medium
            }

            Rectangle {
                visible: root.selected
                Layout.preferredWidth: 46
                Layout.preferredHeight: 20
                radius: root.theme.radiusPill
                color: root.theme.surfaceRaised
                border.width: 1
                border.color: root.theme.ink

                Text {
                    anchors.centerIn: parent
                    text: "ACTIVE"
                    color: root.theme.ink
                    font.family: root.theme.fontFamily
                    font.pixelSize: 7
                    font.weight: Font.Bold
                }

            }

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
