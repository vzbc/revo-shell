import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: audioModule

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    property int systemVolume: 50
    property bool isMuted: false
    property int inputVolume: 50
    property bool isInputMuted: false

    Component.onCompleted: {
        audioQueryProc.running = true
    }

    Connections {
        target: Config
        function onShowAudioChanged() {
            if (Config.showAudio) {
                audioQueryProc.running = false
                audioQueryProc.running = true
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: audioModule.cardMargin
        spacing: audioModule.cardMargin / 2

        // ==========================================
        // CARD 1: AUDIO OUTPUT
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitWidth: 360 
            implicitHeight: outputLayout.implicitHeight + (audioModule.cardMargin * 2)
            color: outputCardHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.05)
            radius: Config.cornerRadius
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // GRAPHIC WATERMARK
            Watermark {
                icon: Config.getIcon("audio")
                iconSize: 150
                seed: 4
            }

            Behavior on color { ColorAnimation { duration: 150 } }

            HoverHandler { id: outputCardHover }

            ColumnLayout {
                id: outputLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: audioModule.cardMargin
                spacing: audioModule.cardMargin

                // Audio Output Header
                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        implicitWidth: outTitleText.implicitWidth
                        implicitHeight: outTitleText.implicitHeight
                        Layout.fillWidth: true

                        Glow {
                            anchors.fill: outTitleText
                            source: outTitleText
                            radius: 8
                            samples: 16
                            color: Config.accent
                            spread: 0.2
                            transparentBorder: true
                            visible: Config.clockShowGlow
                        }

                        Text {
                            id: outTitleText
                            anchors.fill: parent
                            text: "AUDIO OUTPUT"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                        }
                    }

                    Text {
                        text: audioModule.isMuted ? "Muted" : audioModule.systemVolume + "%"
                        color: Config.accent
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }
                }

                // Output Slider Block
                RowLayout {
                    Layout.fillWidth: true
                    spacing: audioModule.cardMargin

                    Text {
                        text: audioModule.isMuted ? "volume_off" : "volume_up"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 24
                        color: Config.accent

                        TapHandler {
                            onTapped: {
                                audioModule.isMuted = !audioModule.isMuted
                                muteWriteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
                                muteWriteProc.running = true
                            }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }

                    // Direct Mouse Tracking Output Track
                    Item {
                        id: outTrack
                        Layout.fillWidth: true
                        implicitHeight: 32

                        property real localRatio: audioModule.systemVolume / 100.0
                        property bool isDragging: false

                        readonly property real currentRatio: isDragging ? localRatio : (audioModule.systemVolume / 100.0)

                        // Static track line
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Qt.rgba(255, 255, 255, 0.12)

                            // Active fill
                            Rectangle {
                                width: parent.width * outTrack.currentRatio
                                height: parent.height
                                color: audioModule.isMuted ? Config.textMuted : Config.accent
                                radius: 3
                            }
                        }

                        // Elastic morphing pill handle
                        Rectangle {
                            id: outHandle

                            readonly property real baseWidth: 12
                            readonly property real baseHeight: 24

                            property real stretch: 0.0
                            property real popScale: 1.0

                            width: Math.max(8, baseWidth + (stretch * 18))
                            height: Math.max(16, baseHeight - (stretch * 11.67))
                            radius: height / 2
                            color: Config.textMain

                            transform: Scale {
                                origin.x: outHandle.width / 2
                                origin.y: outHandle.height / 2
                                xScale: outHandle.popScale
                                yScale: outHandle.popScale
                            }

                            x: (outTrack.width * outTrack.currentRatio) - (width / 2)
                            y: (parent.height / 2) - (height / 2)

                            states: [
                                State {
                                    name: "dragging"
                                    when: outTrack.isDragging
                                    PropertyChanges { target: outHandle; stretch: 1.2; popScale: 1.0 }
                                }
                            ]

                            transitions: [
                                Transition {
                                    from: "dragging"
                                    to: ""
                                    SequentialAnimation {
                                        ParallelAnimation {
                                            NumberAnimation { target: outHandle; property: "stretch"; to: -0.4; duration: 100; easing.type: Easing.OutQuad }
                                            NumberAnimation { target: outHandle; property: "popScale"; to: 1.25; duration: 100; easing.type: Easing.OutBack }
                                        }
                                        ParallelAnimation {
                                            NumberAnimation { target: outHandle; property: "stretch"; to: 0.0; duration: 250; easing.type: Easing.OutBack }
                                            NumberAnimation { target: outHandle; property: "popScale"; to: 1.0; duration: 250; easing.type: Easing.OutBack }
                                        }
                                    }
                                }
                            ]

                            Connections {
                                target: audioModule
                                function onSystemVolumeChanged() {
                                    if (!outTrack.isDragging) outExternalMorphAnim.restart()
                                }
                            }

                            SequentialAnimation {
                                id: outExternalMorphAnim
                                ParallelAnimation {
                                    NumberAnimation { target: outHandle; property: "stretch"; to: 1.2; duration: 120; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: outHandle; property: "popScale"; to: 1.0; duration: 120; easing.type: Easing.OutCubic }
                                }
                                ParallelAnimation {
                                    NumberAnimation { target: outHandle; property: "stretch"; to: -0.4; duration: 100; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: outHandle; property: "popScale"; to: 1.25; duration: 100; easing.type: Easing.OutBack }
                                }
                                ParallelAnimation {
                                    NumberAnimation { target: outHandle; property: "stretch"; to: 0.0; duration: 250; easing.type: Easing.OutBack }
                                    NumberAnimation { target: outHandle; property: "popScale"; to: 1.0; duration: 250; easing.type: Easing.OutBack }
                                }
                            }
                        }

                        // High-precision MouseArea drag handler
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            function updateRatio(mouseXPos) {
                                if (outTrack.width <= 0) return
                                let ratio = Math.max(0.0, Math.min(1.0, mouseXPos / outTrack.width))
                                outTrack.localRatio = ratio
                                audioModule.systemVolume = Math.round(ratio * 100)
                                if (audioModule.isMuted) audioModule.isMuted = false
                                volWriteTimer.restart()
                            }

                            onPressed: mouse => {
                                outTrack.isDragging = true
                                updateRatio(mouse.x)
                            }
                            onPositionChanged: mouse => {
                                if (pressed) updateRatio(mouse.x)
                            }
                            onReleased: outTrack.isDragging = false
                            onCanceled: outTrack.isDragging = false
                        }
                    }
                }

                // Sink Devices List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: ListModel { id: sinkModel }

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: model.isDefault ? 38 : 34
                            radius: Config.cornerRadius / 2
                            color: model.isDefault ? Qt.rgba(255, 255, 255, 0.12) : (itemHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent")
                            border.color: model.isDefault ? Config.accent : "transparent"
                            border.width: model.isDefault ? 2 : 0

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10

                                Text {
                                    text: model.sinkName
                                    color: model.isDefault ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: model.isDefault ? Config.size(Config.fontBody) : Config.size(Config.fontCaption)
                                    font.bold: model.isDefault
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "✓"
                                    font.family: Config.sysFont
                                    font.pixelSize: model.isDefault ? Config.size(Config.fontBody) : Config.size(Config.fontCaption)
                                    font.bold: true
                                    color: Config.accent
                                    visible: model.isDefault
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    sinkSetProc.command = ["wpctl", "set-default", model.sinkTarget]
                                    sinkSetProc.running = true
                                }
                            }
                            HoverHandler { id: itemHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }
        }

        // ==========================================
        // CARD 2: AUDIO INPUT
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitWidth: 360
            implicitHeight: inputLayout.implicitHeight + (audioModule.cardMargin * 2)
            color: inputCardHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.05)
            radius: Config.cornerRadius
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // GRAPHIC WATERMARK
            Watermark {
                icon: "mic"
                iconSize: 150
                seed: 5
            }

            Behavior on color { ColorAnimation { duration: 150 } }

            HoverHandler { id: inputCardHover }

            ColumnLayout {
                id: inputLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: audioModule.cardMargin
                spacing: audioModule.cardMargin

                // Audio Input Header
                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        implicitWidth: inTitleText.implicitWidth
                        implicitHeight: inTitleText.implicitHeight
                        Layout.fillWidth: true

                        Glow {
                            anchors.fill: inTitleText
                            source: inTitleText
                            radius: 8
                            samples: 16
                            color: Config.accent
                            spread: 0.2
                            transparentBorder: true
                            visible: Config.clockShowGlow
                        }

                        Text {
                            id: inTitleText
                            anchors.fill: parent
                            text: "AUDIO INPUT"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                        }
                    }

                    Text {
                        text: audioModule.isInputMuted ? "Muted" : audioModule.inputVolume + "%"
                        color: Config.accent
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }
                }

                // Input Slider Block
                RowLayout {
                    Layout.fillWidth: true
                    spacing: audioModule.cardMargin

                    Text {
                        text: audioModule.isInputMuted ? "mic_off" : "mic"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 24
                        color: Config.accent

                        TapHandler {
                            onTapped: {
                                audioModule.isInputMuted = !audioModule.isInputMuted
                                muteWriteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
                                muteWriteProc.running = true
                            }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }

                    // Direct Mouse Tracking Input Track
                    Item {
                        id: inTrack
                        Layout.fillWidth: true
                        implicitHeight: 32

                        property real localRatio: audioModule.inputVolume / 100.0
                        property bool isDragging: false

                        readonly property real currentRatio: isDragging ? localRatio : (audioModule.inputVolume / 100.0)

                        // Static track line
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Qt.rgba(255, 255, 255, 0.12)

                            // Active fill
                            Rectangle {
                                width: parent.width * inTrack.currentRatio
                                height: parent.height
                                color: audioModule.isInputMuted ? Config.textMuted : Config.accent
                                radius: 3
                            }
                        }

                        // Elastic morphing pill handle
                        Rectangle {
                            id: inHandle

                            readonly property real baseWidth: 12
                            readonly property real baseHeight: 24

                            property real stretch: 0.0
                            property real popScale: 1.0

                            width: Math.max(8, baseWidth + (stretch * 18))
                            height: Math.max(16, baseHeight - (stretch * 11.67))
                            radius: height / 2
                            color: Config.textMain

                            transform: Scale {
                                origin.x: inHandle.width / 2
                                origin.y: inHandle.height / 2
                                xScale: inHandle.popScale
                                yScale: inHandle.popScale
                            }

                            x: (inTrack.width * inTrack.currentRatio) - (width / 2)
                            y: (parent.height / 2) - (height / 2)

                            states: [
                                State {
                                    name: "dragging"
                                    when: inTrack.isDragging
                                    PropertyChanges { target: inHandle; stretch: 1.2; popScale: 1.0 }
                                }
                            ]

                            transitions: [
                                Transition {
                                    from: "dragging"
                                    to: ""
                                    SequentialAnimation {
                                        ParallelAnimation {
                                            NumberAnimation { target: inHandle; property: "stretch"; to: -0.4; duration: 100; easing.type: Easing.OutQuad }
                                            NumberAnimation { target: inHandle; property: "popScale"; to: 1.25; duration: 100; easing.type: Easing.OutBack }
                                        }
                                        ParallelAnimation {
                                            NumberAnimation { target: inHandle; property: "stretch"; to: 0.0; duration: 250; easing.type: Easing.OutBack }
                                            NumberAnimation { target: inHandle; property: "popScale"; to: 1.0; duration: 250; easing.type: Easing.OutBack }
                                        }
                                    }
                                }
                            ]

                            Connections {
                                target: audioModule
                                function onInputVolumeChanged() {
                                    if (!inTrack.isDragging) inExternalMorphAnim.restart()
                                }
                            }

                            SequentialAnimation {
                                id: inExternalMorphAnim
                                ParallelAnimation {
                                    NumberAnimation { target: inHandle; property: "stretch"; to: 1.2; duration: 120; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: inHandle; property: "popScale"; to: 1.0; duration: 120; easing.type: Easing.OutCubic }
                                }
                                ParallelAnimation {
                                    NumberAnimation { target: inHandle; property: "stretch"; to: -0.4; duration: 100; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: inHandle; property: "popScale"; to: 1.25; duration: 100; easing.type: Easing.OutBack }
                                }
                                ParallelAnimation {
                                    NumberAnimation { target: inHandle; property: "stretch"; to: 0.0; duration: 250; easing.type: Easing.OutBack }
                                    NumberAnimation { target: inHandle; property: "popScale"; to: 1.0; duration: 250; easing.type: Easing.OutBack }
                                }
                            }
                        }

                        // High-precision MouseArea drag handler
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            function updateRatio(mouseXPos) {
                                if (inTrack.width <= 0) return
                                let ratio = Math.max(0.0, Math.min(1.0, mouseXPos / inTrack.width))
                                inTrack.localRatio = ratio
                                audioModule.inputVolume = Math.round(ratio * 100)
                                if (audioModule.isInputMuted) audioModule.isInputMuted = false
                                micWriteTimer.restart()
                            }

                            onPressed: mouse => {
                                inTrack.isDragging = true
                                updateRatio(mouse.x)
                            }
                            onPositionChanged: mouse => {
                                if (pressed) updateRatio(mouse.x)
                            }
                            onReleased: inTrack.isDragging = false
                            onCanceled: inTrack.isDragging = false
                        }
                    }
                }

                // Source Devices List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: ListModel { id: sourceModel }

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: model.isDefault ? 38 : 34
                            radius: Config.cornerRadius / 2
                            color: model.isDefault ? Qt.rgba(255, 255, 255, 0.12) : (itemHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent")
                            border.color: model.isDefault ? Config.accent : "transparent"
                            border.width: model.isDefault ? 2 : 0

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10

                                Text {
                                    text: model.sourceName
                                    color: model.isDefault ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: model.isDefault ? Config.size(Config.fontBody) : Config.size(Config.fontCaption)
                                    font.bold: model.isDefault
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "✓"
                                    font.family: Config.sysFont
                                    font.pixelSize: model.isDefault ? Config.size(Config.fontBody) : Config.size(Config.fontCaption)
                                    font.bold: true
                                    color: Config.accent
                                    visible: model.isDefault
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    sinkSetProc.command = ["wpctl", "set-default", model.sourceTarget]
                                    sinkSetProc.running = true
                                }
                            }
                            HoverHandler { id: itemHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }
        }
    }

    // Backend Process Handlers
    Timer {
        id: volWriteTimer
        interval: 30
        repeat: false
        onTriggered: {
            volumeWriteProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (audioModule.systemVolume / 100).toFixed(2)]
            volumeWriteProc.running = true
        }
    }

    Timer {
        id: micWriteTimer
        interval: 30
        repeat: false
        onTriggered: {
            volumeWriteProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (audioModule.inputVolume / 100).toFixed(2)]
            volumeWriteProc.running = true
        }
    }

    // Fast path: Update volume and mute state immediately (0ms delay)
    function triggerFastVolumeRead() {
        if (!volumeReadProc.running) volumeReadProc.running = true
        if (!micReadProc.running) micReadProc.running = true
    }

    // Slow path: Only re-scan device lists (wpctl status) when sinks/sources change
    Timer {
        id: debounceAudioTimer
        interval: 200
        repeat: false
        onTriggered: {
            audioQueryProc.running = false
            audioQueryProc.running = true
        }
    }

    Process {
        id: pulseEventStream
        command: ["stdbuf", "-oL", "pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                // Instant update for volume/mute changes on sinks and sources
                if (data.includes("change")) {
                    audioModule.triggerFastVolumeRead()
                }

                // Debounced update only when hardware devices are plugged/unplugged or defaults switch
                if (data.includes("new") || data.includes("remove") || data.includes("server")) {
                    debounceAudioTimer.restart()
                }
            }
        }
    }

    Process {
        id: audioQueryProc
        command: ["wpctl", "status"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n")
                sinkModel.clear()
                sourceModel.clear()
                
                let seenSinkIds = {}
                let seenSourceIds = {}
                let targetBlock = 0
                let hasDefaultSink = false
                let hasDefaultSource = false

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i]
                    if (line.includes("Sinks:")) { targetBlock = 1; continue; }
                    if (line.includes("Sources:")) { targetBlock = 2; continue; }
                    if (line.includes("Filters:") || line.includes("Streams:") || line.includes("Settings:")) { 
                        targetBlock = 0
                    }

                    if (line.includes("├─") || line.includes("└─")) continue;

                    let match = line.match(/(\*\s*)?\s*(\d+)\.\s+(.*)/)
                    if (match) {
                        let isDef = (match[1] !== undefined && match[1].includes("*"))
                        let id = match[2].trim()
                        let rawName = match[3].trim()
                        let cleanName = rawName.split("[")[0].replace(/[├─└─│]/g, "").trim()
                        if (cleanName === "") continue;

                        if (targetBlock === 1) {
                            if (seenSinkIds[id]) continue;
                            seenSinkIds[id] = true
                            let finalDef = isDef && !hasDefaultSink
                            if (finalDef) hasDefaultSink = true
                            sinkModel.append({ isDefault: finalDef, sinkTarget: id, sinkName: cleanName })
                        } else if (targetBlock === 2) {
                            if (seenSourceIds[id]) continue;
                            seenSourceIds[id] = true
                            let finalDef = isDef && !hasDefaultSource
                            if (finalDef) hasDefaultSource = true
                            sourceModel.append({ isDefault: finalDef, sourceTarget: id, sourceName: cleanName })
                        }
                    }
                }
                volumeReadProc.running = true
                micReadProc.running = true
            }
        }
    }

    Process {
        id: volumeReadProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let cleaned = this.text.trim()
                let match = cleaned.match(/Volume:\s+([0-9.]+)/)
                if (match) {
                    let newVol = Math.round(parseFloat(match[1]) * 100)
                    if (!outTrack.isDragging) {
                        audioModule.systemVolume = newVol
                    }
                    audioModule.isMuted = cleaned.includes("[MUTED]")
                }
            }
        }
    }

    Process {
        id: micReadProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let cleaned = this.text.trim()
                let match = cleaned.match(/Volume:\s+([0-9.]+)/)
                if (match) {
                    let newVol = Math.round(parseFloat(match[1]) * 100)
                    if (!inTrack.isDragging) {
                        audioModule.inputVolume = newVol
                    }
                    audioModule.isInputMuted = cleaned.includes("[MUTED]")
                }
            }
        }
    }

    Process { id: volumeWriteProc; running: false }
    Process { id: muteWriteProc; running: false }
    Process { id: sinkSetProc; running: false; onExited: audioQueryProc.running = true }
}