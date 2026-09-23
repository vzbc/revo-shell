import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

PanelWindow {
    id: petWindow
    visible: Config.showMascot && Config.mascotPath !== ""

    Component.onCompleted: {
        let activeName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        let found = Quickshell.screens.find(s => s.name === activeName)
        petWindow.screen = found || Quickshell.screens[0]
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-mascot"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    color: "transparent"
    exclusiveZone: 0 

    mask: Region { item: petContainer }

    function formatFileUrl(path) {
        if (!path) return ""
        if (path.startsWith("file://")) return path
        if (path.startsWith("/")) return "file://" + path
        return "file://" + Quickshell.env("HOME") + "/" + path
    }

    property string currentPhrase: ""
    property bool isTalking: false

    Item {
        id: petContainer
        
        width: 128
        height: character.implicitWidth ? (width * (character.implicitHeight / character.implicitWidth)) : width

        // Backend storage for x/y position
        property real dragX: 0
        property real dragY: 0
        property bool initialized: false

        // Always bind directly to dragX/dragY
        x: dragX
        y: dragY

        // Safely center once the parent window has a non-zero size
        Connections {
            target: petWindow
            function onWidthChanged() { petContainer.initPosition() }
            function onHeightChanged() { petContainer.initPosition() }
        }

        function initPosition() {
            if (!initialized && petWindow.width > 0 && petWindow.height > 0) {
                dragX = Math.max(0, (petWindow.width / 2) - (width / 2))
                dragY = Math.max(0, (petWindow.height / 2) - (height / 2))
                initialized = true
            }
        }

        Component.onCompleted: initPosition()

        onXChanged: checkScreenBoundary()
        onYChanged: checkScreenBoundary()

        function checkScreenBoundary() {
            if (!dragArea.drag.active) return

            let globalX = petWindow.screen.x + petContainer.x
            let globalY = petWindow.screen.y + petContainer.y

            let centerX = globalX + (petContainer.width / 2)
            let centerY = globalY + (petContainer.height / 2)

            for (let i = 0; i < Quickshell.screens.length; i++) {
                let s = Quickshell.screens[i]
                if (s === petWindow.screen) continue

                if (centerX >= s.x && centerX <= (s.x + s.width) &&
                    centerY >= s.y && centerY <= (s.y + s.height)) {
                    
                    let newLocalX = globalX - s.x
                    let newLocalY = globalY - s.y

                    petWindow.screen = s
                    petContainer.dragX = newLocalX
                    petContainer.dragY = newLocalY
                    break
                }
            }
        }

        AnimatedImage {
            id: character
            source: petWindow.formatFileUrl(Config.mascotPath)
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            playing: true

            onStatusChanged: {
                if (status === AnimatedImage.Ready) {
                    playing = true
                }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: petContainer
            drag.axis: Drag.XAndYAxis
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: false
            
            // Sync drag position with properties
            onPositionChanged: {
                if (drag.active) {
                    petContainer.dragX = petContainer.x
                    petContainer.dragY = petContainer.y
                }
            }
            
            onWheel: (wheel) => {
                let step = 16
                if (wheel.angleDelta.y > 0) {
                    petContainer.width += step
                } else {
                    petContainer.width = Math.max(32, petContainer.width - step)
                }
            }
        }

        // --- BARE TEXT OVERLAY (WITH WRAPPING & OUTLINE) ---
        Item {
            id: chatBubble
            visible: isTalking
            
            width: chatText.width
            height: chatText.height

            anchors {
                bottom: character.top
                bottomMargin: 6
                horizontalCenter: character.horizontalCenter
            }

            Text {
                id: chatText
                text: currentPhrase
                anchors.centerIn: parent
                font.bold: true
                
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontBody)
                
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.8)

                wrapMode: Text.WordWrap
                width: Math.min(implicitWidth, 240)
                horizontalAlignment: Text.AlignHCenter

                Component.onCompleted: {
                    Config.fontStyle(font)
                }
            }
        }
    }

    Timer {
        interval: 5000 
        running: Config.showMascot
        repeat: true
        onTriggered: {
            let phrases = Config.mascotPhrases || []
            if (!isTalking && phrases.length > 0 && Math.random() > 0.7) {
                currentPhrase = phrases[Math.floor(Math.random() * phrases.length)]
                isTalking = true
                hideChatTimer.start()
            }
        }
    }

    Timer {
        id: hideChatTimer
        interval: 3500 
        onTriggered: isTalking = false
    }

    Timer {
        interval: 600000 
        running: Config.showMascot && Config.fetchOnlineQuotes
        repeat: true
        onTriggered: Config.triggerQuoteFetch()
    }
}