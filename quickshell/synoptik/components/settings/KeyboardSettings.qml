import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import ".."

Flickable {
    id: flickable
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        active: flickable.moving || flickable.flicking
    }

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12
    property string recordingId: ""

    // Reusable Geometric / Square Toggle Switch Component
    component ToggleSwitch : Rectangle {
        id: sw
        property bool checked: false
        
        implicitWidth: 40
        implicitHeight: 22
        radius: 6
        color: checked ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.4)
        border.width: sw.checked ? 2 : 1
        border.color: checked ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        // Square Thumb / Slider
        Rectangle {
            id: thumb
            x: sw.checked ? (sw.width - width - 3) : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 4
            color: sw.checked ? Config.accent : Qt.rgba(255, 255, 255, 0.2)
            border.width: 0
            border.color: sw.checked ? Qt.lighter(Config.accent, 1.2) : Qt.rgba(255, 255, 255, 0.25)

            Behavior on x { 
                NumberAnimation { 
                    duration: 160
                    easing.type: Easing.OutCubic 
                } 
            }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
    }

    Item {
        id: keyListener
        anchors.fill: parent
        focus: flickable.recordingId !== ""

        Keys.onPressed: (event) => {
            if (flickable.recordingId === "") return

            if (event.key === Qt.Key_Escape) {
                flickable.recordingId = ""
                event.accepted = true
                return
            }

            // Ignore standalone modifier presses
            if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Meta, Qt.Key_Alt, Qt.Key_Super_L, Qt.Key_Super_R].includes(event.key)) {
                event.accepted = true
                return
            }

            // Strict allowlist validation and keysym conversion
            let keyStr = ""
            if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                keyStr = String.fromCharCode(event.key)
            } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                keyStr = String.fromCharCode(event.key)
            } else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) {
                keyStr = "F" + (event.key - Qt.Key_F1 + 1)
            } else {
                switch (event.key) {
                    case Qt.Key_Space:        keyStr = "Space"; break
                    case Qt.Key_Tab:
                    case Qt.Key_Backtab:      keyStr = "TAB"; break
                    case Qt.Key_Return:
                    case Qt.Key_Enter:        keyStr = "Return"; break
                    case Qt.Key_Backspace:    keyStr = "BackSpace"; break
                    case Qt.Key_Delete:       keyStr = "Delete"; break
                    case Qt.Key_Left:         keyStr = "Left"; break
                    case Qt.Key_Right:        keyStr = "Right"; break
                    case Qt.Key_Up:           keyStr = "Up"; break
                    case Qt.Key_Down:         keyStr = "Down"; break
                    case Qt.Key_Home:         keyStr = "Home"; break
                    case Qt.Key_End:          keyStr = "End"; break
                    case Qt.Key_PageUp:       keyStr = "Page_Up"; break
                    case Qt.Key_PageDown:     keyStr = "Page_Down"; break
                    case Qt.Key_BracketLeft:  keyStr = "bracketleft"; break
                    case Qt.Key_BracketRight: keyStr = "bracketright"; break
                    case Qt.Key_Semicolon:    keyStr = "semicolon"; break
                    case Qt.Key_Apostrophe:   keyStr = "apostrophe"; break
                    case Qt.Key_Comma:        keyStr = "comma"; break
                    case Qt.Key_Period:       keyStr = "period"; break
                    case Qt.Key_Slash:        keyStr = "slash"; break
                    case Qt.Key_Backslash:    keyStr = "backslash"; break
                    case Qt.Key_Minus:        keyStr = "minus"; break
                    case Qt.Key_Equal:        keyStr = "equal"; break
                    case Qt.Key_QuoteLeft:    keyStr = "grave"; break
                    default:
                        event.accepted = true
                        return
                }
            }

            // Build modifier string
            let mods = []
            if (event.modifiers & Qt.MetaModifier || event.modifiers === 0) mods.push("SUPER")
            if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
            if (event.modifiers & Qt.AltModifier) mods.push("ALT")
            if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")

            Config.updateKeybind(flickable.recordingId, mods.join(" + "), keyStr)
            flickable.recordingId = ""
            event.accepted = true
        }
    }

    ColumnLayout {
        id: contentColumn
        width: Math.min(flickable.width - (flickable.cardMargin * 2), 620)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: flickable.cardMargin

        Text {
            Layout.fillWidth: true
            text: "KEYBOARD CONFIGURATION"
            color: Config.textMain
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontSubhead)
            font.bold: true
        }

        Text {
            text: "Configure global desktop shortcuts, widget triggers, on-screen keyboard layouts, and input overlay behaviors."
            color: Config.textMuted
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontCaption)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        // ==========================================
        // 1. WIDGET KEYBINDS CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: bindsCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: bindsCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "WIDGET SHORTCUTS"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                        }

                        Text {
                            text: flickable.recordingId !== "" ? "Press any key combination (Esc to cancel)..." : "Click any badge to remap. Updates write to hypr_style.lua."
                            color: flickable.recordingId !== "" ? Config.accent : Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    // RESET DEFAULTS PILL BUTTON
                    Rectangle {
                        id: resetBtn
                        implicitWidth: resetRow.implicitWidth + 16
                        implicitHeight: 30
                        radius: 15
                        color: resetMouse.containsMouse ? Config.accent : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.18)
                        border.width: 1.5
                        border.color: Config.accent

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: resetRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "restart_alt"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 15
                                color: resetMouse.containsMouse ? Config.bgBase : Config.accent
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                text: "Reset Defaults"
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: resetMouse.containsMouse ? Config.bgBase : Config.accent
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: resetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.resetKeybinds()
                        }
                    }
                }

                // SHORTCUT ROWS
                Repeater {
                    model: [
                        { id: "launcher",          name: "App Launcher",        icon: "terminal_2" },
                        { id: "settings",          name: "Settings Panel",      icon: "build" },
                        { id: "wallpaper",         name: "Wallpaper Picker",    icon: "wall_art" },
                        { id: "workspaceoverview", name: "Workspace Overview", icon: "select_window_2" },
                        { id: "clipboard",         name: "Clipboard Manager",   icon: "content_paste" },
                        { id: "lockscreen",        name: "Lock Screen",         icon: "lock" },
                        { id: "shader",            name: "Retro Screen Shader", icon: "videogame_asset" }
                    ]

                    delegate: Rectangle {
                        id: rowCard
                        Layout.fillWidth: true
                        implicitHeight: 52
                        radius: Config.cornerRadius / 2
                        readonly property bool isRecording: flickable.recordingId === modelData.id
                        color: isRecording ? Qt.rgba(255, 255, 255, 0.14) : (rowHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                        border.width: isRecording ? 1.5 : 1
                        border.color: isRecording ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            Rectangle {
                                implicitWidth: 32
                                implicitHeight: 32
                                radius: 6
                                color: Qt.rgba(255, 255, 255, 0.05)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: Config.accent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                }
                            }

                            Text {
                                text: modelData.name
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                id: bindBadge
                                implicitHeight: 30
                                implicitWidth: Math.max(84, keyLabel.implicitWidth + 20)
                                radius: 15
                                color: rowCard.isRecording ? Config.accent : (badgeHover.containsMouse ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.28) : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.16))
                                border.width: 1
                                border.color: rowCard.isRecording ? Config.accent : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.4)

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    id: keyLabel
                                    anchors.centerIn: parent
                                    property var bindData: (Config.keybinds && Config.keybinds[modelData.id] && Config.keybinds[modelData.id].key) 
                                        ? Config.keybinds[modelData.id] 
                                        : (Config.defaultKeybinds[modelData.id] || {})
                                    text: {
                                        if (rowCard.isRecording) return "RECORDING..."
                                        let m = bindData.mod || "SUPER"
                                        let k = bindData.key || ""
                                        return m + (k !== "" ? " + " + k : "")
                                    }
                                    color: rowCard.isRecording ? Config.bgBase : Config.accent
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    id: badgeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        flickable.recordingId = modelData.id
                                        keyListener.focus = true
                                        keyListener.forceActiveFocus()
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: -1
                            onClicked: {
                                flickable.recordingId = modelData.id
                                keyListener.focus = true
                                keyListener.forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. ON-SCREEN KEYBOARD (OSK) OPTIONS CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: oskCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: oskCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Text {
                    text: "ON-SCREEN KEYBOARD"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                // OSK ENABLE TOGGLE
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Enable On-Screen Keyboard"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Show the virtual touch-friendly keyboard overlay for touchscreens and quick input."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.showOsk !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.showOsk = (Config.showOsk === false)
                                if (typeof Config.saveSettings === "function") Config.saveSettings()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }

                // OSK LAYOUT SELECTOR
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Keyboard Layout Style:"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { id: "Normal",  name: "Normal",  icon: "keyboard",        desc: "Full standard" },
                                { id: "Minimal", name: "Minimal", icon: "keyboard_keys",   desc: "Compact view" },
                                { id: "Gamer",   name: "Gamer",   icon: "sports_esports",  desc: "WASD oriented" }
                            ]

                            delegate: Rectangle {
                                id: layoutPill
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.minimumWidth: 0
                                implicitHeight: 64
                                radius: Config.cornerRadius / 2

                                readonly property bool isSelected: (Config.oskLayout || "Normal") === modelData.id

                                color: isSelected 
                                    ? Qt.rgba(255, 255, 255, 0.14) 
                                    : (layoutHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                                border.width: isSelected ? 1.5 : 1
                                border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                                Behavior on color { ColorAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 6

                                        Text {
                                            text: modelData.icon
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 16
                                            color: layoutPill.isSelected ? Config.accent : Config.textMuted
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Text {
                                            text: modelData.name
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontCaption)
                                            font.bold: true
                                            color: layoutPill.isSelected ? Config.accent : Config.textMain
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }

                                    Text {
                                        text: modelData.desc
                                        font.family: Config.sysFont
                                        font.pixelSize: 10
                                        color: Config.textMuted
                                        Layout.alignment: Qt.AlignHCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    id: layoutHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Config.oskLayout = modelData.id
                                        if (typeof Config.saveSettings === "function") Config.saveSettings()
                                        else if (typeof Config.save === "function") Config.save()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; implicitHeight: 20 }
    }
}