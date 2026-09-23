import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import ".."

Rectangle {
    id: root

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    Layout.fillWidth: true
    Layout.preferredWidth: parent ? parent.width : 356
    implicitHeight: sliderLayout.implicitHeight + (cardMargin * 2)
    radius: Config.cornerRadius
    color: cardHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
    border.width: 1
    border.color: Qt.rgba(255, 255, 255, 0.1)
    clip: true

    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }

    // GRAPHIC WATERMARK
    Watermark {
        icon: "tune"
        iconSize: 150
        baseRotation: -15
        seed: 2
    }

    // --- BRIGHTNESS PROPERTIES ---
    property int currentBrightness: 100
    property bool hasBacklight: false
    signal brightnessChanged(int pct)

    // --- VOLUME PROPERTIES ---
    property int currentVolume: 50
    property bool isAudioMuted: false
    property bool isUserDraggingVol: false
    property real localRatio: 0.0
    signal volumeChanged(int pct)

    HoverHandler { id: cardHover }

    ColumnLayout {
        id: sliderLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.cardMargin
        spacing: 12

        // ==========================================
        // SECTION 1: BRIGHTNESS SLIDER
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            opacity: root.hasBacklight ? 1.0 : 0.45

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Brightness"
                    font.family: Config.sysFont
                    // Inline Comment: Restored title size back to fontCaption
                    font.pixelSize: Config.size(Config.fontCaption)
                    font.bold: true
                    color: Config.textMain
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.hasBacklight ? (root.currentBrightness + "%") : "Unavailable"
                    font.family: Config.sysFont
                    // Inline Comment: Restored readout percentage back to fontMicro
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                    color: root.hasBacklight ? Config.textMain : Config.textMuted
                }
            }

            // Brightness Track Container
            Item {
                Layout.fillWidth: true
                implicitHeight: 40

                RectangularGlow {
                    id: activeBrightGlow
                    anchors.fill: brightFillContainer
                    glowRadius: 8
                    spread: 0.2
                    color: Config.accent
                    cornerRadius: brightTrack.radius
                    opacity: (brightHover.hovered || brightDrag.active) && root.hasBacklight && brightFillContainer.width > 0 ? 0.5 : 0.0

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Item {
                    id: brightFillContainer
                    x: brightTrack.x
                    y: brightTrack.y
                    height: brightTrack.height

                    width: (root.hasBacklight && root.currentBrightness > 0) 
                        ? Math.max(height, brightTrack.width * (root.currentBrightness / 100.0)) 
                        : 0

                    Behavior on width {
                        enabled: !brightDrag.active
                        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                    }
                }

                Rectangle {
                    id: brightTrack
                    anchors.fill: parent
                    radius: Config.cornerRadius / 1.5
                    color: Qt.rgba(0, 0, 0, 0.35)
                    clip: true

                    Rectangle {
                        id: brightFill
                        width: brightFillContainer.width
                        height: parent.height
                        radius: Config.cornerRadius / 1.5
                        color: Config.accent
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "brightness_6"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: root.hasBacklight ? Config.bgBase : Config.textMuted
                    }

                    DragHandler {
                        id: brightDrag
                        target: null
                        enabled: root.hasBacklight
                        onTranslationChanged: {
                            if (active && root.hasBacklight) {
                                let localX = brightDrag.centroid.position.x
                                let pct = Math.max(1, Math.min(100, Math.round((localX / brightTrack.width) * 100)))
                                
                                if (pct !== root.currentBrightness) {
                                    root.currentBrightness = pct
                                    root.brightnessChanged(pct)
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.hasBacklight
                        cursorShape: root.hasBacklight ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: {
                            let pct = Math.max(1, Math.min(100, Math.round((mouseX / brightTrack.width) * 100)))
                            root.currentBrightness = pct
                            root.brightnessChanged(pct)
                        }
                    }

                    HoverHandler { id: brightHover }
                }
            }
        }

        // ==========================================
        // SECTION 2: VOLUME SLIDER
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Volume"
                    font.family: Config.sysFont
                    // Inline Comment: Restored title size back to fontCaption
                    font.pixelSize: Config.size(Config.fontCaption)
                    font.bold: true
                    color: Config.textMain
                }

                Item { Layout.fillWidth: true }

                Text {
                    readonly property int displayVol: root.isUserDraggingVol 
                        ? Math.round(root.localRatio * 100) 
                        : root.currentVolume

                    text: root.isAudioMuted ? "MUTED" : (displayVol < 0 ? "---" : displayVol + "%")
                    font.family: Config.sysFont
                    // Inline Comment: Restored readout percentage back to fontMicro
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                    color: root.isAudioMuted ? Config.textMuted : Config.textMain
                }
            }

            // Volume Track Container
            Item {
                Layout.fillWidth: true
                implicitHeight: 40

                RectangularGlow {
                    id: activeVolGlow
                    anchors.fill: volFillContainer
                    glowRadius: 8
                    spread: 0.2
                    color: Config.accent
                    cornerRadius: volTrack.radius
                    opacity: (volHover.hovered || root.isUserDraggingVol) && !root.isAudioMuted && volFillContainer.width > 0 ? 0.5 : 0.0

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Item {
                    id: volFillContainer
                    x: volTrack.x
                    y: volTrack.y
                    height: volTrack.height

                    readonly property real targetRatio: root.isUserDraggingVol 
                        ? root.localRatio 
                        : (root.currentVolume / 100.0)

                    width: (root.isAudioMuted || targetRatio <= 0) 
                        ? 0 
                        : Math.max(height, volTrack.width * Math.min(1.0, targetRatio))

                    Behavior on width {
                        enabled: !root.isUserDraggingVol && !volArea.pressed && root.currentVolume >= 0
                        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                    }
                }

                Rectangle {
                    id: volTrack
                    anchors.fill: parent
                    radius: Config.cornerRadius / 1.5
                    color: Qt.rgba(0, 0, 0, 0.35)
                    clip: true

                    Rectangle {
                        id: volFill
                        width: volFillContainer.width
                        height: parent.height
                        radius: Config.cornerRadius / 1.5
                        color: Config.accent
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property int activeVol: root.isUserDraggingVol 
                            ? Math.round(root.localRatio * 100) 
                            : root.currentVolume

                        text: root.isAudioMuted ? "volume_off" : (activeVol <= 0 ? "volume_mute" : (activeVol < 50 ? "volume_down" : "volume_up"))
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: (!root.isAudioMuted && activeVol > 10) ? Config.bgBase : Config.textMain
                    }

                    MouseArea {
                        id: volArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true

                        function applyDrag(mouseXPos) {
                            let trackW = volTrack.width
                            if (trackW <= 0) return

                            let ratio = Math.max(0.0, Math.min(1.0, mouseXPos / trackW))
                            root.localRatio = ratio
                            
                            let pct = Math.round(ratio * 100)
                            if (pct !== root.currentVolume) {
                                root.volumeChanged(pct)
                            }
                        }

                        onPressed: mouse => {
                            root.isUserDraggingVol = true
                            applyDrag(mouse.x)
                        }

                        onPositionChanged: mouse => {
                            if (pressed) {
                                applyDrag(mouse.x)
                            }
                        }

                        onReleased: root.isUserDraggingVol = false
                        onCanceled: root.isUserDraggingVol = false
                    }

                    HoverHandler { id: volHover }
                }
            }
        }
    }
}