import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

Ui.RaisedSurface {
    id: root

    required property QtObject clockService
    required property QtObject audioService
    required property QtObject networkService
    required property QtObject bluetoothService
    required property QtObject notificationService
    property bool panelOpen: false
    property bool audioStudioOpen: false
    property bool notificationCenterOpen: false

    signal panelToggleRequested()
    signal audioStudioToggleRequested()
    signal notificationToggleRequested()

    implicitWidth: contentRow.implicitWidth + padding * 2 + theme.shadowOffset
    implicitHeight: theme.sideIslandHeight
    padding: theme.space2
    fill: theme.surface
    surfaceRadius: theme.radiusCard

    RowLayout {
        id: contentRow

        anchors.fill: parent
        spacing: root.theme.space2

        Rectangle {
            Layout.preferredWidth: statusControls.implicitWidth + root.theme.space2
            Layout.preferredHeight: root.theme.compactControlSize
            radius: root.theme.radiusControl
            color: root.theme.surfaceRaised
            border.width: root.theme.borderWidth
            border.color: root.theme.ink

            RowLayout {
                id: statusControls

                anchors.centerIn: parent
                spacing: 0

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 28
                    iconSource: Quickshell.shellDir + "/assets/icons/" + (root.audioService.muted ? "volume-muted.svg" : "volume-high.svg")
                    accessibleName: root.audioService.statusText + ". Toggle mute"
                    enabled: root.audioService.ready
                    onClicked: root.audioService.toggleMuted()
                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 28
                    iconSource: Quickshell.shellDir + "/assets/icons/" + (root.audioService.inputMuted ? "microphone-off.svg" : "microphone.svg")
                    accessibleName: (root.audioStudioOpen ? "Close audio studio. " : "Open audio studio. ") + root.audioService.inputStatusText
                    fill: root.audioStudioOpen ? root.theme.peach : "transparent"
                    enabled: root.audioService.inputReady
                    onClicked: root.audioStudioToggleRequested()
                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 28
                    iconSource: Quickshell.shellDir + "/assets/icons/" + (root.bluetoothService.enabled ? "bluetooth.svg" : "bluetooth-off.svg")
                    accessibleName: root.bluetoothService.statusText + ". Toggle Bluetooth"
                    enabled: root.bluetoothService.available
                    onClicked: root.bluetoothService.toggleEnabled()
                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 28
                    iconSource: Quickshell.shellDir + "/assets/icons/" + (root.networkService.wifiEnabled ? "wifi.svg" : "wifi-off.svg")
                    accessibleName: root.networkService.statusText + ". Toggle Wi-Fi"
                    enabled: root.networkService.wifiAvailable
                    onClicked: root.networkService.toggleWifi()
                }

            }

        }

        FocusScope {
            id: panelToggle

            Layout.preferredWidth: 92
            Layout.preferredHeight: root.theme.compactControlSize
            activeFocusOnTab: true
            scale: panelTap.pressed ? root.theme.pressScale : 1
            Accessible.role: Accessible.Button
            Accessible.name: (root.panelOpen ? "Close quick panel. " : "Open quick panel. ") + root.clockService.accessibleText
            Keys.onEnterPressed: root.panelToggleRequested()
            Keys.onReturnPressed: root.panelToggleRequested()
            Keys.onSpacePressed: root.panelToggleRequested()

            Rectangle {
                anchors.fill: parent
                radius: root.theme.radiusControl
                color: root.panelOpen ? root.theme.lilac : (panelHover.hovered ? root.theme.alpha(root.theme.pink, 0.78) : root.theme.pink)
                border.width: root.theme.borderWidth
                border.color: panelToggle.activeFocus ? root.theme.focus : root.theme.ink
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: root.theme.space1

                Text {
                    text: root.clockService.timeText
                    color: root.theme.ink
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textMd
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.preferredWidth: meridiemLabel.implicitWidth + 8
                    Layout.preferredHeight: 18
                    radius: root.theme.radiusPill
                    color: root.theme.surfaceRaised
                    border.width: 1
                    border.color: root.theme.ink

                    Text {
                        id: meridiemLabel

                        anchors.centerIn: parent
                        text: root.clockService.meridiemText
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.Bold
                    }

                }

            }

            HoverHandler {
                id: panelHover
            }

            TapHandler {
                id: panelTap

                onTapped: root.panelToggleRequested()
            }

            Behavior on scale {
                NumberAnimation {
                    duration: root.theme.motionFast
                    easing.type: root.theme.easingStandard
                }

            }

        }

        Ui.IconButton {
            theme: root.theme
            controlSize: root.theme.compactControlSize
            iconSource: Quickshell.shellDir + "/assets/icons/" + (root.notificationService.quietMode ? "bell-off.svg" : "bell.svg")
            accessibleName: (root.notificationCenterOpen ? "Close" : "Open") + " notifications. " + root.notificationService.unreadCount + " unread"
            fill: root.notificationCenterOpen ? root.theme.lilac : root.theme.pink
            badgeText: root.notificationService.unreadCount > 0 ? (root.notificationService.unreadCount > 9 ? "9+" : String(root.notificationService.unreadCount)) : ""
            onClicked: root.notificationToggleRequested()
        }

    }

}
