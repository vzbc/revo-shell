import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Data" as Dat
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

Scope {
    id: root

    property int brightness: 0
    property int current: -1
    property int max: 1
    property bool shouldShowOsd: false
    property bool initialized: false

    property string backlightDevice: ""

    Process {
        id: findBacklight
        command: ["sh", "-c", "ls /sys/class/backlight | head -n 1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let device = data.trim();
                if (device) {
                    root.backlightDevice = device;
                }
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 100
        running: root.backlightDevice !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            currentFile.reload();
            maxFile.reload();
        }
    }

    FileView {
        id: currentFile
        path: root.backlightDevice ? "/sys/class/backlight/" + root.backlightDevice + "/brightness" : ""
        onLoaded: {
            var val = parseInt(text().trim());
            if (isNaN(val))
                return;
            if (root.current !== val) {
                if (root.initialized && root.current !== -1) {
                    root.shouldShowOsd = true;
                    hideTimer.restart();
                }
                root.current = val;
                root.updateBrightness();
                root.initialized = true;
            }
        }
    }

    FileView {
        id: maxFile
        path: root.backlightDevice ? "/sys/class/backlight/" + root.backlightDevice + "/max_brightness" : ""
        onLoaded: {
            var val = parseInt(text().trim());
            if (!isNaN(val)) {
                root.max = val;
                root.updateBrightness();
            }
        }
    }

    function updateBrightness() {
        if (root.max > 0 && root.current >= 0) {
            root.brightness = Math.round((root.current / root.max) * 100);
        }
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.shouldShowOsd = false
    }

    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            anchors.top: true
            margins.top: screen.height / 9
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            implicitWidth: 550
            implicitHeight: 50
            color: "transparent"
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Dat.Colors.color2

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 15
                        rightMargin: 15
                    }
                    spacing: 10

                    Text {
                        text: "󰃠"
                        color: "#ffffff"
                        font.pixelSize: 25
                        font.family: "Montserrat Light"
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 10
                        radius: 20
                        color: Dat.Colors.color3

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            implicitWidth: parent.width * (root.brightness / 100)
                            radius: parent.radius
                            color: "#ffffff"
                        }
                    }

                    Text {
                        text: root.brightness + "%"
                        color: "#ffffff"
                        font.pixelSize: 20
                        font.family: "Montserrat Light"
                        font.weight: Font.Bold
                        Layout.minimumWidth: 50
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
