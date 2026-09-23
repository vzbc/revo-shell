import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property QtObject clockService
    required property QtObject audioService
    required property QtObject networkService
    required property QtObject bluetoothService
    required property QtObject notificationService
    required property QtObject brightnessService
    required property QtObject systemStats
    required property QtObject calendarService
    required property QtObject sessionService
    required property QtObject attentionService
    property bool powerMenuOpen: false
    property string pendingAction: ""
    property string pendingLabel: ""

    signal closeRequested()
    signal notificationsRequested()

    function resetTransientState() {
        powerMenuOpen = false;
        pendingAction = "";
        pendingLabel = "";
        calendarService.goToToday();
    }

    function choosePowerAction(action, label) {
        pendingAction = action;
        pendingLabel = label;
    }

    function confirmPowerAction() {
        if (pendingAction.length === 0)
            return ;

        const action = pendingAction;
        resetTransientState();
        closeRequested();
        sessionService.runAction(action);
    }

    implicitWidth: theme.quickPanelWidth
    implicitHeight: panelColumn.implicitHeight + theme.space4 * 2 + theme.shadowOffset
    focus: true
    Keys.onEscapePressed: root.closeRequested()

    Ui.RaisedSurface {
        anchors.fill: parent
        theme: root.theme
        fill: root.theme.surface
        surfaceRadius: root.theme.radiusPanel
        padding: root.theme.space4

        ColumnLayout {
            id: panelColumn

            anchors.fill: parent
            spacing: root.theme.space3

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                spacing: root.theme.space3

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: "Quick controls"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textLg
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(root.clockService.now, "dddd, MMMM d")
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 34
                    iconSource: Quickshell.shellDir + "/assets/icons/power.svg"
                    accessibleName: root.powerMenuOpen ? "Close session actions" : "Open session actions"
                    fill: root.theme.coral
                    raised: true
                    onClicked: {
                        root.powerMenuOpen = !root.powerMenuOpen;
                        root.pendingAction = "";
                        root.pendingLabel = "";
                    }
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.theme.space2

                Ui.StatChip {
                    theme: root.theme
                    iconSource: Quickshell.shellDir + "/assets/icons/cpu.svg"
                    label: "CPU"
                    value: root.systemStats.cpuLoading ? "..." : (root.systemStats.cpuError ? "!" : root.systemStats.cpuUsage + "%")
                    accent: root.theme.peach
                }

                Ui.StatChip {
                    theme: root.theme
                    iconSource: Quickshell.shellDir + "/assets/icons/memory.svg"
                    label: "RAM"
                    value: root.systemStats.memoryLoading ? "..." : (root.systemStats.memoryError ? "!" : root.systemStats.memoryUsage + "%")
                    accent: root.theme.blue
                }

                Ui.StatChip {
                    visible: root.systemStats.batteryAvailable
                    theme: root.theme
                    iconSource: Quickshell.shellDir + "/assets/icons/battery.svg"
                    label: "BAT"
                    value: root.systemStats.batteryPercent + "%"
                    accent: root.theme.green
                }

                Item {
                    Layout.fillWidth: true
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.theme.space2

                Ui.ControlTile {
                    Layout.fillWidth: true
                    theme: root.theme
                    iconSource: Quickshell.shellDir + "/assets/icons/coffee.svg"
                    label: "Caffeine"
                    status: root.attentionService.caffeineStatusText
                    checked: root.attentionService.caffeineEnabled
                    accent: root.theme.gold
                    onClicked: root.attentionService.toggleCaffeine()
                }

                Ui.ControlTile {
                    Layout.fillWidth: true
                    theme: root.theme
                    iconSource: Quickshell.shellDir + "/assets/icons/" + (root.notificationService.quietMode ? "bell-off.svg" : "bell.svg")
                    label: "Quiet mode"
                    status: root.notificationService.quietMode ? "Critical alerts only" : "Notifications on"
                    checked: root.notificationService.quietMode
                    accent: root.theme.lilac
                    onClicked: root.notificationService.toggleQuietMode()
                }

                Item {
                    Layout.fillWidth: true
                }

            }

            RowLayout {
                visible: root.attentionService.caffeineEnabled
                Layout.fillWidth: true
                spacing: root.theme.space2

                Text {
                    Layout.fillWidth: true
                    text: "Keep awake for"
                    color: root.theme.inkMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textXs
                    font.weight: Font.DemiBold
                }

                Ui.PixelButton {
                    Layout.preferredWidth: 60
                    theme: root.theme
                    label: "30m"
                    fill: root.theme.surfaceRaised
                    onClicked: root.attentionService.startCaffeine(30)
                }

                Ui.PixelButton {
                    Layout.preferredWidth: 60
                    theme: root.theme
                    label: "1h"
                    fill: root.theme.gold
                    onClicked: root.attentionService.startCaffeine(60)
                }

                Ui.PixelButton {
                    Layout.preferredWidth: 60
                    theme: root.theme
                    label: "2h"
                    fill: root.theme.surfaceRaised
                    onClicked: root.attentionService.startCaffeine(120)
                }

            }

            Rectangle {
                visible: root.powerMenuOpen
                Layout.fillWidth: true
                Layout.preferredHeight: root.pendingAction.length === 0 ? 78 : 66
                radius: root.theme.radiusCard
                color: root.theme.surfaceMuted
                border.width: root.theme.borderWidth
                border.color: root.theme.ink

                RowLayout {
                    visible: root.pendingAction.length === 0
                    anchors.fill: parent
                    anchors.margins: root.theme.space2
                    spacing: root.theme.space2

                    Ui.ControlTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        theme: root.theme
                        iconSource: Quickshell.shellDir + "/assets/icons/lock.svg"
                        label: "Lock"
                        status: "Session"
                        accent: root.theme.green
                        onClicked: root.choosePowerAction("lock", "Lock the session?")
                    }

                    Ui.ControlTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        theme: root.theme
                        iconSource: Quickshell.shellDir + "/assets/icons/restart.svg"
                        label: "Restart"
                        status: "System"
                        accent: root.theme.gold
                        onClicked: root.choosePowerAction("restart", "Restart the computer?")
                    }

                    Ui.ControlTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        theme: root.theme
                        iconSource: Quickshell.shellDir + "/assets/icons/power.svg"
                        label: "Power off"
                        status: "System"
                        accent: root.theme.coral
                        onClicked: root.choosePowerAction("poweroff", "Power off the computer?")
                    }

                }

                RowLayout {
                    visible: root.pendingAction.length > 0
                    anchors.fill: parent
                    anchors.margins: root.theme.space2
                    spacing: root.theme.space2

                    Text {
                        Layout.fillWidth: true
                        text: root.pendingLabel
                        wrapMode: Text.WordWrap
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                        font.weight: Font.DemiBold
                    }

                    Ui.PixelButton {
                        Layout.preferredWidth: 82
                        theme: root.theme
                        label: "Cancel"
                        fill: root.theme.surfaceRaised
                        onClicked: {
                            root.pendingAction = "";
                            root.pendingLabel = "";
                        }
                    }

                    Ui.PixelButton {
                        Layout.preferredWidth: 82
                        theme: root.theme
                        label: "Confirm"
                        fill: root.theme.coral
                        onClicked: root.confirmPowerAction()
                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.theme.space2

                Ui.ControlTile {
                    Layout.fillWidth: true
                    theme: root.theme
                    iconSource: Quickshell.shellDir + "/assets/icons/" + (root.networkService.wifiEnabled ? "wifi.svg" : "wifi-off.svg")
                    label: "Wi-Fi"
                    status: root.networkService.networkName
                    checked: root.networkService.wifiEnabled
                    enabled: root.networkService.wifiAvailable
                    accent: root.theme.green
                    onClicked: root.networkService.toggleWifi()
                }

                Ui.ControlTile {
                    Layout.fillWidth: true
                    theme: root.theme
                    iconSource: Quickshell.shellDir + "/assets/icons/" + (root.bluetoothService.enabled ? "bluetooth.svg" : "bluetooth-off.svg")
                    label: "Bluetooth"
                    status: root.bluetoothService.connectedCount > 0 ? root.bluetoothService.connectedName : (root.bluetoothService.enabled ? "On" : "Off")
                    checked: root.bluetoothService.enabled
                    enabled: root.bluetoothService.available
                    accent: root.theme.blue
                    onClicked: root.bluetoothService.toggleEnabled()
                }

                Ui.ControlTile {
                    Layout.fillWidth: true
                    theme: root.theme
                    iconSource: Quickshell.shellDir + "/assets/icons/bell.svg"
                    label: "Notify"
                    status: root.notificationService.count + " saved"
                    checked: root.notificationService.count > 0
                    accent: root.theme.pink
                    onClicked: root.notificationsRequested()
                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: sliderColumn.implicitHeight + root.theme.space3 * 2
                radius: root.theme.radiusCard
                color: root.theme.surfaceRaised
                border.width: root.theme.borderWidth
                border.color: root.theme.ink

                ColumnLayout {
                    id: sliderColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: root.theme.space3
                    spacing: root.theme.space2

                    Ui.ValueSlider {
                        Layout.fillWidth: true
                        theme: root.theme
                        iconSource: Quickshell.shellDir + "/assets/icons/" + (root.audioService.muted ? "volume-muted.svg" : "volume-high.svg")
                        label: "Volume"
                        statusText: root.audioService.muted ? "Muted" : root.audioService.volumePercent + "%"
                        value: Math.min(1, root.audioService.volume)
                        enabled: root.audioService.ready
                        accent: root.theme.green
                        iconClickable: true
                        iconAccessibleName: root.audioService.statusText + ". Toggle mute"
                        onIconClicked: root.audioService.toggleMuted()
                        onUserChanged: (value) => {
                            return root.audioService.setVolume(value);
                        }
                    }

                    Ui.ValueSlider {
                        Layout.fillWidth: true
                        theme: root.theme
                        iconSource: Quickshell.shellDir + "/assets/icons/sun.svg"
                        label: "Brightness"
                        statusText: root.brightnessService.statusText
                        value: root.brightnessService.value
                        enabled: root.brightnessService.available
                        accent: root.theme.peach
                        onUserChanged: (value) => {
                            return root.brightnessService.setValue(value);
                        }
                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: monthCalendar.implicitHeight + root.theme.space3 * 2
                radius: root.theme.radiusCard
                color: root.theme.surfaceRaised
                border.width: root.theme.borderWidth
                border.color: root.theme.ink

                MonthCalendar {
                    id: monthCalendar

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: root.theme.space3
                    theme: root.theme
                    calendarService: root.calendarService
                }

            }

        }

    }

}
