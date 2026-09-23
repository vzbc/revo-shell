import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property QtObject audioService

    signal closeRequested()

    function open() {
        forceActiveFocus();
    }

    implicitWidth: 430
    implicitHeight: studioColumn.implicitHeight + theme.space4 * 2 + theme.shadowOffset
    focus: true
    Keys.onEscapePressed: root.closeRequested()

    Ui.RaisedSurface {
        anchors.fill: parent
        theme: root.theme
        fill: root.theme.surface
        surfaceRadius: root.theme.radiusPanel
        padding: root.theme.space4

        ColumnLayout {
            id: studioColumn

            anchors.fill: parent
            spacing: root.theme.space3

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: root.theme.space2

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: root.theme.radiusControl
                    color: root.theme.peach
                    border.width: root.theme.borderWidth
                    border.color: root.theme.ink

                    Image {
                        anchors.centerIn: parent
                        width: root.theme.iconSm
                        height: root.theme.iconSm
                        source: Quickshell.shellDir + "/assets/icons/microphone.svg"
                        sourceSize.width: root.theme.iconSm
                        sourceSize.height: root.theme.iconSm
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "Audio studio"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textLg
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Route sound and tune both sides"
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 32
                    iconSource: Quickshell.shellDir + "/assets/icons/close.svg"
                    accessibleName: "Close audio studio"
                    fill: root.theme.surfaceRaised
                    onClicked: root.closeRequested()
                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: outputColumn.implicitHeight + root.theme.space3 * 2
                radius: root.theme.radiusCard
                color: root.theme.surfaceRaised
                border.width: root.theme.borderWidth
                border.color: root.theme.ink

                ColumnLayout {
                    id: outputColumn

                    anchors.fill: parent
                    anchors.margins: root.theme.space3
                    spacing: root.theme.space2

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "OUTPUT"
                            color: root.theme.inkMuted
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.textXs
                            font.weight: Font.Bold
                        }

                        Ui.IconButton {
                            theme: root.theme
                            controlSize: 28
                            iconSource: Quickshell.shellDir + "/assets/icons/" + (root.audioService.muted ? "volume-muted.svg" : "volume-high.svg")
                            accessibleName: root.audioService.statusText + ". Toggle output mute"
                            fill: root.audioService.muted ? root.theme.coral : root.theme.green
                            enabled: root.audioService.ready
                            onClicked: root.audioService.toggleMuted()
                        }

                    }

                    Ui.ValueSlider {
                        Layout.fillWidth: true
                        theme: root.theme
                        iconSource: Quickshell.shellDir + "/assets/icons/volume-high.svg"
                        label: root.audioService.ready ? root.audioService.deviceName(root.audioService.sink) : "Output unavailable"
                        statusText: root.audioService.muted ? "Muted" : root.audioService.volumePercent + "%"
                        value: Math.min(1, root.audioService.volume)
                        enabled: root.audioService.ready
                        accent: root.theme.green
                        onUserChanged: (value) => {
                            return root.audioService.setVolume(value);
                        }
                    }

                    Repeater {
                        model: root.audioService.outputNodes

                        AudioDeviceRow {
                            required property var modelData

                            Layout.fillWidth: true
                            theme: root.theme
                            label: root.audioService.deviceName(modelData)
                            iconSource: Quickshell.shellDir + "/assets/icons/headphones.svg"
                            selected: root.audioService.isDefaultOutput(modelData)
                            enabled: modelData.ready
                            onClicked: root.audioService.selectOutput(modelData)
                        }

                    }

                    Text {
                        visible: root.audioService.outputNodes.length === 0
                        Layout.fillWidth: true
                        text: "No output devices found."
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: inputColumn.implicitHeight + root.theme.space3 * 2
                radius: root.theme.radiusCard
                color: root.theme.surfaceRaised
                border.width: root.theme.borderWidth
                border.color: root.theme.ink

                ColumnLayout {
                    id: inputColumn

                    anchors.fill: parent
                    anchors.margins: root.theme.space3
                    spacing: root.theme.space2

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "MICROPHONE"
                            color: root.theme.inkMuted
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.textXs
                            font.weight: Font.Bold
                        }

                        Ui.IconButton {
                            theme: root.theme
                            controlSize: 28
                            iconSource: Quickshell.shellDir + "/assets/icons/" + (root.audioService.inputMuted ? "microphone-off.svg" : "microphone.svg")
                            accessibleName: root.audioService.inputStatusText + ". Toggle microphone mute"
                            fill: root.audioService.inputMuted ? root.theme.coral : root.theme.peach
                            enabled: root.audioService.inputReady
                            onClicked: root.audioService.toggleInputMuted()
                        }

                    }

                    Ui.ValueSlider {
                        Layout.fillWidth: true
                        theme: root.theme
                        iconSource: Quickshell.shellDir + "/assets/icons/microphone.svg"
                        label: root.audioService.inputReady ? root.audioService.deviceName(root.audioService.source) : "Microphone unavailable"
                        statusText: root.audioService.inputMuted ? "Muted" : root.audioService.inputVolumePercent + "%"
                        value: Math.min(1, root.audioService.inputVolume)
                        enabled: root.audioService.inputReady
                        accent: root.theme.peach
                        onUserChanged: (value) => {
                            return root.audioService.setInputVolume(value);
                        }
                    }

                    Repeater {
                        model: root.audioService.inputNodes

                        AudioDeviceRow {
                            required property var modelData

                            Layout.fillWidth: true
                            theme: root.theme
                            label: root.audioService.deviceName(modelData)
                            iconSource: Quickshell.shellDir + "/assets/icons/microphone.svg"
                            selected: root.audioService.isDefaultInput(modelData)
                            enabled: modelData.ready
                            onClicked: root.audioService.selectInput(modelData)
                        }

                    }

                    Text {
                        visible: root.audioService.inputNodes.length === 0
                        Layout.fillWidth: true
                        text: "No microphone devices found."
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

            }

        }

    }

}
