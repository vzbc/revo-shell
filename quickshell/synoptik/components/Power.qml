import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: powerModule

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    property int activeHoverIndex: -1
    property string activeProfile: "balanced"

    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    // FETCH CURRENT POWER PROFILE ON LOAD
    Process {
        id: getProfileProcess
        command: ["powerprofilesctl", "get"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                let p = data.trim()
                if (p.length > 0) powerModule.activeProfile = p
            }
        }
    }

    // FUNCTION TO SET PROFILE VIA POWERPROFILESCTL
    function setPowerProfile(profile) {
        powerModule.activeProfile = profile
        Quickshell.execDetached(["powerprofilesctl", "set", profile])
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: powerModule.cardMargin
        spacing: powerModule.cardMargin / 2

        // ==========================================
        // POWER CARD (Title + Actions)
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitWidth: 412
            implicitHeight: cardLayout.implicitHeight + (powerModule.cardMargin * 2)
            color: Qt.rgba(255, 255, 255, 0.05)
            radius: Config.cornerRadius
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // GRAPHIC WATERMARK
            Watermark {
                icon: Config.getIcon("power")
                iconSize: 150
                seed: 17
            }

            ColumnLayout {
                id: cardLayout
                anchors.fill: parent
                anchors.margins: powerModule.cardMargin
                spacing: powerModule.cardMargin

                Item {
                    implicitWidth: powerTitleText.implicitWidth
                    implicitHeight: powerTitleText.implicitHeight
                    Layout.fillWidth: true

                    Glow {
                        anchors.fill: powerTitleText
                        source: powerTitleText
                        radius: 8
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow
                    }

                    Text {
                        id: powerTitleText
                        anchors.fill: parent
                        text: "POWER OPTIONS"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontTitle)
                        font.bold: true
                        font.italic: true
                    }
                }

                RowLayout {
                    id: actionRow
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { icon: "lock", label: "Lock", cmd: ["hyprlock"] },
                            { icon: "bedtime", label: "Suspend", cmd: ["systemctl", "suspend"] },
                            { icon: "logout", label: "Log Out", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
                            { icon: "restart_alt", label: "Reboot", cmd: ["systemctl", "reboot"] },
                            { icon: "power_settings_new", label: "Power Off", cmd: ["systemctl", "poweroff"] }
                        ]

                        delegate: Rectangle {
                            id: actionBtn

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 68
                            radius: Config.cornerRadius / 2

                            color: powerModule.activeHoverIndex === index
                                ? Qt.rgba(255, 255, 255, 0.12)
                                : (btnHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                            Behavior on color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - 4
                                spacing: 4

                                Text {
                                    text: modelData.icon
                                    font.family: "Material Symbols Outlined"
                                    font.weight: Font.Bold
                                    font.pixelSize: 24
                                    color: powerModule.activeHoverIndex === index ? Config.accent : Config.textMain
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontMicro)
                                    font.bold: true
                                    color: powerModule.activeHoverIndex === index ? Config.accent : Config.textMuted
                                    Layout.alignment: Qt.AlignHCenter
                                    elide: Text.ElideNone
                                    maximumLineCount: 1
                                }
                            }

                            HoverHandler {
                                id: btnHover
                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: {
                                    if (hovered) powerModule.activeHoverIndex = index;
                                    else if (powerModule.activeHoverIndex === index) powerModule.activeHoverIndex = -1;
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    Config.showPower = false;
                                    if (modelData.label === "Lock") {
                                        Config.sessionLocked = true;
                                    } else {
                                        Quickshell.execDetached(modelData.cmd);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // POWER PROFILE SELECTOR CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: profileCardLayout.implicitHeight + (powerModule.cardMargin * 2)
            color: Qt.rgba(255, 255, 255, 0.05)
            radius: Config.cornerRadius
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // GRAPHIC WATERMARK
            Watermark {
                icon: "speed"
                iconSize: 150
                seed: 18
            }

            ColumnLayout {
                id: profileCardLayout
                anchors.fill: parent
                anchors.margins: powerModule.cardMargin
                spacing: powerModule.cardMargin

                Text {
                    text: "POWER PROFILE"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "power-saver", label: "Saver", icon: "eco" },
                            { id: "balanced", label: "Balanced", icon: "balance" },
                            { id: "performance", label: "Performance", icon: "speed" }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 40
                            radius: Config.cornerRadius / 2

                            readonly property bool isActive: powerModule.activeProfile === modelData.id

                            color: isActive 
                                ? Config.accent 
                                : (profHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: isActive ? Config.bgBase : Config.textMain
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: true
                                    color: isActive ? Config.bgBase : Config.textMain
                                }
                            }

                            HoverHandler {
                                id: profHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: powerModule.setPowerProfile(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}