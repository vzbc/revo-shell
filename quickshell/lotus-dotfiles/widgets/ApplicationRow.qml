import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

FocusScope {
    id: root

    required property QtObject theme
    required property var application
    property bool selected: false

    signal activated()
    signal hovered()

    implicitHeight: theme.launcherRowHeight
    scale: tap.pressed ? theme.pressScale : 1
    Accessible.role: Accessible.Button
    Accessible.name: application.name + (application.genericName.length > 0 ? ". " + application.genericName : "")

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusControl
        color: root.selected ? root.theme.alpha(root.theme.green, 0.62) : (hoverHandler.hovered ? root.theme.alpha(root.theme.peach, 0.3) : "transparent")
        border.width: root.selected ? root.theme.borderWidth : 0
        border.color: root.theme.ink

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.theme.space3
            anchors.rightMargin: root.theme.space3
            spacing: root.theme.space3

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: root.theme.radiusControl
                color: root.theme.surfaceRaised
                border.width: 1
                border.color: root.theme.ink

                IconImage {
                    anchors.centerIn: parent
                    width: root.theme.iconLg
                    height: root.theme.iconLg
                    source: root.application.icon.length > 0 && Quickshell.hasThemeIcon(root.application.icon) ? Quickshell.iconPath(root.application.icon) : "file://" + Quickshell.shellDir + "/assets/icons/application.svg"
                    asynchronous: true
                    mipmap: true
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.application.name
                    color: root.theme.ink
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textSm
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    text: root.application.genericName.length > 0 ? root.application.genericName : root.application.comment
                    visible: text.length > 0
                    color: root.theme.inkMuted
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textXs
                }

            }

            Rectangle {
                visible: root.application.runInTerminal
                Layout.preferredWidth: 28
                Layout.preferredHeight: 24
                radius: root.theme.radiusPill
                color: root.theme.alpha(root.theme.blue, 0.62)
                border.width: 1
                border.color: root.theme.ink

                Image {
                    anchors.centerIn: parent
                    width: root.theme.iconSm
                    height: root.theme.iconSm
                    source: Quickshell.shellDir + "/assets/icons/terminal.svg"
                    sourceSize.width: root.theme.iconSm
                    sourceSize.height: root.theme.iconSm
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

            }

        }

        HoverHandler {
            id: hoverHandler

            onHoveredChanged: {
                if (hovered)
                    root.hovered();

            }
        }

        TapHandler {
            id: tap

            onTapped: root.activated()
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: root.theme.motionFast
            easing.type: root.theme.easingStandard
        }

    }

}
