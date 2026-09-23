pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Services.Mpris
import "../../"

Rectangle {
    id: mprisroot

    required property MprisPlayer player
    required property real discScale
    property bool popupVisible: false
    readonly property color colOverlay: Colors.withAlpha(Colors.bg, 0.70)
    readonly property color colSeekKnob: Colors.accent
    property real _discAngle: 0

    // Cache art URL per-track: clear on title change (shows fallback vinyl
    // while the new thumbnail downloads), latch on non-empty URL so Firefox's
    // habit of immediately clearing artUrl doesn't drop the disc.
    property string _artUrl: ""

    property int _toggleCount: 0
    property var _now: new Date()
    property bool _is4AM: {
        var h = mprisroot._now.getHours();
        return h >= 3 && h < 5;
    }

    readonly property bool _isPlaying: player.playbackState === MprisPlaybackState.Playing

    Component.onCompleted: {
        if (player.trackArtUrl !== "")
            _artUrl = player.trackArtUrl;
    }

    Connections {
        target: mprisroot.player
        function onTrackTitleChanged() {
            mprisroot._artUrl = "";
            mprisroot._toggleCount = 0;
        }
        function onTrackArtUrlChanged() {
            if (mprisroot.player.trackArtUrl !== "")
                mprisroot._artUrl = mprisroot.player.trackArtUrl;
        }
        function onPlaybackStateChanged() {
            var s = mprisroot.player.playbackState;
            if (s === MprisPlaybackState.Playing || s === MprisPlaybackState.Paused) {
                mprisroot._toggleCount++;
                toggleResetTimer.restart();
            }
        }
    }

    Timer {
        id: toggleResetTimer
        interval: 60000
        onTriggered: mprisroot._toggleCount = 0
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: mprisroot._now = new Date()
    }

    // 30fps driver for disc rotation + seeker position
    Timer {
        interval: 33
        repeat: true
        running: mprisroot._isPlaying && mprisroot.popupVisible
        onTriggered: {
            mprisroot._discAngle = (mprisroot._discAngle + interval * 6.0 / 1000.0) % 360;
            mprisroot.player.positionChanged();
        }
    }

    radius: Math.round(20 * UIScale.value)
    topLeftRadius: 0
    topRightRadius: 0
    clip: true
    color: Colors.bg

    Rectangle {
        id: _cornerMask
        anchors.fill: parent
        radius: mprisroot.radius
        topLeftRadius: 0
        topRightRadius: 0
        visible: false
        layer.enabled: true
    }

    // Blurred album art background + overlay, masked to rounded corners
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            maskSource: _cornerMask
        }

        Image {
            anchors.fill: parent
            source: mprisroot._artUrl
            fillMode: Image.PreserveAspectCrop
            retainWhileLoading: true
            opacity: 0.75
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 48
                saturation: 0.15
            }
        }

        Rectangle {
            anchors.fill: parent
            color: mprisroot.colOverlay
        }
    }

    // Teto
    Item {
        anchors.fill: parent
        clip: true
        visible: mprisroot.player.trackTitle.toLowerCase().includes("teto") || mprisroot.player.trackArtist.toLowerCase().includes("teto")
        rotation: -20

        Column {
            anchors.centerIn: parent
            width: parent.width * 2
            spacing: Math.round(14 * UIScale.value)

            Repeater {
                model: 40
                Text {
                    required property int index
                    width: parent.width
                    text: "TETOTETOTETOTETOTETOTETOTETOTETOTETOTETO"
                    color: Qt.rgba(1, 1, 1, 0.07)
                    font.pixelSize: Math.round(22 * UIScale.value)
                    font.weight: Font.Bold
                    font.family: "monospace"
                    font.letterSpacing: 2
                }
            }
        }
    }

    // Fallback vinyl, always underneath as base
    Item {
        id: vinylBase
        anchors.verticalCenter: mprisroot.bottom
        anchors.horizontalCenter: mprisroot.horizontalCenter
        width: parent.width * mprisroot.discScale
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.surface
        }
        Repeater {
            model: [0.88, 0.76, 0.63, 0.50]
            Rectangle {
                required property real modelData
                anchors.centerIn: parent
                width: parent.width * modelData
                height: width
                radius: width / 2
                color: "transparent"
                border.color: Colors.withAlpha(Colors.accent, 0.10)
                border.width: 2
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.22
            height: width
            radius: width / 2
            color: Colors.bg
        }
    }

    // Spinning album art
    Item {
        id: spinWrapper
        anchors.verticalCenter: mprisroot.bottom
        anchors.horizontalCenter: mprisroot.horizontalCenter
        width: parent.width * mprisroot.discScale
        height: width
        rotation: mprisroot._discAngle

        Image {
            id: albumArt
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: mprisroot._artUrl
            retainWhileLoading: true
            cache: false
            layer.enabled: true
            layer.smooth: true

            layer.effect: MultiEffect {
                antialiasing: true
                maskEnabled: true
                maskSpreadAtMin: 1.0
                maskThresholdMax: 1.0
                maskThresholdMin: 0.5
                maskSource: Image {
                    layer.smooth: true
                    mipmap: true
                    smooth: true
                    source: "../../assets/AlbumCover.svg"
                }
            }
        }
    }

    // Circular seeker
    Item {
        id: circularSeeker
        width: parent.width
        height: parent.width
        anchors.verticalCenter: mprisroot.bottom
        anchors.horizontalCenter: mprisroot.horizontalCenter

        readonly property real startAngle: 190
        readonly property real sweepAngle: 160
        readonly property real radius: (parent.width / 2) * mprisroot.discScale

        readonly property real internalAngle: (mprisroot.player.position / mprisroot.player.length) * sweepAngle
        property bool userIsDragging: false
        property real _manualAngle: 0
        property real displayedAngle: userIsDragging ? _manualAngle : internalAngle

        Shape {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                strokeWidth: Math.round(10 * UIScale.value)
                strokeColor: Colors.withAlpha(Colors.accent, 0.22)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: circularSeeker.width / 2
                    centerY: circularSeeker.height / 2
                    radiusX: circularSeeker.radius
                    radiusY: circularSeeker.radius
                    startAngle: circularSeeker.startAngle
                    sweepAngle: circularSeeker.sweepAngle
                }
            }
            ShapePath {
                strokeWidth: Math.round(10 * UIScale.value)
                strokeColor: Colors.accent
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: circularSeeker.width / 2
                    centerY: circularSeeker.height / 2
                    radiusX: circularSeeker.radius
                    radiusY: circularSeeker.radius
                    startAngle: circularSeeker.startAngle
                    sweepAngle: circularSeeker.displayedAngle
                }
            }
        }

        Rectangle {
            width: Math.round(14 * UIScale.value)
            height: Math.round(14 * UIScale.value)
            radius: Math.round(7 * UIScale.value)
            antialiasing: true
            color: mprisroot.colSeekKnob
            x: circularSeeker.width / 2 + circularSeeker.radius * Math.cos((circularSeeker.startAngle + circularSeeker.displayedAngle) * Math.PI / 180) - width / 2
            y: circularSeeker.height / 2 + circularSeeker.radius * Math.sin((circularSeeker.startAngle + circularSeeker.displayedAngle) * Math.PI / 180) - height / 2
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onPressed: mevent => {
                if (!circularSeeker.userIsDragging) {
                    const dx = mevent.x - width / 2;
                    const dy = mevent.y - height / 2;
                    const distance = Math.sqrt(dx ** 2 + dy ** 2);
                    const hitOffset = Math.round(12 * UIScale.value);
                    const innerRadius = circularSeeker.radius - hitOffset;
                    const outerRadius = circularSeeker.radius + hitOffset;
                    if (distance >= innerRadius && distance <= outerRadius) {
                        circularSeeker.userIsDragging = true;
                        updateAngle(mevent.x, mevent.y);
                    }
                    if (distance <= innerRadius)
                        mprisroot.player.togglePlaying();
                }
            }
            onReleased: Qt.callLater(() => circularSeeker.userIsDragging = false)
            onPositionChanged: mevent => {
                if (circularSeeker.userIsDragging)
                    updateAngle(mevent.x, mevent.y);
            }

            function updateAngle(x, y) {
                const dx = x - width / 2;
                const dy = y - height / 2;
                let theta = Math.atan2(dy, dx) * 180 / Math.PI;
                if (theta < 0)
                    theta += 360;
                const start = circularSeeker.startAngle;
                const end = (start + circularSeeker.sweepAngle) % 360;
                const inArc = (start < end) ? (theta >= start && theta <= end) : (theta >= start || theta <= end);
                if (inArc) {
                    let newAngle = theta - start;
                    if (newAngle < 0)
                        newAngle += 360;
                    circularSeeker._manualAngle = newAngle;
                    mprisroot.player.position = mprisroot.player.length * (newAngle / circularSeeker.sweepAngle);
                }
            }
        }
    }

    // Track info
    Column {
        anchors.top: parent.top
        anchors.topMargin: Math.round(16 * UIScale.value)
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Math.round(100 * UIScale.value)
        spacing: Math.round(5 * UIScale.value)

        Text {
            text: mprisroot.player.trackTitle
            width: parent.width
            color: Colors.text
            font.bold: true
            font.pixelSize: UIScale.fontLead
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            text: {
                if (mprisroot._is4AM)
                    return I18n.t("music.cantSleep");
                if (mprisroot._toggleCount >= 8)
                    return I18n.t("music.makeUpYourMind");
                return mprisroot.player.trackArtist;
            }
            width: parent.width
            color: Colors.muted
            font.bold: true
            font.pixelSize: UIScale.fontSmall
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Previous
    Item {
        anchors.left: parent.left
        anchors.leftMargin: Math.round(18 * UIScale.value)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Math.round(-22 * UIScale.value)
        width: Math.round(36 * UIScale.value)
        height: Math.round(36 * UIScale.value)

        Text {
            anchors.centerIn: parent
            text: "⏮"
            font.pixelSize: Math.round(22 * UIScale.value)
            color: prevArea.containsMouse ? Colors.accent : Colors.muted
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }
        MouseArea {
            id: prevArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mprisroot.player.previous()
        }
    }

    // Next
    Item {
        anchors.right: parent.right
        anchors.rightMargin: Math.round(18 * UIScale.value)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Math.round(-22 * UIScale.value)
        width: Math.round(36 * UIScale.value)
        height: Math.round(36 * UIScale.value)

        Text {
            anchors.centerIn: parent
            text: "⏭"
            font.pixelSize: Math.round(22 * UIScale.value)
            color: nextArea.containsMouse ? Colors.accent : Colors.muted
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }
        MouseArea {
            id: nextArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mprisroot.player.next()
        }
    }
}
