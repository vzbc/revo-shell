import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import ".."

Scope {
    id: oskScope

    // Target active screen (set explicitly during drag or initialized to focused)
    property var activeScreen: {
        let activeName = (typeof Hyprland !== "undefined" && Hyprland.focusedMonitor) ? Hyprland.focusedMonitor.name : ""
        let found = Quickshell.screens.find(s => s.name === activeName)
        return found ? found : Quickshell.screens[0]
    }

    // Normalized relative position percentage across whatever screen it lives on
    property real relativeX: 0.5
    property real relativeY: 0.7

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: win
            required property var modelData

            screen: modelData
            visible: Config.showOsk && (oskScope.activeScreen === modelData)

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-osk"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusiveZone: 0

            anchors {
                top: true; bottom: true
                left: true; right: true
            }

            color: "transparent"
            mask: oskInputBounds

            Region {
                id: oskInputBounds
                item: keyboardWrapper
            }

            Rectangle {
                id: keyboardWrapper
                color: "transparent"

                width: (Config.oskLayout || "Normal") === "Gamer" ? 440 : ((Config.oskLayout || "Normal") === "Minimal" ? 540 : 720)
                height: (Config.oskLayout || "Normal") === "Gamer" ? 220 : ((Config.oskLayout || "Normal") === "Minimal" ? 220 : 280)

                x: Math.max(10, Math.min(win.width - width - 10, oskScope.relativeX * (win.width - width)))
                y: Math.max(10, Math.min(win.height - height - 10, oskScope.relativeY * (win.height - height)))

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    cursorShape: containsMouse ? Qt.SizeAllCursor : Qt.ArrowCursor

                    property point pressMousePos: Qt.point(0, 0)

                    onPressed: (mouse) => {
                        pressMousePos = Qt.point(mouse.x, mouse.y)
                    }

                    onPositionChanged: (mouse) => {
                        if (!pressed) return

                        // Only evaluate screen cross when actively dragging
                        let globalPos = Quickshell.cursorPosition
                        if (globalPos) {
                            let targetScreen = Quickshell.screens.find(s => 
                                globalPos.x >= s.x && globalPos.x < (s.x + s.width) &&
                                globalPos.y >= s.y && globalPos.y < (s.y + s.height)
                            )
                            if (targetScreen && targetScreen !== oskScope.activeScreen) {
                                oskScope.activeScreen = targetScreen
                            }
                        }

                        let deltaX = mouse.x - pressMousePos.x
                        let deltaY = mouse.y - pressMousePos.y

                        let newX = keyboardWrapper.x + deltaX
                        let newY = keyboardWrapper.y + deltaY

                        oskScope.relativeX = Math.max(0, Math.min(1, newX / Math.max(1, win.width - keyboardWrapper.width)))
                        oskScope.relativeY = Math.max(0, Math.min(1, newY / Math.max(1, win.height - keyboardWrapper.height)))
                    }
                }

                // --- VIEW MODE 1: STANDARD KEYBOARDS (NORMAL / MINIMAL) ---
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5
                    visible: (Config.oskLayout || "Normal") !== "Gamer"

                    Repeater {
                        model: (Config.oskLayout || "Normal") === "Minimal" ? layoutMinimal : layoutNormal
                        delegate: RowLayout {
                            id: rowContainer
                            required property var modelData
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 5

                            Repeater {
                                model: rowContainer.modelData
                                delegate: Loader {
                                    required property var modelData
                                    sourceComponent: keyCapComponent
                                    onLoaded: item.keyData = modelData
                                    width: 38 * modelData[2]
                                    height: 38
                                }
                            }
                        }
                    }
                }

                // --- VIEW MODE 2: ABSOLUTE COORDINATE POSITIONING (GAMER) ---
                Item {
                    anchors.fill: parent
                    visible: (Config.oskLayout || "Normal") === "Gamer"

                    // --- NUMBER ROW (1-0) ---
                    Repeater {
                        model: [
                            ["1", "KEY_1"], ["2", "KEY_2"], ["3", "KEY_3"], ["4", "KEY_4"], ["5", "KEY_5"],
                            ["6", "KEY_6"], ["7", "KEY_7"], ["8", "KEY_8"], ["9", "KEY_9"], ["0", "KEY_0"]
                        ]

                        delegate: Loader {
                            required property var modelData
                            required property int index
                            x: 15 + (index * 38)
                            y: 12
                            sourceComponent: keyCapComponent
                            onLoaded: item.keyData = [modelData[0], modelData[1], 1]
                            width: 34; height: 32
                        }
                    }

                    // --- WASD & ACTION KEYS ---

                    // Tab
                    Loader {
                        x: 15; y: 51
                        sourceComponent: keyCapComponent
                        onLoaded: item.keyData = ["Tab", "KEY_TAB", 1]
                        width: 55; height: 38
                    }

                    // Shift
                    Loader {
                        x: 15; y: 95
                        sourceComponent: keyCapComponent
                        onLoaded: item.keyData = ["Shift", "KEY_LEFTSHIFT", 1]
                        width: 55; height: 38
                    }

                    // W
                    Loader {
                        x: 128; y: 51
                        sourceComponent: keyCapComponent
                        onLoaded: item.keyData = ["W", "KEY_W", 1]
                        width: 40; height: 38
                    }

                    // A
                    Loader {
                        x: 82; y: 95
                        sourceComponent: keyCapComponent
                        onLoaded: item.keyData = ["A", "KEY_A", 1]
                        width: 40; height: 38
                    }

                    // S
                    Loader {
                        x: 128; y: 95
                        sourceComponent: keyCapComponent
                        onLoaded: item.keyData = ["S", "KEY_S", 1]
                        width: 40; height: 38
                    }

                    // D
                    Loader {
                        x: 174; y: 95
                        sourceComponent: keyCapComponent
                        onLoaded: item.keyData = ["D", "KEY_D", 1]
                        width: 40; height: 38
                    }

                    // Enter
                    Loader {
                        x: 230; y: 51
                        sourceComponent: keyCapComponent
                        onLoaded: item.keyData = ["Enter", "KEY_ENTER", 1]
                        width: 50; height: 82
                    }

                    // Spacebar
                    Loader {
                        x: 43; y: 145
                        sourceComponent: keyCapComponent
                        onLoaded: item.keyData = ["Space", "KEY_SPACE", 1]
                        width: 210; height: 38
                    }

                    // --- UNIFIED INTEGRATED MOUSE CHASSIS ---
                    // Right edge = 306 + 85 = 391 (Flush with 0 key right edge)
                    Item {
                        id: mouseChassis
                        x: 306; y: 51
                        width: 85; height: 132

                        readonly property bool leftPressed: oskScope.pressedKeys.has("BTN_LEFT")
                        readonly property bool rightPressed: oskScope.pressedKeys.has("BTN_RIGHT")
                        readonly property bool middlePressed: oskScope.pressedKeys.has("BTN_MIDDLE")

                        Rectangle {
                            anchors.fill: parent
                            radius: 18
                            color: Config.bgPanel
                            border.color: Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1

                            // Left Click Zone
                            Rectangle {
                                width: (parent.width / 2)
                                height: parent.height * 0.45
                                x: 0; y: 0
                                topLeftRadius: parent.radius
                                color: mouseChassis.leftPressed ? Config.accent : "transparent"
                                border.color: mouseChassis.leftPressed ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            // Right Click Zone
                            Rectangle {
                                width: (parent.width / 2)
                                height: parent.height * 0.45
                                x: parent.width / 2; y: 0
                                topRightRadius: parent.radius
                                color: mouseChassis.rightPressed ? Config.accent : "transparent"
                                border.color: mouseChassis.rightPressed ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            // Scroll Wheel Block
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: (parent.height * 0.45) - 13
                                width: 10; height: 24
                                radius: 4
                                color: mouseChassis.middlePressed ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                                border.color: mouseChassis.middlePressed ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- SHARED DATA & KEY DEFINITIONS ---
    property var pressedKeys: new Set()

    readonly property var layoutNormal: [
        [["~", "KEY_GRAVE", 1], ["1", "KEY_1", 1], ["2", "KEY_2", 1], ["3", "KEY_3", 1], ["4", "KEY_4", 1], ["5", "KEY_5", 1], ["6", "KEY_6", 1], ["7", "KEY_7", 1], ["8", "KEY_8", 1], ["9", "KEY_9", 1], ["0", "KEY_0", 1], ["-", "KEY_MINUS", 1], ["=", "KEY_EQUAL", 1], ["Bksp", "KEY_BACKSPACE", 1.75]],
        [["Tab", "KEY_TAB", 1.5], ["Q", "KEY_Q", 1], ["W", "KEY_W", 1], ["E", "KEY_E", 1], ["R", "KEY_R", 1], ["T", "KEY_T", 1], ["Y", "KEY_Y", 1], ["U", "KEY_U", 1], ["I", "KEY_I", 1], ["O", "KEY_O", 1], ["P", "KEY_P", 1], ["[", "KEY_LEFTBRACE", 1], ["]", "KEY_RIGHTBRACE", 1], ["\\", "KEY_BACKSLASH", 1.25]],
        [["Caps", "KEY_CAPSLOCK", 1.75], ["A", "KEY_A", 1], ["S", "KEY_S", 1], ["D", "KEY_D", 1], ["F", "KEY_F", 1], ["G", "KEY_G", 1], ["H", "KEY_H", 1], ["J", "KEY_J", 1], ["K", "KEY_K", 1], ["L", "KEY_L", 1], [";", "KEY_SEMICOLON", 1], ["'", "KEY_APOSTROPHE", 1], ["Enter", "KEY_ENTER", 2]],
        [["Shift", "KEY_LEFTSHIFT", 2.25], ["Z", "KEY_Z", 1], ["X", "KEY_X", 1], ["C", "KEY_C", 1], ["V", "KEY_V", 1], ["B", "KEY_B", 1], ["N", "KEY_N", 1], ["M", "KEY_M", 1], [",", "KEY_COMMA", 1], [".", "KEY_DOT", 1], ["/", "KEY_SLASH", 1], ["Shift", "KEY_RIGHTSHIFT", 2.5]],
        [["Ctrl", "KEY_LEFTCTRL", 1.25], ["Super", "KEY_LEFTMETA", 1.25], ["Alt", "KEY_LEFTALT", 1.25], ["Space", "KEY_SPACE", 5.25], ["Alt", "KEY_RIGHTALT", 1.25], ["Ctrl", "KEY_RIGHTCTRL", 1.25]]
    ]

    readonly property var layoutMinimal: [
        [["Q", "KEY_Q", 1], ["W", "KEY_W", 1], ["E", "KEY_E", 1], ["R", "KEY_R", 1], ["T", "KEY_T", 1], ["Y", "KEY_Y", 1], ["U", "KEY_U", 1], ["I", "KEY_I", 1], ["O", "KEY_O", 1], ["P", "KEY_P", 1], ["Bksp", "KEY_BACKSPACE", 1.5]],
        [["A", "KEY_A", 1], ["S", "KEY_S", 1], ["D", "KEY_D", 1], ["F", "KEY_F", 1], ["G", "KEY_G", 1], ["H", "KEY_H", 1], ["J", "KEY_J", 1], ["K", "KEY_K", 1], ["L", "KEY_L", 1], ["Enter", "KEY_ENTER", 1.75]],
        [["Shift", "KEY_LEFTSHIFT", 2], ["Z", "KEY_Z", 1], ["X", "KEY_X", 1], ["C", "KEY_C", 1], ["V", "KEY_V", 1], ["B", "KEY_B", 1], ["N", "KEY_N", 1], ["M", "KEY_M", 1], ["Shift", "KEY_RIGHTSHIFT", 1.75]],
        [["Ctrl", "KEY_LEFTCTRL", 1.5], ["Alt", "KEY_LEFTALT", 1.5], ["Space", "KEY_SPACE", 5.5], ["Alt", "KEY_RIGHTALT", 1.5], ["Ctrl", "KEY_RIGHTCTRL", 1.5]]
    ]

    Process {
        id: keySniffer
        command: ["stdbuf", "-oL", "sudo", "showmethekey-cli"]
        running: !!(Config.showOsk)
        
        stdout: SplitParser {
            onRead: (line) => {
                let trimmed = line.trim();
                if (!trimmed) return;
                try {
                    let obj = JSON.parse(trimmed);
                    if (obj.event_name === "KEYBOARD_KEY" || obj.event_name === "POINTER_BUTTON") {
                        let updatedKeys = new Set(oskScope.pressedKeys);
                        let targetIdentifier = obj.key_name || obj.button_name;
                        if (!targetIdentifier) return;

                        if (obj.state_name === "PRESSED") updatedKeys.add(targetIdentifier);
                        else if (obj.state_name === "RELEASED") updatedKeys.delete(targetIdentifier);
                        
                        oskScope.pressedKeys = updatedKeys;
                    }
                } catch(e) {}
            }
        }
    }

    Component {
        id: keyCapComponent
        Item {
            id: keyCapRoot
            property var keyData
            property bool isPressed: oskScope.pressedKeys.has(keyData[1])

            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: (Config.oskLayout || "Normal") === "Gamer" ? 4 : Config.cornerRadius / 2
                color: keyCapRoot.isPressed ? Config.accent : Config.bgPanel
                border.color: keyCapRoot.isPressed ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1
            }

            Text {
                anchors.centerIn: parent
                text: keyCapRoot.keyData[0]
                color: keyCapRoot.isPressed ? Config.bgBase : Config.textMain
                font.bold: true
                font.pixelSize: 12
                font.family: Config.sysFont
            }
        }
    }
}