import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia
import Qt.labs.platform
import Quickshell
import ".."

Item {
    id: mirrorRoot
    focus: true

    Keys.onLeftPressed: (event) => { anchorControls.cycleAnchor(anchorControls.isHorizontal ? "left" : "up"); event.accepted = true }
    Keys.onUpPressed: (event) => { anchorControls.cycleAnchor(anchorControls.isHorizontal ? "left" : "up"); event.accepted = true }
    Keys.onRightPressed: (event) => { anchorControls.cycleAnchor(anchorControls.isHorizontal ? "right" : "down"); event.accepted = true }
    Keys.onDownPressed: (event) => { anchorControls.cycleAnchor(anchorControls.isHorizontal ? "right" : "down"); event.accepted = true }

    implicitWidth: Config.mirrorExpanded ? 640 : 380
    implicitHeight: mainColumn.implicitHeight + (Config.cardMargin * 2)

    function takeSnapshot() {
        let timestamp = Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmss")
        let picturesDir = StandardPaths.writableLocation(StandardPaths.PicturesLocation).toString().replace(/^file:\/\//, "")
        let targetPath = `${picturesDir}/mirror_snap_${timestamp}.png`

        flashAnimation.restart()

        videoWrapper.grabToImage(function(result) {
            if (result.saveToFile(targetPath)) {
                console.log("Snapshot saved to:", targetPath)
            } else {
                console.warn("Failed to save snapshot to:", targetPath)
            }
        })
    }

    // Attach localOutput to the global Config session dynamically
    function attachSession() {
        if (Config.mirrorCaptureSession) {
            Config.mirrorCaptureSession.videoOutput = localOutput
            if (Config.mirrorCaptureSession.camera) {
                Config.mirrorCaptureSession.camera.active = mirrorRoot.visible && Config.showMirror
            }
            if (typeof Config.mirrorLoading !== "undefined") {
                Config.mirrorLoading = false
                Config.mirrorError = ""
            }
        }
    }

    onVisibleChanged: {
        if (visible) attachSession()
    }

    Connections {
        target: Config
        ignoreUnknownSignals: true
        function onMirrorCaptureSessionChanged() {
            mirrorRoot.attachSession()
        }
        function onShowMirrorChanged() {
            if (Config.mirrorCaptureSession && Config.mirrorCaptureSession.camera) {
                Config.mirrorCaptureSession.camera.active = Config.showMirror
            }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: Config.cardMargin
        spacing: Config.cardMargin / 2

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: cardLayout.implicitHeight + (Config.cardMargin * 2)
            color: Qt.rgba(255, 255, 255, 0.05)
            radius: Config.cornerRadius
            clip: true

            // GRAPHIC WATERMARK
            Watermark {
                icon: Config.getIcon("mirror")
                iconSize: 150
                seed: 28
            }

            ColumnLayout {
                id: cardLayout
                anchors.fill: parent
                anchors.margins: Config.cardMargin
                spacing: 12

                // HEADER
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item {
                        implicitWidth: mirrorTitleText.implicitWidth
                        implicitHeight: mirrorTitleText.implicitHeight
                        Layout.fillWidth: true

                        Glow {
                            anchors.fill: mirrorTitleText
                            source: mirrorTitleText
                            radius: 8
                            samples: 16
                            color: Config.accent
                            spread: 0.2
                            transparentBorder: true
                            visible: Config.clockShowGlow && mirrorRoot.visible && (typeof mainSurface !== "undefined" ? mainSurface.progress >= 0.95 : true)
                        }

                        Text {
                            id: mirrorTitleText
                            anchors.fill: parent
                            text: "MIRROR"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                            elide: Text.ElideRight
                        }
                    }

                    // DYNAMIC ORIENTATION ANCHOR ARROWS
                    GridLayout {
                        id: anchorControls
                        columns: isHorizontal ? 2 : 1
                        rows: isHorizontal ? 1 : 2
                        columnSpacing: 4
                        rowSpacing: 4
                        Layout.alignment: Qt.AlignVCenter

                        readonly property bool isHorizontal: {
                            if (typeof Config.isHorizontal !== "undefined") return !!Config.isHorizontal;
                            if (typeof Config.barPosition !== "undefined") return Config.barPosition === "top" || Config.barPosition === "bottom";
                            if (typeof Config.isBarHorizontal !== "undefined") return !!Config.isBarHorizontal;
                            if (typeof Config.orientation !== "undefined") return Config.orientation === Qt.Horizontal || Config.orientation === "horizontal";
                            return Config.barPosition !== "left" && Config.barPosition !== "right";
                        }

                        function cycleAnchor(direction) {
                            if (typeof Config.cycleMirrorAnchor === "function") {
                                Config.cycleMirrorAnchor(direction);
                            }
                        }

                        // LEFT / UP ARROW
                        Rectangle {
                            implicitWidth: 20; implicitHeight: 20; radius: 10
                            color: prevHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: anchorControls.isHorizontal ? "keyboard_arrow_left" : "keyboard_arrow_up"
                                color: (Config.mirrorAnchorPos === "top")
                                    ? Config.accent 
                                    : (prevHover.hovered ? Config.textMain : Config.textMuted)
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 20
                                font.bold: true
                            }

                            TapHandler { onTapped: anchorControls.cycleAnchor(anchorControls.isHorizontal ? "left" : "up") }
                            HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                        }

                        // RIGHT / DOWN ARROW
                        Rectangle {
                            implicitWidth: 20; implicitHeight: 20; radius: 10
                            color: nextHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: anchorControls.isHorizontal ? "keyboard_arrow_right" : "keyboard_arrow_down"
                                color: (Config.mirrorAnchorPos === "bottom")
                                    ? Config.accent 
                                    : (nextHover.hovered ? Config.textMain : Config.textMuted)
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 20
                                font.bold: true
                            }

                            TapHandler { onTapped: anchorControls.cycleAnchor(anchorControls.isHorizontal ? "right" : "down") }
                            HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }

                    // ASPECT / CROP TOGGLE BUTTON
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: 13
                        color: cropBtnHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: Config.mirrorKeepAspect ? "crop" : "crop_free"
                            color: Config.mirrorKeepAspect ? Config.accent : Config.textMuted
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        TapHandler { onTapped: Config.mirrorKeepAspect = !Config.mirrorKeepAspect }
                        HoverHandler { id: cropBtnHover; cursorShape: Qt.PointingHandCursor }
                    }

                    // CANVAS EXPAND BUTTON (2X SIZE TOGGLE)
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: 13
                        color: expandBtnHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: Config.mirrorExpanded ? "fit_screen" : "aspect_ratio"
                            color: Config.mirrorExpanded ? Config.accent : Config.textMuted
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        TapHandler { onTapped: Config.mirrorExpanded = !Config.mirrorExpanded }
                        HoverHandler { id: expandBtnHover; cursorShape: Qt.PointingHandCursor }
                    }

                    // PIN PANEL BUTTON
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: 13
                        color: pinBtnHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "push_pin"
                            color: Config.mirrorPinned ? Config.accent : Config.textMuted
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            font.bold: true
                            rotation: Config.mirrorPinned ? 45 : 0

                            Behavior on rotation {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        TapHandler { onTapped: Config.mirrorPinned = !Config.mirrorPinned }
                        HoverHandler { id: pinBtnHover; cursorShape: Qt.PointingHandCursor }
                    }

                    // CLOSE BUTTON
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: 13
                        color: closeBtnHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            color: Config.textMuted
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        TapHandler { onTapped: Config.showMirror = false }
                        HoverHandler { id: closeBtnHover; cursorShape: Qt.PointingHandCursor }
                    }
                }

                // CAMERA DISPLAY CANVAS
                Rectangle {
                    id: cameraCanvas
                    Layout.fillWidth: true
                    implicitHeight: Config.mirrorExpanded ? 440 : 250
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.width: Config.showBorders ? Config.borderThickness : 0
                    border.color: (typeof shellRoot !== "undefined" && shellRoot.currentBorderColor) ? shellRoot.currentBorderColor : Config.accent
                    clip: true

                    Item {
                        id: videoWrapper
                        anchors.fill: parent
                        anchors.margins: Config.showBorders ? Config.borderThickness : 0
                        clip: true

                        VideoOutput {
                            id: localOutput
                            anchors.fill: parent
                            fillMode: Config.mirrorKeepAspect ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit
                            visible: true

                            transform: Scale {
                                origin.x: localOutput.width / 2
                                xScale: Config.mirrorMirrored ? 1 : -1
                            }

                            Component.onCompleted: {
                                mirrorRoot.attachSession()
                            }
                            Component.onDestruction: {
                                if (Config.mirrorCaptureSession && Config.mirrorCaptureSession.videoOutput === localOutput) {
                                    Config.mirrorCaptureSession.videoOutput = null
                                }
                            }
                        }
                    }

                    // LOADING / ERROR OVERLAY
                    Rectangle {
                        id: loadingOverlay
                        anchors.fill: videoWrapper
                        color: Qt.rgba(15 / 255, 15 / 255, 18 / 255, 0.92)
                        z: 90
                        radius: Config.cornerRadius / 2
                        visible: opacity > 0
                        opacity: (Config.mirrorLoading || (Config.mirrorError && Config.mirrorError !== "")) ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 40
                                implicitHeight: 40

                                Text {
                                    id: spinnerIcon
                                    anchors.centerIn: parent
                                    text: (Config.mirrorError && Config.mirrorError !== "") ? "videocam_off" : "progress_activity"
                                    color: (Config.mirrorError && Config.mirrorError !== "") ? "#ff5555" : Config.accent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 32
                                    font.bold: true

                                    RotationAnimation on rotation {
                                        from: 0
                                        to: 360
                                        duration: 1100
                                        loops: Animation.Infinite
                                        running: Config.mirrorLoading && (!Config.mirrorError || Config.mirrorError === "")
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: (Config.mirrorError && Config.mirrorError !== "") ? Config.mirrorError : "Loading..."
                                color: (Config.mirrorError && Config.mirrorError !== "") ? "#ff8888" : Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                            }
                        }
                    }

                    // SNAPSHOT FLASH OVERLAY
                    Rectangle {
                        id: flashOverlay
                        anchors.fill: videoWrapper
                        color: "#ffffff"
                        opacity: 0.0
                        z: 99
                        radius: Config.cornerRadius / 2

                        NumberAnimation on opacity {
                            id: flashAnimation
                            running: false
                            from: 0.85
                            to: 0.0
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }

                    // CANVAS OVERLAY CONTROLS
                    RowLayout {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 10
                        spacing: 8
                        z: 100

                        // FLIP HORIZONTAL TOGGLE
                        Rectangle {
                            implicitWidth: 32; implicitHeight: 32; radius: 16
                            color: flipHover.hovered ? Config.accent : Qt.rgba(0, 0, 0, 0.4)
                            opacity: flipHover.hovered ? 1.0 : 0.7

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "flip_camera_android"
                                color: "#ffffff"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 18
                                font.bold: true
                            }

                            TapHandler { onTapped: Config.mirrorMirrored = !Config.mirrorMirrored }
                            HoverHandler { id: flipHover; cursorShape: Qt.PointingHandCursor }
                        }

                        // SNAPSHOT BUTTON
                        Rectangle {
                            implicitWidth: 32; implicitHeight: 32; radius: 16
                            color: snapHover.hovered ? Config.accent : Qt.rgba(0, 0, 0, 0.4)
                            opacity: snapHover.hovered ? 1.0 : 0.7

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "photo_camera"
                                color: "#ffffff"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 18
                                font.bold: true
                            }

                            TapHandler { onTapped: mirrorRoot.takeSnapshot() }
                            HoverHandler { id: snapHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }
        }
    }
}