import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications as Notifs

Item {
    id: notifModuleRoot

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    // Bind to global shellRoot activeNotifs property safely
    readonly property int activeCount: (typeof shellRoot !== "undefined" && shellRoot.activeNotifs !== undefined) ? shellRoot.activeNotifs : 0

    function clearAll() {
        if (typeof notifServer === "undefined" || !notifServer.trackedNotifications) return;
        let notifs = notifServer.trackedNotifications.values;
        if (!notifs) return;
        
        // Loop backwards to dismiss safely
        for (let i = notifs.length - 1; i >= 0; i--) {
            if (notifs[i]) {
                notifs[i].dismiss();
            }
        }
        if (typeof shellRoot !== "undefined" && shellRoot.updateNotifCount) {
            Qt.callLater(shellRoot.updateNotifCount);
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: notifModuleRoot.cardMargin
        spacing: notifModuleRoot.cardMargin

        // Main Card Container
        Rectangle {
            Layout.fillWidth: true
            implicitWidth: 360
            implicitHeight: cardContent.implicitHeight + (notifModuleRoot.cardMargin * 2)
            color: Qt.rgba(1, 1, 1, 0.05)
            radius: Config.cornerRadius
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // GRAPHIC WATERMARK
            Watermark {
                icon: Config.getIcon("notifications")
                iconSize: 150
                seed: 10
            }

            ColumnLayout {
                id: cardContent
                anchors.fill: parent
                anchors.margins: notifModuleRoot.cardMargin
                spacing: notifModuleRoot.cardMargin

                // Header Section
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Dynamic Notification Icon
                    Text {
                        text: notifModuleRoot.activeCount > 0 ? "notifications_active" : "notifications"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: Config.size(Config.fontTitle)
                        color: notifModuleRoot.activeCount > 0 ? Config.accent : Config.textMain

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item {
                        implicitWidth: notifTitleText.implicitWidth
                        implicitHeight: notifTitleText.implicitHeight
                        Layout.fillWidth: true

                        Glow {
                            anchors.fill: notifTitleText
                            source: notifTitleText
                            radius: 8
                            samples: 16
                            color: Config.accent
                            spread: 0.2
                            transparentBorder: true
                            visible: Config.clockShowGlow
                        }

                        Text {
                            id: notifTitleText
                            anchors.fill: parent
                            text: "NOTIFICATIONS"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                        }
                    }

                    Rectangle {
                        implicitWidth: clearText.implicitWidth + 12
                        implicitHeight: 24
                        radius: Config.cornerRadius / 2
                        color: clearHover.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: notifModuleRoot.activeCount > 0

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "CLEAR ALL"
                            color: clearHover.hovered ? Config.accent : Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TapHandler {
                            onTapped: notifModuleRoot.clearAll()
                        }

                        HoverHandler {
                            id: clearHover
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                // Scrollable Cards List
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: notifModuleRoot.activeCount > 0 
                        ? Math.min(scrollContent.implicitHeight, 320) 
                        : emptyStateContainer.implicitHeight
                    color: "transparent"
                    clip: true

                    Behavior on implicitHeight {
                        NumberAnimation { duration: 150 }
                    }

                    Flickable {
                        anchors.fill: parent
                        contentHeight: scrollContent.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: scrollContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 8

                            Repeater {
                                model: (typeof notifServer !== "undefined" && notifServer.trackedNotifications) 
                                    ? notifServer.trackedNotifications.values 
                                    : []

                                delegate: Rectangle {
                                    id: notifCard
                                    width: scrollContent.width
                                    Layout.fillWidth: true
                                    implicitHeight: cardTextCol.implicitHeight + (notifModuleRoot.cardMargin * 2)
                                    radius: Config.cornerRadius / 2
                                    color: itemHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.15)

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    ColumnLayout {
                                        id: cardTextCol
                                        anchors.fill: parent
                                        anchors.margins: notifModuleRoot.cardMargin
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: (modelData && modelData.appName) ? modelData.appName.toUpperCase() : "SYSTEM"
                                                color: Config.accent
                                                font.family: Config.sysFont
                                                font.pixelSize: Config.size(Config.fontBody)
                                                font.bold: true
                                                font.italic: true
                                                font.letterSpacing: 0.8
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            visible: modelData && modelData.summary !== ""
                                            text: (modelData && modelData.summary) ? modelData.summary : ""
                                            color: Config.textMain
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontSubhead)
                                            font.bold: true
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                        }

                                        Text {
                                            visible: modelData && modelData.body !== ""
                                            text: (modelData && modelData.body) ? modelData.body : ""
                                            color: Config.textMuted
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontBody)
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                        }
                                    }

                                    // Floating Close Button Box
                                    Rectangle {
                                        id: closeBtnRect
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.rightMargin: notifModuleRoot.cardMargin - 2
                                        anchors.topMargin: notifModuleRoot.cardMargin - 2
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        radius: 11
                                        color: closeHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                                        opacity: itemHover.hovered ? 1.0 : 0.0
                                        z: 5

                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on opacity { NumberAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "close"
                                            color: closeHover.hovered ? Config.accent : Config.textMuted
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 16

                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        TapHandler {
                                            onTapped: {
                                                if (modelData) {
                                                    modelData.dismiss();
                                                }
                                            }
                                        }

                                        HoverHandler {
                                            id: closeHover
                                            cursorShape: Qt.PointingHandCursor
                                        }
                                    }

                                    HoverHandler {
                                        id: itemHover
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }

                            // Empty State
                            ColumnLayout {
                                id: emptyStateContainer
                                Layout.fillWidth: true
                                spacing: 6
                                visible: notifModuleRoot.activeCount === 0
                                Layout.alignment: Qt.AlignHCenter

                                Text {
                                    Layout.fillWidth: true
                                    text: "inbox"
                                    color: Config.textMuted
                                    opacity: 0.5
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 28
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "No active notifications"
                                    color: Config.textMuted
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}