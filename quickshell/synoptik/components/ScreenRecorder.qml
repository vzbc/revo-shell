import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    // Bound directly to the global singleton so states sync across all bar cards
    property bool isRecording: Boolean(Config.isRecording)

    readonly property string pos: Config.barPosition || "top"
    readonly property bool isVert: pos === "left" || pos === "right"

    // Dynamic drawer surface bounds driven by cardMargin
    implicitWidth: mainCard.implicitWidth + (cardMargin * 2)
    implicitHeight: mainCard.implicitHeight + (cardMargin * 2)

    // Periodically check pgrep to keep state persistent
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }

    Process {
        id: checkProc
        command: ["pgrep", "-x", "wf-recorder"]
        running: false

        onExited: (code, status) => {
            let active = (code === 0)
            root.isRecording = active
            Config.isRecording = active
        }
    }

    function triggerRegionSelect() {
        Config.showScreenRecorder = false

        let home = Quickshell.env("HOME")
        let dateStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss")
        let savePath = home + "/Videos/recording_" + dateStr + ".mp4"

        // Resolve default output monitor dynamically for portable system audio capture
        let script = "mkdir -p ~/Videos; set -l geom (slurp -b '#00000000' -c '#ef4444' -w 2); test -n \"$geom\"; and set -l sink (pactl get-default-sink 2>/dev/null); set -l audio_flag (test -n \"$sink\"; and echo \"--audio=$sink.monitor\"; or echo \"--audio=@DEFAULT_AUDIO_SINK@.monitor\"); exec wf-recorder $audio_flag -f \"" + savePath + "\" -g \"$geom\""

        Quickshell.execDetached(["fish", "-c", script])
        Config.isRecording = true
        root.isRecording = true
    }

    function triggerFullscreenSelect() {
        Config.showScreenRecorder = false

        let home = Quickshell.env("HOME")
        let dateStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss")
        let savePath = home + "/Videos/recording_" + dateStr + ".mp4"

        // Resolve default output monitor and active Hyprland output dynamically
        let script = "mkdir -p ~/Videos; set -l mon (hyprctl monitors -j | jq -r '.[] | select(.focused).name'); set -l sink (pactl get-default-sink 2>/dev/null); set -l audio_flag (test -n \"$sink\"; and echo \"--audio=$sink.monitor\"; or echo \"--audio=@DEFAULT_AUDIO_SINK@.monitor\"); exec wf-recorder $audio_flag -o $mon -f \"" + savePath + "\""

        Quickshell.execDetached(["fish", "-c", script])
        Config.isRecording = true
        root.isRecording = true
    }

    function stopRecording() {
        // Send SIGINT to gracefully close recording file
        Quickshell.execDetached(["fish", "-c", "pkill -2 wf-recorder"])
        root.isRecording = false
        Config.isRecording = false
        Config.showScreenRecorder = false
    }

    // Outer Margin Wrapper
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.cardMargin

        // Main Card Container
        Rectangle {
            id: mainCard
            Layout.fillWidth: true
            Layout.fillHeight: true

            implicitWidth: recordLayout.implicitWidth + (root.cardMargin * 2)
            implicitHeight: recordLayout.implicitHeight + (root.isVert ? (root.cardMargin + 4) : (root.cardMargin * 2))

            radius: Config.cornerRadius / 2
            color: root.isRecording ? Qt.rgba(0.8, 0.2, 0.2, 0.2) : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: root.isRecording ? "#ef4444" : Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // Watermark decoration
            Watermark {
                icon: Config.getIcon("recorder")
                iconSize: 120
                seed: 11
            }

            Behavior on color { ColorAnimation { duration: 150 } }

            GridLayout {
                id: recordLayout
                anchors.centerIn: parent
                columns: root.isVert ? 1 : 99
                rows: root.isVert ? 99 : 1
                columnSpacing: 10
                rowSpacing: 10

                // Pulsing recording indicator dot
                Rectangle {
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: 6
                    color: root.isRecording ? "#ef4444" : Config.textMuted
                    Layout.alignment: Qt.AlignCenter

                    SequentialAnimation on opacity {
                        running: root.isRecording
                        loops: Animation.Infinite
                        PropertyAnimation { to: 0.3; duration: 600 }
                        PropertyAnimation { to: 1.0; duration: 600 }
                    }
                }

                // Region Selection Button
                Rectangle {
                    implicitWidth: 44; implicitHeight: 44
                    radius: Config.cornerRadius / 3
                    color: areaHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.08)
                    visible: !root.isRecording
                    Layout.alignment: Qt.AlignCenter

                    Text {
                        anchors.centerIn: parent
                        text: "screenshot_region"
                        font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 28
                        color: areaHover.hovered ? Config.bgBase : Config.textMain
                    }

                    TapHandler {
                        onTapped: root.triggerRegionSelect()
                    }

                    HoverHandler { id: areaHover; cursorShape: Qt.PointingHandCursor }
                }

                // Fullscreen Capture Button
                Rectangle {
                    implicitWidth: 44; implicitHeight: 44
                    radius: Config.cornerRadius / 3
                    color: fullHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.08)
                    visible: !root.isRecording
                    Layout.alignment: Qt.AlignCenter

                    Text {
                        anchors.centerIn: parent
                        text: "screen_record"
                        font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 28
                        color: fullHover.hovered ? Config.bgBase : Config.textMain
                    }

                    TapHandler {
                        onTapped: root.triggerFullscreenSelect()
                    }

                    HoverHandler { id: fullHover; cursorShape: Qt.PointingHandCursor }
                }

                // Stop Button
                Rectangle {
                    implicitWidth: 44; implicitHeight: 44
                    radius: Config.cornerRadius / 3
                    color: stopHover.hovered ? "#ef4444" : Qt.rgba(239, 68, 68, 0.2)
                    visible: root.isRecording
                    Layout.alignment: Qt.AlignCenter

                    Text {
                        anchors.centerIn: parent
                        text: "stop"
                        font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 28
                        color: stopHover.hovered ? Config.textMain : "#ef4444"
                    }

                    TapHandler {
                        onTapped: root.stopRecording()
                    }

                    HoverHandler { id: stopHover; cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }
}