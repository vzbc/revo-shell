import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    required property QtObject theme
    required property QtObject trayService
    required property QtObject trayController
    required property var screen
    required property var parentWindow
    readonly property int inlineLimit: 4
    readonly property var inlineItems: trayService.inlineItems(inlineLimit)
    readonly property int overflowCount: Math.max(0, trayService.count - inlineLimit)

    signal openingRequested()

    function toggleOverflow() {
        if (!trayController.isOpen(screen.name))
            openingRequested();

        trayController.toggle(screen.name);
    }

    visible: trayService.count > 0
    implicitWidth: visible ? trayRow.implicitWidth + theme.space2 : 0
    implicitHeight: visible ? theme.compactControlSize : 0
    radius: theme.radiusControl
    color: theme.surfaceRaised
    border.width: theme.borderWidth
    border.color: theme.ink

    RowLayout {
        id: trayRow

        anchors.centerIn: parent
        spacing: 0

        Repeater {

            model: ScriptModel {
                values: root.inlineItems
            }

            delegate: TrayItemButton {
                required property var modelData

                theme: root.theme
                trayService: root.trayService
                trayItem: modelData
                parentWindow: root.parentWindow
                controlSize: root.theme.compactControlSize - 4
            }

        }

        FocusScope {
            visible: root.overflowCount > 0
            Layout.preferredWidth: visible ? root.theme.compactControlSize - 2 : 0
            Layout.preferredHeight: root.theme.compactControlSize - 4
            activeFocusOnTab: visible
            Accessible.role: Accessible.Button
            Accessible.name: root.overflowCount + " more tray items"
            Keys.onEnterPressed: root.toggleOverflow()
            Keys.onReturnPressed: root.toggleOverflow()
            Keys.onSpacePressed: root.toggleOverflow()

            Rectangle {
                anchors.fill: parent
                radius: root.theme.radiusControl
                color: root.trayController.isOpen(root.screen.name) ? root.theme.lilac : (overflowPointer.containsMouse ? root.theme.alpha(root.theme.lilac, 0.55) : "transparent")
                border.width: parent.activeFocus ? root.theme.borderWidth : 0
                border.color: parent.activeFocus ? root.theme.focus : root.theme.ink

                Text {
                    anchors.centerIn: parent
                    text: "+" + root.overflowCount
                    color: root.theme.ink
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textXs
                    font.weight: Font.Bold
                }

            }

            MouseArea {
                id: overflowPointer

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.toggleOverflow()
            }

        }

    }

}
