pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real currentBrightness: 0.5
    property bool shouldShowOsd: false

    function changeBright(delta) {
        brightnessProcess.command = ["sh", "-c", `
          brightnessctl -e4 -n2 set ${delta > 0 ? "5%+" : "5%-"}
          qs ipc --path ~/.config/quickshell/cartoon-shell \
              call brightness set \
              "$(awk "BEGIN {print $(brightnessctl g)/$(brightnessctl m)}")"
          `];

        brightnessProcess.running = true;
    }
    function setBright(value) {
        brightnessProcess.command = ["sh", "-c", `
        brightnessctl -e4 -n2 set ${Math.round(value * 100)}%
        qs ipc --path ~/.config/quickshell/cartoon-shell \
            call brightness set \
            "$(awk "BEGIN {print $(brightnessctl g)/$(brightnessctl m)}")"
        `];

        brightnessProcess.running = true;
    }

    Process {
        id: brightnessProcess
        running: false

        onExited: {
            getBrightProcess.running = true;
        }
    }

    Component.onCompleted: {
        Qt.callLater(init);
    }

    function init() {
        getBrightProcess.running = true;
    }

    Process {
        id: getBrightProcess
        running: false

        command: ["bash", "-c", "awk \"BEGIN {print $(brightnessctl g)/$(brightnessctl m)}\""]

        stdout: StdioCollector {
            onTextChanged: {
                const value = parseFloat(text.trim());
                if (!isNaN(value)) {
                    root.currentBrightness = value;
                }
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function set(value: real) {
            root.shouldShowOsd = true;
            root.currentBrightness = value;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shouldShowOsd = false
    }
}
