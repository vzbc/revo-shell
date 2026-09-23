import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: osdRoot

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    property int volume: -1 
    property bool isMuted: false
    property bool initialized: false 

    // Smoothly animate target volume value instead of layout span to avoid resize jumping
    property real animVolume: Math.max(0, volume)
    Behavior on animVolume {
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
    }

    SoundEffect {
        id: volumeTick
        // Inline Comment: Pre-buffer volume step tick WAV
        source: Qt.resolvedUrl(Quickshell.shellDir.toString() + "/assets/sound2.wav")
        volume: 0.1
    }

    function trigger() {
        if (typeof Config !== "undefined" && (Config.showAudio || Config.showControlCenter)) return
        
        osdHideTimer.stop()
        Config.showOSD = true
        osdHideTimer.restart()
    }

    function dismiss() {
        Config.showOSD = false
        osdHideTimer.stop()
    }

    Component.onCompleted: {
        initReadProc.running = true
    }

    Connections {
        target: Config
        function onShowOSDChanged() {
            if (Config.showOSD) {
                osdHideTimer.restart()
            }
        }
    }

    Timer {
        id: osdHideTimer
        interval: 2000
        repeat: false
        onTriggered: osdRoot.dismiss()
    }

    Process {
        id: initReadProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let cleaned = this.text.trim()
                let match = cleaned.match(/Volume:\s+([0-9.]+)/)
                if (match) {
                    osdRoot.volume = Math.round(parseFloat(match[1]) * 100)
                    osdRoot.isMuted = cleaned.includes("[MUTED]")
                    osdRoot.initialized = true
                }
            }
        }
    }

    Process {
        id: osdReadProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let cleaned = this.text.trim()
                let match = cleaned.match(/Volume:\s+([0-9.]+)/)
                if (match) {
                    let newVol = Math.round(parseFloat(match[1]) * 100)
                    let newMute = cleaned.includes("[MUTED]")

                    if (newVol !== osdRoot.volume || newMute !== osdRoot.isMuted) {
                        osdRoot.volume = newVol
                        osdRoot.isMuted = newMute
                        
                        if (osdRoot.initialized) {
                            osdRoot.trigger()
                        }
                    }
                }
            }
        }
    }

    Process {
        id: osdSubscribeProc
        command: ["stdbuf", "-oL", "pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("sink") || data.includes("server")) {
                    if (!osdReadProc.running) {
                        osdReadProc.running = true
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: osdRoot.cardMargin
        spacing: osdRoot.cardMargin

        Rectangle {
            Layout.fillWidth: true
            implicitWidth: 500
            implicitHeight: cardContent.implicitHeight + (osdRoot.cardMargin * 2)
            color: Qt.rgba(255, 255, 255, 0.05)
            radius: Config.cornerRadius

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: osdRoot.dismiss()
            }

            RowLayout {
                id: cardContent
                anchors.fill: parent
                anchors.margins: osdRoot.cardMargin
                spacing: osdRoot.cardMargin

                Rectangle {
                    implicitWidth: 48
                    implicitHeight: 48
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(255, 255, 255, 0.06)
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                    Text {
                        anchors.centerIn: parent
                        text: osdRoot.isMuted 
                            ? "volume_off" 
                            : (osdRoot.volume === 0 ? "volume_mute" : (osdRoot.volume < 50 ? "volume_down" : "volume_up"))
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                        color: osdRoot.isMuted ? Config.textMuted : Config.accent
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: 48

                    Glow {
                        anchors.fill: waveCanvasH
                        source: waveCanvasH
                        radius: 12
                        samples: 24
                        color: osdRoot.isMuted ? Config.textMuted : Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow !== undefined ? Config.clockShowGlow : true
                    }

                    Canvas {
                        id: waveCanvasH
                        anchors.fill: parent

                        property real animPhase: 0.0
                        readonly property real activeSpan: Math.min(width, width * (osdRoot.animVolume / 100))

                        onActiveSpanChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onAnimPhaseChanged: requestPaint()

                        NumberAnimation on animPhase {
                            running: osdRoot.visible
                            from: 0.0
                            to: Math.PI * 2
                            duration: 3000
                            loops: Animation.Infinite
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)

                            var waveAmplitude = 4.0 
                            var waveFrequency = 0.14 
                            var strokeLineWidth = 6
                            var centerY = height / 2

                            if (waveCanvasH.activeSpan > 0) {
                                ctx.save()
                                ctx.beginPath()
                                for (var x = 0; x <= waveCanvasH.activeSpan; x += 1) {
                                    var y = centerY + Math.sin(x * waveFrequency + waveCanvasH.animPhase) * waveAmplitude
                                    if (x === 0) ctx.moveTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.strokeStyle = osdRoot.isMuted ? Config.textMuted : Config.accent
                                ctx.lineWidth = strokeLineWidth
                                ctx.lineCap = "round"
                                ctx.lineJoin = "round"

                                ctx.stroke()
                                ctx.restore()
                            }

                            if (waveCanvasH.activeSpan < width) {
                                ctx.save()
                                ctx.beginPath()
                                ctx.moveTo(waveCanvasH.activeSpan, centerY)
                                ctx.lineTo(width, centerY)
                                ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.12)
                                ctx.lineWidth = strokeLineWidth
                                ctx.lineCap = "round"
                                ctx.stroke()
                                ctx.restore()
                            }
                        }
                    }

                    Rectangle {
                        id: toggleLine

                        readonly property real baseWidth: 12
                        readonly property real baseHeight: 30

                        property real stretch: 0.0
                        property real popScale: 1.0

                        width: Math.max(8, baseWidth + (stretch * 18))
                        height: Math.max(16, baseHeight - (stretch * 11.67))
                        radius: height / 2
                        color: Config.textMain

                        transform: Scale {
                            origin.x: toggleLine.width / 2
                            origin.y: toggleLine.height / 2
                            xScale: toggleLine.popScale
                            yScale: toggleLine.popScale
                        }

                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, waveCanvasH.activeSpan - (width / 2)))

                        Connections {
                            target: osdRoot
                            function onVolumeChanged() {
                                if (osdRoot.initialized) {
                                    morphAnim.restart()
                                    
                                    // Inline Comment: Re-trigger PCM sample instantly on rapid volume changes
                                    volumeTick.play()
                                }
                            }
                        }

                        SequentialAnimation {
                            id: morphAnim

                            ParallelAnimation {
                                NumberAnimation { target: toggleLine; property: "stretch"; to: 1.2; duration: 120; easing.type: Easing.OutCubic }
                                NumberAnimation { target: toggleLine; property: "popScale"; to: 1.0; duration: 120; easing.type: Easing.OutCubic }
                            }

                            ParallelAnimation {
                                NumberAnimation { target: toggleLine; property: "stretch"; to: -0.4; duration: 100; easing.type: Easing.OutQuad }
                                NumberAnimation { target: toggleLine; property: "popScale"; to: 1.25; duration: 100; easing.type: Easing.OutBack }
                            }

                            ParallelAnimation {
                                NumberAnimation { target: toggleLine; property: "stretch"; to: 0.0; duration: 250; easing.type: Easing.OutBack }
                                NumberAnimation { target: toggleLine; property: "popScale"; to: 1.0; duration: 250; easing.type: Easing.OutBack }
                            }
                        }
                    }
                }

                Text {
                    text: osdRoot.isMuted ? "Muted" : Math.max(0, osdRoot.volume) + "%"
                    color: osdRoot.isMuted ? Config.textMuted : Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontSubhead)
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 48
                }
            }
        }
    }
}