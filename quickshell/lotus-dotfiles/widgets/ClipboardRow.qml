import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property var entry
    property bool selected: false

    signal activated()
    signal deleteRequested()
    signal hovered()

    implicitHeight: theme.clipboardRowHeight
    activeFocusOnTab: true
    scale: tap.pressed ? theme.pressScale : 1
    Accessible.role: Accessible.Button
    Accessible.name: entry.preview + (selected ? ". Selected" : "")
    Keys.onEnterPressed: root.activated()
    Keys.onReturnPressed: root.activated()
    Keys.onSpacePressed: root.activated()
    Keys.onDeletePressed: root.deleteRequested()

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusControl
        color: root.selected ? root.theme.alpha(root.theme.green, 0.62) : (hoverHandler.hovered ? root.theme.alpha(root.theme.peach, 0.24) : root.theme.surfaceRaised)
        border.width: root.theme.borderWidth
        border.color: root.activeFocus ? root.theme.focus : root.theme.ink

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.theme.space2
            spacing: root.theme.space3

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: root.theme.radiusControl
                color: root.entry.binary ? root.theme.lilac : root.theme.peach
                border.width: 1
                border.color: root.theme.ink

                Image {
                    anchors.centerIn: parent
                    width: root.theme.iconSm
                    height: root.theme.iconSm
                    source: Quickshell.shellDir + "/assets/icons/" + (root.entry.binary ? "image.svg" : "clipboard.svg")
                    sourceSize.width: root.theme.iconSm
                    sourceSize.height: root.theme.iconSm
                }

            }

            Text {
                Layout.fillWidth: true
                text: root.entry.preview
                color: root.theme.ink
                elide: Text.ElideRight
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textSm
                font.weight: root.selected ? Font.Bold : Font.Medium
            }

            Ui.IconButton {
                theme: root.theme
                controlSize: 30
                iconSource: Quickshell.shellDir + "/assets/icons/trash.svg"
                accessibleName: "Delete this clipboard entry"
                fill: root.theme.surfaceMuted
                onClicked: root.deleteRequested()
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

            acceptedButtons: Qt.LeftButton
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
