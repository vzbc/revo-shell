import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: cardRoot

    readonly property bool isStopped: mediaStatus === "Stopped" || mediaTitle === "Not Playing" || mediaTitle === ""

    Layout.fillWidth: true
    implicitHeight: mediaContainer.implicitHeight
    Layout.preferredHeight: implicitHeight

    property Item controlCenterPanel: null

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    property string mediaTitle: "Not Playing"
    property string mediaArtist: "---"
    property string mediaStatus: "Stopped"
    property string mediaArtUrl: ""
    property var cavaBars: []

    // Progress State
    property double trackPosition: 0
    property double trackLength: 0
    property string activePlayerName: ""

    signal sendCommand(var cmd)

    // Position Poller
    Process {
        id: mediaPosProc
        command: ["fish", "-c", "playerctl position; playerctl metadata mpris:length; playerctl metadata --format '{{playerName}}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 1 && lines[0] !== "") {
                    let pos = parseFloat(lines[0]);
                    if (!isNaN(pos)) cardRoot.trackPosition = pos;
                }
                if (lines.length >= 2 && lines[1] !== "") {
                    let len = parseFloat(lines[1]);
                    if (!isNaN(len)) cardRoot.trackLength = len / 1000000.0;
                }
                if (lines.length >= 3 && lines[2].trim() !== "") {
                    cardRoot.activePlayerName = lines[2].trim();
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: Config.showControlCenter && cardRoot.mediaStatus === "Playing"
        repeat: true
        triggeredOnStart: true
        onTriggered: mediaPosProc.running = true
    }

    function formatTime(sec) {
        if (isNaN(sec) || sec <= 0) return "0:00";
        let m = Math.floor(sec / 60);
        let s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function seekRelative(offsetSec) {
        let sign = offsetSec >= 0 ? "+" : "-";
        let val = Math.abs(offsetSec);
        sendCommand(["playerctl", "position", `${val}${sign}`]);
        cardRoot.trackPosition = Math.max(0, cardRoot.trackPosition + offsetSec);
    }

    Rectangle {
        id: mediaContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: cardRoot.isStopped ? 48 : (contentCluster.implicitHeight + (cardRoot.cardMargin * 2))
        radius: Config.cornerRadius
        clip: true

        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        color: cardHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.1)

        HoverHandler { id: cardHover }

        Watermark {
            icon: Config.getIcon("cc")
            iconSize: cardRoot.isStopped ? 60 : 150
            seed: 1
        }

        // ==========================================
        // 1. MINIMAL COMPACT BAR (WHEN STOPPED)
        // ==========================================
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            visible: cardRoot.isStopped
            opacity: cardRoot.isStopped ? 1.0 : 0.0
            spacing: 12
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                text: "music_off"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: Config.textMuted
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "No Media Playing"
                color: Config.textMuted
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontCaption)
                font.bold: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Standby Play Trigger
            Item {
                implicitWidth: 32
                implicitHeight: 32
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "play_arrow"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 22
                    color: idlePlayHover.hovered ? Config.accent : Config.textMuted
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                TapHandler { onTapped: cardRoot.sendCommand(["playerctl", "play-pause"]) }
                HoverHandler { id: idlePlayHover; cursorShape: Qt.PointingHandCursor }
            }
        }

        // ==========================================
        // 2. ACTIVE MEDIA VIEW (WHEN PLAYING / PAUSED)
        // ==========================================
        RowLayout {
            id: contentCluster
            anchors.centerIn: parent
            width: Math.min(parent.width - (cardRoot.cardMargin * 2), 620)
            spacing: 24
            visible: !cardRoot.isStopped
            opacity: !cardRoot.isStopped ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            // --- CIRCULAR VISUALIZER & ART ---
            Item {
                id: artContainer
                implicitWidth: 130
                implicitHeight: 130
                Layout.alignment: Qt.AlignVCenter

                Canvas {
                    id: visualizerCanvas
                    anchors.fill: parent
                    antialiasing: true

                    readonly property bool isVisualizerActive: cardRoot.visible 
                        && cardRoot.mediaStatus === "Playing"

                    property real rotationAngle: 0.0

                    PropertyAnimation on rotationAngle {
                        from: 0.0
                        to: 2 * Math.PI
                        duration: 20000
                        loops: Animation.Infinite
                        running: visualizerCanvas.isVisualizerActive
                    }

                    onRotationAngleChanged: if (isVisualizerActive) requestPaint()
                    onWidthChanged: if (isVisualizerActive) requestPaint()
                    onHeightChanged: if (isVisualizerActive) requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        if (!visualizerCanvas.isVisualizerActive || !cardRoot.cavaBars || cardRoot.cavaBars.length === 0) return;

                        var centerX = width / 2;
                        var centerY = height / 2;
                        var innerRadius = 46;
                        var barCount = cardRoot.cavaBars.length;
                        var maxBarLength = 14;
                        var barWidth = 2.5;

                        ctx.save();
                        ctx.fillStyle = Config.accent;

                        for (var i = 0; i < barCount; i++) {
                            var angle = ((i * 2 * Math.PI) / barCount) + visualizerCanvas.rotationAngle;
                            var value = cardRoot.cavaBars[i] / 255.0;
                            var barLength = value * maxBarLength;

                            ctx.save();
                            ctx.translate(centerX, centerY);
                            ctx.rotate(angle);

                            var startY = innerRadius + 2;
                            var endY = startY + barLength;

                            var baseRadius = barWidth / 2;
                            var tipRadius = baseRadius + (value * 1.2);

                            ctx.beginPath();
                            ctx.moveTo(-baseRadius, startY);
                            ctx.lineTo(-tipRadius, endY);
                            ctx.arc(0, endY, tipRadius, Math.PI, 0, true);
                            ctx.lineTo(baseRadius, startY);
                            ctx.closePath();
                            ctx.fill();

                            ctx.restore();
                        }
                        ctx.restore();
                    }

                    Connections {
                        target: cardRoot
                        function onCavaBarsChanged() {
                            if (visualizerCanvas.isVisualizerActive) {
                                visualizerCanvas.requestPaint();
                            }
                        }
                    }
                }

                Item {
                    width: 88
                    height: 88
                    anchors.centerIn: parent

                    Image {
                        id: artImage
                        anchors.fill: parent
                        source: cardRoot.mediaArtUrl ? cardRoot.mediaArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    Rectangle {
                        id: maskTarget
                        anchors.fill: parent
                        radius: width / 2
                        color: "black"
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: artImage
                        maskSource: maskTarget
                        visible: artImage.status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 34
                        color: Config.textMuted
                        visible: artImage.status !== Image.Ready
                    }
                }
            }

            // --- METADATA, PROGRESS & CONTROLS ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                // Track Info & Player Source
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Item { Layout.fillWidth: true }

                        Text {
                            id: titleText
                            text: cardRoot.mediaTitle
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.maximumWidth: 320
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // Player Source Badge
                        Rectangle {
                            implicitWidth: playerBadgeText.implicitWidth + 10
                            implicitHeight: 16
                            radius: 8
                            color: Qt.rgba(255, 255, 255, 0.08)
                            visible: cardRoot.activePlayerName !== ""

                            Text {
                                id: playerBadgeText
                                anchors.centerIn: parent
                                text: cardRoot.activePlayerName.toUpperCase()
                                color: Config.accent
                                font.family: Config.sysFont
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        id: artistText
                        text: cardRoot.mediaArtist
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Progress Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: cardRoot.trackLength > 0

                    Text {
                        text: cardRoot.formatTime(cardRoot.trackPosition)
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        color: Config.textMuted
                    }

                    Rectangle {
                        id: progressBarTrack
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: Qt.rgba(255, 255, 255, 0.1)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: (cardRoot.trackLength > 0) ? Math.min(parent.width, parent.width * (cardRoot.trackPosition / cardRoot.trackLength)) : 0
                            radius: 2
                            color: Config.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (cardRoot.trackLength > 0) {
                                    let targetSec = (mouse.x / width) * cardRoot.trackLength;
                                    cardRoot.sendCommand(["playerctl", "position", targetSec.toFixed(2)]);
                                    cardRoot.trackPosition = targetSec;
                                }
                            }
                        }
                    }

                    Text {
                        text: cardRoot.formatTime(cardRoot.trackLength)
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        color: Config.textMuted
                    }
                }

                // Transport Controls with 10s Replay / Forward
                RowLayout {
                    spacing: 16
                    Layout.alignment: Qt.AlignHCenter

                    // Replay 10s
                    Item {
                        implicitWidth: 26
                        implicitHeight: 26
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "replay_10"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: replayHover.hovered ? Config.accent : Config.textMuted
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TapHandler { onTapped: cardRoot.seekRelative(-10) }
                        HoverHandler { id: replayHover; cursorShape: Qt.PointingHandCursor }
                    }

                    // Previous
                    Item {
                        implicitWidth: 28
                        implicitHeight: 28
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "skip_previous"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 24
                            color: prevHover.hovered ? Config.accent : Config.textMain
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TapHandler { onTapped: cardRoot.sendCommand(["playerctl", "previous"]) }
                        HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                    }

                    // Play / Pause
                    Item {
                        implicitWidth: 38
                        implicitHeight: 38
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: cardRoot.mediaStatus === "Playing" ? "pause_circle" : "play_circle"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 36
                            color: playHover.hovered ? Config.textMain : Config.accent
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TapHandler { onTapped: cardRoot.sendCommand(["playerctl", "play-pause"]) }
                        HoverHandler { id: playHover; cursorShape: Qt.PointingHandCursor }
                    }

                    // Next
                    Item {
                        implicitWidth: 28
                        implicitHeight: 28
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "skip_next"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 24
                            color: nextHover.hovered ? Config.accent : Config.textMain
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TapHandler { onTapped: cardRoot.sendCommand(["playerctl", "next"]) }
                        HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                    }

                    // Forward 10s
                    Item {
                        implicitWidth: 26
                        implicitHeight: 26
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "forward_10"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: forwardHover.hovered ? Config.accent : Config.textMuted
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TapHandler { onTapped: cardRoot.seekRelative(10) }
                        HoverHandler { id: forwardHover; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }
    }
}