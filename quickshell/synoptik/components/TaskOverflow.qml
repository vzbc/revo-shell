import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

Item {
    id: overflowRoot

    // Inline Comment: Card margin token pulled from global Config
    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    property string activeScreenName: ""

    // Inline Comment: Running client instances on current active display
    readonly property var activeClients: Hyprland.toplevels.values.filter(c => !activeScreenName || !c.monitor || c.monitor.name === overflowRoot.activeScreenName)

    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: overflowRoot.cardMargin
        spacing: overflowRoot.cardMargin

        // Inner Surface Frame
        Rectangle {
            Layout.fillWidth: true
            implicitWidth: 270
            implicitHeight: cardContentLayout.implicitHeight + (overflowRoot.cardMargin * 2)
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // GRAPHIC WATERMARK
            Watermark {
                icon: Config.getIcon("apps")
                iconSize: 120
                seed: 12
            }

            ColumnLayout {
                id: cardContentLayout
                anchors.fill: parent
                anchors.margins: overflowRoot.cardMargin
                spacing: 8

                // Header
                Item {
                    implicitWidth: taskTitleText.implicitWidth
                    implicitHeight: taskTitleText.implicitHeight
                    Layout.fillWidth: true

                    Glow {
                        anchors.fill: taskTitleText
                        source: taskTitleText
                        radius: 8
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow
                    }

                    Text {
                        id: taskTitleText
                        anchors.fill: parent
                        text: "RUNNING TASKS"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontTitle)
                        font.bold: true
                        font.italic: true
                    }
                }

                Text {
                    visible: overflowRoot.activeClients.length === 0
                    text: "No active windows"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }

                // Single Column Task List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: overflowRoot.activeClients

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: Config.cornerRadius / 2
                            color: itemHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.25)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            readonly property string appId: modelData.wayland?.appId || modelData.lastIpcObject?.class || ""

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                IconImage {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    asynchronous: true
                                    source: {
                                        let id = parent.parent.appId
                                        if (!id) return ""
                                        let entry = DesktopEntries.heuristicLookup(id)
                                        if (entry && entry.icon) {
                                            let path = Quickshell.iconPath(entry.icon, true)
                                            if (path) return path
                                        }
                                        return Quickshell.iconPath(id, true) || Quickshell.iconPath("application-x-executable", true)
                                    }
                                }

                                Text {
                                    text: modelData.title || parent.parent.appId || "Window"
                                    color: modelData.activated ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: modelData.activated
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    if (modelData.wayland) modelData.wayland.activate()
                                    Config.showTaskOverflow = false
                                }
                            }
                            HoverHandler { id: itemHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }
        }
    }
}