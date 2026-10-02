import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.components
import qs.config

// Output/input volume, output device picker and media controls.
BarPopup {
    id: popup

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: [...Pipewire.nodes.values].filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var player: [...Mpris.players.values].find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    implicitWidth: 240

    PwObjectTracker {
        objects: [popup.sink, popup.source]
    }

    component Channel: ColumnLayout {
        id: channel

        required property string label
        property var node

        Layout.fillWidth: true
        spacing: 4
        visible: node?.audio ? true : false

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            BarText {
                Layout.fillWidth: true
                text: channel.label
                font.bold: true
            }

            BarText {
                text: Math.round((channel.node?.audio?.volume ?? 0) * 100) + "%"
            }

            BarButton {
                implicitWidth: 56
                implicitHeight: 24
                text: channel.node?.audio?.muted ? "Unmute" : "Mute"
                active: channel.node?.audio?.muted ?? false
                onClicked: channel.node.audio.muted = !channel.node.audio.muted
            }
        }

        Slider {
            Layout.fillWidth: true
            value: channel.node?.audio?.volume ?? 0
            opacity: channel.node?.audio?.muted ? 0.5 : 1
            onMoved: v => {
                channel.node.audio.muted = false
                channel.node.audio.volume = v
            }
        }
    }

    Channel {
        label: "Speakers"
        node: popup.sink
    }

    Channel {
        label: "Microphone"
        node: popup.source
    }

    Separator {
        vertical: false
        visible: popup.sinks.length > 1
    }

    BarText {
        visible: popup.sinks.length > 1
        text: "Output device"
        color: Theme.textDim
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: popup.sinks.length > 1
        spacing: 0

        Repeater {
            model: popup.sinks

            delegate: MenuRow {
                required property var modelData

                text: modelData.description || modelData.nickname || modelData.name
                checkType: 2
                checked: modelData === popup.sink
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
    }

    // Now playing
    Separator {
        vertical: false
        visible: popup.player !== null
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: popup.player !== null
        spacing: 4

        BarText {
            Layout.fillWidth: true
            Layout.maximumWidth: 222
            text: popup.player?.trackTitle || popup.player?.identity || ""
            font.bold: true
        }

        BarText {
            Layout.fillWidth: true
            Layout.maximumWidth: 222
            visible: text !== ""
            text: popup.player?.trackArtist ?? ""
            color: Theme.textDim
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            BarButton {
                Layout.fillWidth: true
                implicitHeight: 24
                text: "|<"
                enabled: popup.player?.canGoPrevious ?? false
                onClicked: popup.player.previous()
            }

            BarButton {
                Layout.fillWidth: true
                implicitHeight: 24
                text: popup.player?.isPlaying ? "||" : ">"
                active: popup.player?.isPlaying ?? false
                enabled: popup.player?.canTogglePlaying ?? false
                onClicked: popup.player.togglePlaying()
            }

            BarButton {
                Layout.fillWidth: true
                implicitHeight: 24
                text: ">|"
                enabled: popup.player?.canGoNext ?? false
                onClicked: popup.player.next()
            }
        }
    }

    Separator {
        vertical: false
    }

    BarButton {
        Layout.fillWidth: true
        implicitHeight: 26
        text: "Open Mixer..."
        onClicked: {
            Quickshell.execDetached(["pavucontrol"])
            popup.close()
        }
    }
}
