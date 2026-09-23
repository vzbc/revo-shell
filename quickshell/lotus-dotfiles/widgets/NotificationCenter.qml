import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property QtObject notificationService
    property bool clearConfirmationOpen: false

    signal closeRequested()

    function open() {
        clearConfirmationOpen = false;
        notificationService.markAllRead();
        forceActiveFocus();
    }

    function resetTransientState() {
        clearConfirmationOpen = false;
    }

    implicitWidth: theme.notificationCenterWidth
    implicitHeight: theme.notificationCenterHeight
    focus: true
    Keys.onEscapePressed: root.closeRequested()

    Ui.RaisedSurface {
        anchors.fill: parent
        theme: root.theme
        fill: root.theme.surface
        surfaceRadius: root.theme.radiusPanel
        padding: root.theme.space4

        ColumnLayout {
            anchors.fill: parent
            spacing: root.theme.space3

            RowLayout {
                Layout.fillWidth: true
                spacing: root.theme.space2

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: root.theme.radiusControl
                    color: root.notificationService.quietMode ? root.theme.lilac : root.theme.pink
                    border.width: root.theme.borderWidth
                    border.color: root.theme.ink

                    Image {
                        anchors.centerIn: parent
                        width: root.theme.iconMd
                        height: root.theme.iconMd
                        source: Quickshell.shellDir + "/assets/icons/" + (root.notificationService.quietMode ? "bell-off.svg" : "bell.svg")
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "Notifications"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textLg
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.notificationService.statusText + "  ·  " + root.notificationService.count + " saved"
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

                Ui.PixelButton {
                    Layout.preferredWidth: 84
                    theme: root.theme
                    label: root.notificationService.quietMode ? "Unmute" : "Quiet"
                    fill: root.theme.lilac
                    onClicked: root.notificationService.toggleQuietMode()
                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 34
                    iconSource: Quickshell.shellDir + "/assets/icons/close.svg"
                    accessibleName: "Close notifications"
                    fill: root.theme.surfaceRaised
                    onClicked: root.closeRequested()
                }

            }

            Rectangle {
                visible: root.clearConfirmationOpen
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 62 : 0
                radius: root.theme.radiusCard
                color: root.theme.alpha(root.theme.coral, 0.32)
                border.width: root.theme.borderWidth
                border.color: root.theme.ink

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.theme.space2
                    spacing: root.theme.space2

                    Text {
                        Layout.fillWidth: true
                        text: "Clear this session's notification history?"
                        wrapMode: Text.WordWrap
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                        font.weight: Font.DemiBold
                    }

                    Ui.PixelButton {
                        Layout.preferredWidth: 76
                        theme: root.theme
                        label: "Cancel"
                        fill: root.theme.surfaceRaised
                        onClicked: root.clearConfirmationOpen = false
                    }

                    Ui.PixelButton {
                        Layout.preferredWidth: 76
                        theme: root.theme
                        label: "Clear"
                        fill: root.theme.coral
                        onClicked: {
                            root.clearConfirmationOpen = false;
                            root.notificationService.clearHistory();
                        }
                    }

                }

            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    anchors.fill: parent
                    visible: root.notificationService.count > 0
                    clip: true
                    spacing: root.theme.space2
                    boundsBehavior: Flickable.StopAtBounds

                    model: ScriptModel {
                        values: root.notificationService.history
                    }

                    delegate: NotificationCard {
                        required property var modelData

                        width: ListView.view.width
                        theme: root.theme
                        notificationService: root.notificationService
                        entry: modelData
                    }

                }

                Column {
                    anchors.centerIn: parent
                    visible: root.notificationService.count === 0
                    spacing: root.theme.space2

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 52
                        height: 52
                        radius: 26
                        color: root.theme.alpha(root.theme.green, 0.55)
                        border.width: root.theme.borderWidth
                        border.color: root.theme.ink

                        Image {
                            anchors.centerIn: parent
                            width: root.theme.iconLg
                            height: root.theme.iconLg
                            source: Quickshell.shellDir + "/assets/icons/bell.svg"
                        }

                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "All quiet"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textMd
                        font.weight: Font.Bold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 280
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: root.notificationService.serverReady ? "New notifications will appear here." : "The native notification server is unavailable."
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.theme.space2

                Text {
                    Layout.fillWidth: true
                    text: "Session only  ·  Esc closes"
                    color: root.theme.inkMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textXs
                }

                Ui.PixelButton {
                    Layout.preferredWidth: 96
                    theme: root.theme
                    label: "Clear all"
                    fill: root.theme.coral
                    enabled: root.notificationService.count > 0
                    onClicked: root.clearConfirmationOpen = true
                }

            }

        }

    }

}
