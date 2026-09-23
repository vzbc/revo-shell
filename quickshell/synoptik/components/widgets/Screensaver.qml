import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

Scope {
    id: screensaverScope

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: screensaverWin
            required property var modelData

            screen: modelData
            visible: Config.showScreensaver

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-screensaver"
            WlrLayershell.keyboardFocus: Config.showScreensaver ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.exclusiveZone: -1

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "#000000"

            // Hide the cursor while the screensaver is active and capture mouse activity
            MouseArea {
                id: screenMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.BlankCursor
                acceptedButtons: Qt.AllButtons

                property real lastX: -1
                property real lastY: -1
                property bool initialized: false

                onPositionChanged: (mouse) => {
                    if (!initialized) {
                        lastX = mouse.x
                        lastY = mouse.y
                        initialized = true
                        return
                    }
                    let dx = Math.abs(mouse.x - lastX)
                    let dy = Math.abs(mouse.y - lastY)
                    // Movement threshold to avoid sensor vibration dismissal
                    if (dx > 12 || dy > 12) {
                        Config.showScreensaver = false
                    }
                }

                onClicked: {
                    Config.showScreensaver = false
                }
                onWheel: (wheel) => {
                    Config.showScreensaver = false
                    wheel.accepted = true
                }
            }

            // Keyboard Focus & Dismiss Trap
            Item {
                id: keyTrap
                anchors.fill: parent
                focus: Config.showScreensaver

                Keys.onPressed: (event) => {
                    Config.showScreensaver = false
                    event.accepted = true
                }

                Connections {
                    target: Config
                    function onShowScreensaverChanged() {
                        if (Config.showScreensaver) {
                            keyTrap.forceActiveFocus()
                            screenMouseArea.initialized = false
                            screensaverContent.resetPhysics()
                        }
                    }
                }
            }

            // Bouncing Content Object
            Item {
                id: screensaverContent

                readonly property var colors: [
                    "#FF0055", // Neon Magenta / Pink
                    "#00F0FF", // Electric Cyan
                    "#FFE600", // Bright Yellow
                    "#00FF66", // Neon Lime Green
                    "#FF6B00", // Vivid Orange
                    "#9D00FF", // Deep Violet
                    "#0088FF", // Vivid Blue
                    "#FF3366", // Coral
                    "#ECEFF4"  // Snow White
                ]

                property int colorIndex: 0
                property color currentColor: colors[colorIndex]

                property real posX: 80
                property real posY: 80
                property real velX: (Config.screensaverSpeed || 3.5)
                property real velY: (Config.screensaverSpeed || 3.5) * 0.82

                property int cornerHits: 0
                property bool isCornerHit: false

                function resetPhysics() {
                    let winW = screensaverWin.width > 0 ? screensaverWin.width : 1920
                    let winH = screensaverWin.height > 0 ? screensaverWin.height : 1080
                    let objW = width > 0 ? width : 200
                    let objH = height > 0 ? height : 100

                    posX = Math.max(20, Math.min(winW - objW - 20, 60 + Math.floor(Math.random() * (winW * 0.4))))
                    posY = Math.max(20, Math.min(winH - objH - 20, 60 + Math.floor(Math.random() * (winH * 0.4))))
                    
                    let speed = Config.screensaverSpeed || 3.5
                    velX = (Math.random() > 0.5 ? 1 : -1) * speed
                    velY = (Math.random() > 0.5 ? 1 : -1) * (speed * 0.82)
                }

                x: posX
                y: posY
                width: logoWrapper.width
                height: logoWrapper.height

                Timer {
                    id: physicsTimer
                    interval: 16 // ~60 FPS
                    running: Config.showScreensaver && screensaverWin.visible
                    repeat: true
                    onTriggered: {
                        let winW = screensaverWin.width
                        let winH = screensaverWin.height
                        let objW = screensaverContent.width
                        let objH = screensaverContent.height

                        if (winW <= 0 || winH <= 0 || objW <= 0 || objH <= 0) return

                        let nextX = screensaverContent.posX + screensaverContent.velX
                        let nextY = screensaverContent.posY + screensaverContent.velY
                        let hitH = false
                        let hitV = false

                        // Horizontal reflection
                        if (nextX + objW >= winW) {
                            screensaverContent.velX = -Math.abs(screensaverContent.velX)
                            nextX = winW - objW
                            hitH = true
                        } else if (nextX <= 0) {
                            screensaverContent.velX = Math.abs(screensaverContent.velX)
                            nextX = 0
                            hitH = true
                        }

                        // Vertical reflection
                        if (nextY + objH >= winH) {
                            screensaverContent.velY = -Math.abs(screensaverContent.velY)
                            nextY = winH - objH
                            hitV = true
                        } else if (nextY <= 0) {
                            screensaverContent.velY = Math.abs(screensaverContent.velY)
                            nextY = 0
                            hitV = true
                        }

                        if (hitH || hitV) {
                            screensaverContent.colorIndex = (screensaverContent.colorIndex + 1) % screensaverContent.colors.length
                            screensaverContent.currentColor = screensaverContent.colors[screensaverContent.colorIndex]
                        }

                        // Corner hit detection
                        if (hitH && hitV) {
                            screensaverContent.cornerHits++
                            screensaverContent.isCornerHit = true
                            cornerFlashTimer.restart()
                        }

                        screensaverContent.posX = nextX
                        screensaverContent.posY = nextY
                    }
                }

                Timer {
                    id: cornerFlashTimer
                    interval: 600
                    repeat: false
                    onTriggered: screensaverContent.isCornerHit = false
                }

                // Rendered Visual Container with Typography
                Item {
                    id: logoWrapper
                    width: contentColumn.implicitWidth + 32
                    height: contentColumn.implicitHeight + 20

                    Column {
                        id: contentColumn
                        anchors.centerIn: parent
                        spacing: 4

                        // --- DVD VIDEO LOGO MODE ---
                        Column {
                            visible: (Config.screensaverMode || "text") === "dvd"
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: -2

                            Text {
                                text: "DVD"
                                font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                font.pixelSize: (Config.screensaverFontSize || 54) * 1.35
                                font.bold: true
                                font.letterSpacing: 4
                                font.italic: true
                                color: screensaverContent.currentColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                style: Text.Raised
                                styleColor: Qt.rgba(0, 0, 0, 0.9)

                                Behavior on color {
                                    ColorAnimation { duration: 160 }
                                }
                            }

                            Rectangle {
                                width: parent.width * 0.96
                                height: 3
                                color: screensaverContent.currentColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: 1.5

                                Behavior on color {
                                    ColorAnimation { duration: 160 }
                                }
                            }

                            Text {
                                text: "V I D E O"
                                font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                font.pixelSize: (Config.screensaverFontSize || 54) * 0.28
                                font.bold: true
                                font.letterSpacing: 6
                                color: screensaverContent.currentColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                topPadding: 4
                                style: Text.Raised
                                styleColor: Qt.rgba(0, 0, 0, 0.9)

                                Behavior on color {
                                    ColorAnimation { duration: 160 }
                                }
                            }
                        }

                        // --- ACTIVATE LINUX MODE ---
                        Column {
                            visible: Config.screensaverMode === "activate" || Config.screensaverMode === "clock"
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3

                            Text {
                                text: "Activate Linux"
                                font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                font.pixelSize: Config.screensaverFontSize || 54
                                font.bold: true
                                font.letterSpacing: 1
                                color: screensaverContent.currentColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                style: Text.Raised
                                styleColor: Qt.rgba(0, 0, 0, 0.9)

                                Behavior on color {
                                    ColorAnimation { duration: 160 }
                                }
                            }

                            Text {
                                text: "Go to Settings to activate Linux"
                                font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                font.pixelSize: (Config.screensaverFontSize || 54) * 0.36
                                font.bold: false
                                font.letterSpacing: 0.5
                                color: Qt.rgba(screensaverContent.currentColor.r, screensaverContent.currentColor.g, screensaverContent.currentColor.b, 0.82)
                                anchors.horizontalCenter: parent.horizontalCenter
                                style: Text.Raised
                                styleColor: Qt.rgba(0, 0, 0, 0.9)

                                Behavior on color {
                                    ColorAnimation { duration: 160 }
                                }
                            }
                        }

                        // --- CUSTOM FLOATING TEXT MODE ---
                        Column {
                            visible: (Config.screensaverMode || "text") === "text"
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: (Config.screensaverText !== undefined && Config.screensaverText !== "") ? Config.screensaverText : "SYNOPTIK"
                                font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                font.pixelSize: Config.screensaverFontSize || 54
                                font.bold: true
                                font.letterSpacing: 4
                                color: screensaverContent.currentColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                style: Text.Raised
                                styleColor: Qt.rgba(0, 0, 0, 0.9)

                                Behavior on color {
                                    ColorAnimation { duration: 160 }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Corner Hit Counter
            Text {
                visible: (Config.screensaverCornerCounter !== false) && screensaverContent.cornerHits > 0
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 24
                text: "Corner Hits: " + screensaverContent.cornerHits
                font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                font.pixelSize: 13
                font.bold: true
                color: screensaverContent.isCornerHit ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.25)

                Behavior on color {
                    ColorAnimation { duration: 250 }
                }
            }
        }
    }
}
