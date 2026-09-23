import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../common"

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { top: Appearance.barHeight + 8; right: 12 }
    width: 300
    height: mainCol.implicitHeight + 24
    visible: ShellController.controlCenterOpen
    color: "transparent"
    WlrLayershell.namespace: "macos:controlcenter"
    WlrLayershell.layer: WlrLayer.Overlay

    property bool wifiOn: Network.wifiOn
    property bool bluetoothOn: false
    property bool airdropOn: false
    property int focusMode: 0
    property real brightness: 0.8
    property real volume: 0.6
    property bool micActive: false
    property bool darkMode: false

    Component.onCompleted: _micCheck.running = true
    Timer {
        id: _micCheck; interval: 2000; running: true; repeat: true
        onTriggered: _micProc.running = true
    }
    Process {
        id: _micProc; running: false
        command: ["bash", "-c", "pactl list sources 2>/dev/null | grep -c 'RUNNING' || echo 0"]
        stdout: StdioCollector { onStreamFinished: root.micActive = parseInt(text.trim()) > 0 }
    }

    Connections {
        target: ShellController
        function onControlCenterOpenChanged() {
            if (!ShellController.controlCenterOpen) return;
            _wifiProc.running = true;
        }
    }
    Process {
        id: _wifiProc; running: false
        command: ["bash", "-c", "nmcli -t -f WIFI general 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }

    function toggleWifi() {
        root.wifiOn = !root.wifiOn
        ShellController.run(root.wifiOn ? "nmcli radio wifi on" : "nmcli radio wifi off")
    }
    function toggleBluetooth() {
        root.bluetoothOn = !root.bluetoothOn
        ShellController.run(root.bluetoothOn ? "rfkill unblock bluetooth" : "rfkill block bluetooth")
    }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // ---- Row 1: WiFi + Now Playing ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // WiFi tile
            CCLGTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                icon: "\uf1eb"
                label: "Wi-Fi"
                subtitle: root.wifiOn ? (Network.wifiSsid || "MasterStore Team") : "Off"
                active: root.wifiOn
                accentColor: "#007aff"
                onClicked: root.toggleWifi()
            }

            // Now Playing tile
            CCLGTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                icon: "\u266B"
                label: Audio.isPlaying ? (Audio.currentTrack || "Playing") : "Not Playing"
                subtitle: ""
                active: false
                onClicked: ShellController.run("playerctl play-pause 2>/dev/null || true")
            }
        }

        // ---- Row 2: Bluetooth ----
        CCLGTile {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            icon: "\uf293"
            label: "Bluetooth"
            subtitle: root.bluetoothOn ? "On" : "Off"
            active: root.bluetoothOn
            accentColor: "#007aff"
            onClicked: root.toggleBluetooth()
        }

        // ---- Row 3: AirDrop + Screen Mirroring + Menu ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            CCLGTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                icon: "\uf357"
                label: "AirDrop"
                subtitle: root.airdropOn ? "On" : "Off"
                active: root.airdropOn
                accentColor: "#007aff"
                onClicked: root.airdropOn = !root.airdropOn
            }

            // Screen Mirroring circle
            CCLGCircle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                icon: "\u25C8"
                active: false
                onClicked: ShellController.run("hyprctl dispatch togglefloating 2>/dev/null || true")
            }

            // Menu circle
            CCLGCircle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                icon: "\u2630"
                active: root.darkMode
                onClicked: root.darkMode = !root.darkMode
            }
        }

        // ---- Row 4: Night Shift + Fullscreen + Focus ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Night Shift circle
            CCLGCircle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                icon: "\u23E9"
                active: false
                onClicked: ShellController.run("hyprctl dispatch fullscreen 0 2>/dev/null || true")
            }

            // Fullscreen circle
            CCLGCircle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                icon: "\u25A3"
                active: false
                onClicked: ShellController.run("hyprctl dispatch toggleoverview 2>/dev/null || true")
            }

            // Focus tile
            CCLGTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                icon: "\u263E"
                label: "Focus"
                subtitle: root.focusMode === 0 ? "Off" : ["", "DND", "Personal", "Work", "Sleep"][root.focusMode]
                active: root.focusMode > 0
                accentColor: "#bf5af2"
                onClicked: root.focusMode = (root.focusMode + 1) % 5
            }
        }

        // ---- Mic indicator ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.micActive ? 32 : 0
            radius: 10
            color: root.micActive ? Qt.rgba(0.7, 0.35, 0, 0.5) : "transparent"
            border.color: root.micActive ? Qt.rgba(1, 0.6, 0, 0.6) : "transparent"
            border.width: 0.5
            visible: root.micActive
            clip: true
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                spacing: 6
                Text {
                    text: "\u2699"
                    font { pixelSize: 13 }
                    color: "#ff9500"
                }
                Text {
                    text: "Microphone Active"
                    font { family: "SF Pro Text"; pixelSize: 11; weight: Font.Medium }
                    color: "#ff9500"; Layout.fillWidth: true
                }
                Rectangle {
                    width: 6; height: 6; radius: 3; color: "#ff9500"
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 800 }
                        NumberAnimation { to: 1.0; duration: 800 }
                    }
                }
            }
        }

        // ---- Display Slider ----
        CCLGSlider {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            label: "Display"
            iconLeft: "\u2600"
            iconRight: "\u2600"
            value: root.brightness
            onValueChanged: root.brightness = value
        }

        // ---- Sound Slider ----
        CCLGSlider {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            label: "Sound"
            iconLeft: "\uD83D\uDD07"
            iconRight: "\uD83D\uDD0A"
            value: root.volume
            onValueChanged: {
                root.volume = value;
                ShellController.run("pactl set-sink-volume @DEFAULT_SINK@ " + Math.round(value * 100) + "%");
            }
        }

        // ---- Edit Controls ----
        CCLGSlider {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            label: ""
            iconLeft: ""
            iconRight: ""
            value: 0
            visible: false
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 16
            color: Qt.rgba(0.12, 0.12, 0.15, 0.4)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 0.5
            Text {
                anchors.centerIn: parent
                text: "Edit Controls"
                font { family: "SF Pro Text"; pixelSize: 12; weight: Font.Medium }
                color: Qt.rgba(1, 1, 1, 0.8)
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellController.run("echo 'edit controls' > /tmp/macos_cmd")
            }
        }
    }

    // ---- Liquid Glass Tile (WiFi, Bluetooth, AirDrop, Focus, Now Playing) ----
    component CCLGTile: Rectangle {
        id: tile
        property string icon: ""
        property string label: ""
        property string subtitle: ""
        property bool active: false
        property color accentColor: "#007aff"
        signal clicked()

        radius: 14
        color: active ? accentColor : Qt.rgba(0.12, 0.12, 0.15, 0.4)
        border.color: active ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(1, 1, 1, 0.08)
        border.width: 0.5

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Rectangle {
                width: 32; height: 32; radius: 16
                color: active ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(1, 1, 1, 0.1)
                Layout.alignment: Qt.AlignVCenter
                Text {
                    anchors.centerIn: parent
                    text: tile.icon
                    font { family: "Apple Color Emoji"; pixelSize: 14 }
                    color: "#ffffff"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                Text {
                    text: tile.label
                    font { family: "SF Pro Text"; pixelSize: 13; weight: Font.SemiBold }
                    color: "#ffffff"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: tile.subtitle
                    font { family: "SF Pro Text"; pixelSize: 10; weight: Font.Regular }
                    color: active ? Qt.rgba(255, 255, 255, 0.7) : Qt.rgba(1, 1, 1, 0.5)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    // ---- Liquid Glass Circle ----
    component CCLGCircle: Rectangle {
        id: sc
        property string icon: ""
        property bool active: false
        property color accentColor: "#636366"
        signal clicked()

        radius: width / 2
        color: active ? accentColor : Qt.rgba(0.12, 0.12, 0.15, 0.4)
        border.color: active ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(1, 1, 1, 0.08)
        border.width: 0.5

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: sc.icon
            font { family: "Apple Color Emoji"; pixelSize: 15 }
            color: sc.active ? "#ffffff" : Qt.rgba(1, 1, 1, 0.85)
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sc.clicked()
        }
    }

    // ---- Liquid Glass Slider ----
    component CCLGSlider: Item {
        id: sl
        property string label: ""
        property string iconLeft: ""
        property string iconRight: ""
        property real value: 0.5
        signal realValueChanged(real value)

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Qt.rgba(0.12, 0.12, 0.15, 0.4)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 0.5
        }

        Text {
            id: lbl
            anchors.top: parent.top
            anchors.topMargin: 6
            anchors.left: parent.left
            anchors.leftMargin: 12
            text: sl.label
            font { family: "SF Pro Text"; pixelSize: 11; weight: Font.Medium }
            color: Qt.rgba(1, 1, 1, 0.7)
            visible: text !== ""
        }

        Item {
            anchors.top: sl.label !== "" ? lbl.bottom : parent.top
            anchors.topMargin: sl.label !== "" ? 4 : 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: 6
                text: sl.iconLeft
                font { family: "Apple Color Emoji"; pixelSize: 11 }
                color: Qt.rgba(1, 1, 1, 0.6)
                visible: text !== ""
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: sl.iconLeft !== "" ? 28 : 10
                anchors.right: parent.right; anchors.rightMargin: sl.iconRight !== "" ? 28 : 10
                height: 18; radius: 9
                color: Qt.rgba(1, 1, 1, 0.15)

                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: sl.value * parent.width
                    radius: 9
                    color: "#ffffff"
                }

                Rectangle {
                    x: sl.value * (parent.width - width)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18; height: 18; radius: 9
                    color: "#ffffff"
                    border.color: Qt.rgba(0, 0, 0, 0.12)
                    border.width: 0.5
                }

                MouseArea {
                    anchors.fill: parent
                    onMouseXChanged: (mouse) => {
                        if (pressed) {
                            var v = Math.max(0, Math.min(1, mouse.x / parent.width));
                            sl.value = v; sl.rawValueChanged(v);
                        }
                    }
                    onClicked: (mouse) => {
                        var v = Math.max(0, Math.min(1, mouse.x / parent.width));
                        sl.value = v; sl.rawValueChanged(v);
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right; anchors.rightMargin: 6
                text: sl.iconRight
                font { family: "Apple Color Emoji"; pixelSize: 11 }
                color: Qt.rgba(1, 1, 1, 0.6)
                visible: text !== ""
            }
        }
    }
}
