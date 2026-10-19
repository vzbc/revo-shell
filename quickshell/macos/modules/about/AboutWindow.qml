import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Quickshell
import Quickshell.Io
import "../../services"
import "../common"

// About This Mac — macOS-style glass window. Layout and wording are a
// faithful port of macos-tahoe-liquid-kde's AboutWindow.qml, using the
// shell's own Appearance palette instead of Kirigami and a Process for
// the JSON data source instead of plasma5support.
PopupWindow {
    id: aboutWindow

    screen: Quickshell.screens[0]
    width: 360
    height: 640
    color: "transparent"
    visible: ShellController.aboutOpen

    readonly property string fontFamily: Appearance.fontFamily
    readonly property bool isDarkTheme: true

    readonly property bool infoReady: _ready
    property bool _ready: false
    readonly property string _placeholder: "\u00A0"
    property string vendorDisplay: _placeholder
    property string modelDisplay: _placeholder
    property string yearDisplay: ""
    property string chipDisplay: _placeholder
    property string coresDisplay: _placeholder
    property string memoryDisplay: _placeholder
    property string graphicsDisplay: _placeholder
    property string diskDisplay: _placeholder
    property string networkDisplay: _placeholder
    property string serialDisplay: _placeholder
    property string osDisplay: _placeholder

    FontMetrics {
        id: _fm
        font.family: aboutWindow.fontFamily
        font.pointSize: 12
    }

    // ── data fetcher ─────────────────────────────────────────────────────
    Process {
        id: infoSource
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const stdout = text.trim();
                if (!stdout) return;
                let info;
                try {
                    info = JSON.parse(stdout);
                } catch (e) { return; }
                aboutWindow.vendorDisplay = info.vendor || "Personal Computer";
                aboutWindow.modelDisplay = info.model || "";
                aboutWindow.yearDisplay = info.year || "";
                aboutWindow.chipDisplay = info.chip || "Unknown";
                aboutWindow.coresDisplay = info.cores || "Unknown";
                aboutWindow.memoryDisplay = info.memory || "Unknown";
                aboutWindow.graphicsDisplay = info.graphics || "Unknown";
                aboutWindow.diskDisplay = info.disk || "Unknown";
                aboutWindow.networkDisplay = info.network || "Unknown";
                aboutWindow.serialDisplay = info.serial || "Not Available";
                aboutWindow.osDisplay = info.os || "Unknown";
                aboutWindow._ready = true;
            }
        }
    }

    function refresh() {
        aboutWindow._ready = false;
        infoSource.command = ["bash", "-c", "python3 " + Quickshell.env("HOME") + "/.config/quickshell/macos/scripts/mac-tahoe-about-info"];
        infoSource.running = true;
    }

    onVisibleChanged: {
        if (aboutWindow.visible) {
            aboutWindow.relativeX = Math.round((Quickshell.screens[0].width - aboutWindow.width) / 2);
            aboutWindow.relativeY = Math.round((Quickshell.screens[0].height - aboutWindow.height) / 2 - 40);
            aboutWindow.refresh();
        }
    }

    // unified glass frame
    Rectangle {
        id: glass
        anchors.fill: parent
        radius: 22
        color: Qt.rgba(0.11, 0.11, 0.13, 0.96)
        border.width: 0.5
        border.color: Qt.rgba(1, 1, 1, 0.12)

        layer.enabled: true

        // drag from anywhere
        MouseArea {
            anchors.fill: parent
            property point clickPos: Qt.point(0, 0)
            onPressed: (mouse) => { clickPos = Qt.point(mouse.x, mouse.y) }
            onPositionChanged: (mouse) => {
                aboutWindow.relativeX += mouse.x - clickPos.x;
                aboutWindow.relativeY += mouse.y - clickPos.y;
            }
        }

        // window buttons
        Row {
            anchors { left: parent.left; top: parent.top; leftMargin: 14; topMargin: 14 }
            spacing: 8
            z: 1

            readonly property color inactiveColor: Qt.rgba(1, 1, 1, 0.2)
            readonly property color inactiveBorder: Qt.rgba(1, 1, 1, 0.08)

            // Close
            Rectangle {
                width: 14; height: 14; radius: 7
                color: "#FF5F57"
                border.width: 0.5
                border.color: Qt.rgba(0, 0, 0, 0.12)

                HoverHandler { id: closeHover }
                Text {
                    anchors.centerIn: parent
                    text: "\u00D7"; color: Qt.rgba(0, 0, 0, 0.5)
                    font.pixelSize: 11; font.bold: true
                    opacity: closeHover.hovered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
                TapHandler { onTapped: aboutWindow.visible = false }
            }

            // Minimize (decorative)
            Rectangle {
                width: 14; height: 14; radius: 7
                color: parent.inactiveColor
                border.width: 0.5
                border.color: parent.inactiveBorder
            }

            // Maximize (decorative)
            Rectangle {
                width: 14; height: 14; radius: 7
                color: parent.inactiveColor
                border.width: 0.5
                border.color: parent.inactiveBorder
            }
        }

        // content
        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item { Layout.preferredHeight: 56 }

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 150
                height: 96

                Rectangle {
                    id: bezel
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 132
                    height: 84
                    radius: 5
                    color: "#1f1f24"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 124
                        height: 76
                        radius: 2
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#7db4ec" }
                            GradientStop { position: 0.45; color: "#4a8fe0" }
                            GradientStop { position: 1.0; color: "#2f66b8" }
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: bezel.bottom
                    anchors.topMargin: -2
                    width: 150
                    height: 7
                    radius: 3.5
                    color: "#cfcfd6"
                }
            }

            Item { Layout.preferredHeight: 18 }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: aboutWindow.vendorDisplay
                color: Appearance.fg
                font.family: aboutWindow.fontFamily
                font.pixelSize: 22
                font.bold: true
                opacity: aboutWindow.infoReady ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
            }

            Item { Layout.preferredHeight: 4 }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    let parts = [];
                    if (aboutWindow.modelDisplay && aboutWindow.modelDisplay.trim())
                        parts.push(aboutWindow.modelDisplay);
                    if (aboutWindow.yearDisplay)
                        parts.push(aboutWindow.yearDisplay);
                    return parts.length ? parts.join(", ") : "\u00A0";
                }
                color: Appearance.fgDim
                font.family: aboutWindow.fontFamily
                font.pixelSize: 13
                opacity: aboutWindow.infoReady ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
            }

            Item { Layout.preferredHeight: 36 }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 2
                columnSpacing: 16
                rowSpacing: 6
                opacity: aboutWindow.infoReady ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutQuad } }

                // Processor
                Text {
                    text: "Processor"
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: 110
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: aboutWindow.chipDisplay
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.preferredWidth: 180
                    Layout.minimumHeight: 2 * _fm.height
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }

                // Graphics
                Text {
                    text: "Graphics"
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: 110
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: aboutWindow.graphicsDisplay
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.preferredWidth: 180
                    Layout.minimumHeight: 2 * _fm.height
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }

                // Memory
                Text {
                    text: "Memory"
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: 110
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: aboutWindow.memoryDisplay
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.preferredWidth: 180
                }

                // Startup disk
                Text {
                    text: "Startup disk"
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: 110
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: aboutWindow.diskDisplay
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.preferredWidth: 180
                    verticalAlignment: Text.AlignVCenter
                }

                // Serial number
                Text {
                    text: "Serial number"
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: 110
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: aboutWindow.serialDisplay
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.preferredWidth: 180
                    elide: Text.ElideRight
                }

                // macOS
                Text {
                    text: "macOS"
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: 110
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: aboutWindow.osDisplay
                    color: "#ffffff"
                    font.bold: true
                    font.family: aboutWindow.fontFamily
                    font.pointSize: 12
                    Layout.preferredWidth: 180
                    Layout.minimumHeight: 2 * _fm.height
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item { Layout.preferredHeight: 22 }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                QQC2.Button {
                    text: "More Info..."
                    font.family: aboutWindow.fontFamily
                    font.pixelSize: 12
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.family: aboutWindow.fontFamily
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6
                        color: "#000000"
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: 1
                    }
                    onClicked: {
                        Apps.launch("systemsettings");
                        aboutWindow.visible = false;
                    }
                }
            }

            Item { Layout.preferredHeight: 16 }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: aboutWindow.osDisplay
                    color: Appearance.fgFaint
                    font.family: aboutWindow.fontFamily
                    font.pixelSize: 11
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "\u2122 and \u00A9 1983\u20132026 Apple Inc."
                    color: Appearance.fgFaint
                    font.family: aboutWindow.fontFamily
                    font.pixelSize: 10
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "All Rights Reserved."
                    color: Appearance.fgFaint
                    font.family: aboutWindow.fontFamily
                    font.pixelSize: 10
                }
            }

            Item { Layout.preferredHeight: 28 }
        }
    }
}
