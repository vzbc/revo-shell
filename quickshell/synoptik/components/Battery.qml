import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    property string battName: (typeof shellRoot !== "undefined" && shellRoot.hasBattery) ? shellRoot.battName : "BAT0"
    property int battCapacity: (typeof shellRoot !== "undefined" && shellRoot.hasBattery) ? shellRoot.battCapacity : 0
    property string battStatus: (typeof shellRoot !== "undefined" && shellRoot.hasBattery) ? shellRoot.battStatus : "Discharging"
    property string powerDraw: "2.4"

    // Periodic poller for power consumption details
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!battDetailProc.running) {
                battDetailProc.running = true
            }
        }
    }

    // Detailed Stats Poller
    Process {
        id: battDetailProc
        command: ["fish", "-c", "cat /sys/class/power_supply/" + root.battName + "/power_now 2>/dev/null; or echo 0"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(this.text.trim()) || 0
                if (val > 0) {
                    root.powerDraw = (val / 1000000.0).toFixed(1)
                }
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: root.cardMargin
        spacing: root.cardMargin / 2

        // Card 1: Title, Charging Status, & Capacity Track
        Rectangle {
            Layout.fillWidth: true
            implicitWidth: 360
            implicitHeight: topCardContent.implicitHeight + (root.cardMargin * 2)
            radius: Config.cornerRadius
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // GRAPHIC WATERMARK
            Watermark {
                icon: Config.getIcon("batt")
                iconSize: 150
                seed: 22
            }

            ColumnLayout {
                id: topCardContent
                anchors.fill: parent
                anchors.margins: root.cardMargin
                spacing: root.cardMargin

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: {
                            if (root.battStatus === "Charging") return "battery_android_frame_bolt"
                            if (root.battCapacity <= 10) return "battery_android_0"
                            if (root.battCapacity <= 25) return "battery_android_frame_1"
                            if (root.battCapacity <= 40) return "battery_android_frame_2"
                            if (root.battCapacity <= 60) return "battery_android_frame_3"
                            if (root.battCapacity <= 75) return "battery_android_frame_4"
                            if (root.battCapacity <= 90) return "battery_android_frame_5"
                            if (root.battCapacity < 100) return "battery_android_frame_6"
                            return "battery_android_frame_full"
                        }
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: Config.size(Config.fontTitle)
                        color: Config.textMain
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        implicitWidth: battTitleText.implicitWidth
                        implicitHeight: battTitleText.implicitHeight
                        Layout.fillWidth: true

                        Glow {
                            anchors.fill: battTitleText
                            source: battTitleText
                            radius: 8
                            samples: 16
                            color: Config.accent
                            spread: 0.2
                            transparentBorder: true
                            visible: Config.clockShowGlow
                        }

                        Text {
                            id: battTitleText
                            anchors.fill: parent
                            text: "BATTERY"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                        }
                    }

                    Rectangle {
                        implicitWidth: statusText.implicitWidth + 12
                        implicitHeight: 22
                        radius: Config.cornerRadius / 2
                        color: root.battStatus === "Charging" ? Qt.rgba(16, 185, 129, 0.2) : Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: root.battStatus.toUpperCase()
                            color: root.battStatus === "Charging" ? Config.accent : Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                        }
                    }
                }

                // Battery Status Track Row
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: root.battCapacity + "% Available"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontSubhead)
                        font.bold: true
                    }

                    // Slider Container
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 40

                        // Unclipped glow layer matching track corner radius
                        RectangularGlow {
                            id: activeGlow
                            anchors.fill: battFillContainer
                            glowRadius: 16
                            spread: 0.2
                            color: root.battCapacity <= 15 ? "#ef4444" : Config.accent
                            cornerRadius: battTrack.radius
                            opacity: root.battStatus === "Charging" && battFillContainer.width > 0 ? 0.5 : 0.0

                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // Unclipped reference container tracking physical fill dimensions
                        Item {
                            id: battFillContainer
                            x: battTrack.x
                            y: battTrack.y
                            height: battTrack.height

                            readonly property real targetRatio: Math.max(0.0, Math.min(1.0, root.battCapacity / 100.0))

                            width: targetRatio <= 0 ? 0 : Math.max(height, battTrack.width * targetRatio)

                            Behavior on width {
                                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                            }
                        }

                        // Progress Track
                        Rectangle {
                            id: battTrack
                            anchors.fill: parent
                            radius: Config.cornerRadius / 1.5
                            color: Qt.rgba(0, 0, 0, 0.35)
                            clip: true

                            Rectangle {
                                id: battFill
                                width: battFillContainer.width
                                height: parent.height
                                radius: Config.cornerRadius / 1.5
                                color: root.battCapacity <= 15 ? "#ef4444" : Config.accent
                            }
                        }
                    }
                }
            }
        }

        // Bottom Stats Row
        RowLayout {
            Layout.fillWidth: true
            spacing: root.cardMargin

            // Card 2: Device Stats
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Config.cornerRadius
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.1)
                clip: true

                Behavior on border.color { ColorAnimation { duration: 150 } }

                // GRAPHIC WATERMARK
                Watermark {
                    icon: "devices"
                    iconSize: 80
                    seed: 23
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: "DEVICE"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.battName
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Card 3: Discharge Stats
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Config.cornerRadius
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.1)
                clip: true

                Behavior on border.color { ColorAnimation { duration: 150 } }

                // GRAPHIC WATERMARK
                Watermark {
                    icon: "bolt"
                    iconSize: 80
                    seed: 24
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: "DISCHARGE"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.powerDraw + " W"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}