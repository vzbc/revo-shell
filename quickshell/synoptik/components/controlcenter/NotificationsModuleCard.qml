import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications as Notifs
import ".."

Item {
    id: cardRoot

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.alignment: Qt.AlignTop

    implicitHeight: 64
    Layout.preferredHeight: 64
    z: panelExpanded ? 1000 : 1

    property Item controlCenterPanel: null
    property bool panelExpanded: false
    property bool shouldExpand: panelExpanded

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    readonly property int activeCount: (typeof shellRoot !== "undefined" && shellRoot.activeNotifs !== undefined) ? shellRoot.activeNotifs : 0

    onVisibleChanged: {
        if (!visible) panelExpanded = false
    }

    function clearAll() {
        if (typeof notifServer === "undefined" || !notifServer.trackedNotifications) return;
        let notifs = notifServer.trackedNotifications.values;
        if (!notifs) return;
        
        for (let i = notifs.length - 1; i >= 0; i--) {
            if (notifs[i]) {
                notifs[i].dismiss();
            }
        }
        if (typeof shellRoot !== "undefined" && shellRoot.updateNotifCount) {
            Qt.callLater(shellRoot.updateNotifCount);
        }
    }

    readonly property real collapsedX: {
        let p0 = cardRoot
        let p1 = p0 ? p0.parent : null
        let p2 = p1 ? p1.parent : null
        let p3 = p2 ? p2.parent : null
        let p4 = p3 ? p3.parent : null
        
        return (p0 ? p0.x : 0) + (p1 ? p1.x : 0) + (p2 ? p2.x : 0) + (p3 ? p3.x : 0) + (p4 ? p4.x : 0)
    }

    readonly property real collapsedY: {
        let p0 = cardRoot
        let p1 = p0 ? p0.parent : null
        let p2 = p1 ? p1.parent : null
        let p3 = p2 ? p2.parent : null
        let p4 = p3 ? p3.parent : null
        
        return (p0 ? p0.y : 0) + (p1 ? p1.y : 0) + (p2 ? p2.y : 0) + (p3 ? p3.y : 0) + (p4 ? p4.y : 0)
    }

    Rectangle {
        id: visualBackground
        parent: controlCenterPanel ? controlCenterPanel : cardRoot.parent.parent.parent
        z: cardRoot.panelExpanded ? 1000 : 100
        clip: true
        
        x: cardRoot.panelExpanded ? cardRoot.cardMargin : cardRoot.collapsedX
        y: cardRoot.panelExpanded ? cardRoot.cardMargin : cardRoot.collapsedY
        width: cardRoot.panelExpanded ? (controlCenterPanel ? (controlCenterPanel.width - (cardRoot.cardMargin * 2)) : 400) : cardRoot.width
        height: cardRoot.panelExpanded ? (controlCenterPanel ? (controlCenterPanel.height - (cardRoot.cardMargin * 2)) : 500) : 64
        
        radius: Config.cornerRadius
        
        color: cardRoot.panelExpanded
            ? Qt.rgba(Config.bgBase.r, Config.bgBase.g, Config.bgBase.b, 1.0)
            : (cardHover.hovered ? Qt.rgba(Config.bgBase.r, Config.bgBase.g, Config.bgBase.b, 0.85) : Qt.rgba(0, 0, 0, 0.25))
        border.width: 1
        border.color: cardRoot.panelExpanded ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        HoverHandler {
            id: cardHover
            enabled: !cardRoot.panelExpanded
        }

        MouseArea {
            anchors.fill: parent
            enabled: cardRoot.panelExpanded
            preventStealing: true
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => mouse.accepted = true
            onReleased: (mouse) => mouse.accepted = true
            onClicked: (mouse) => mouse.accepted = true
        }

        TapHandler {
            enabled: cardRoot.panelExpanded
            gesturePolicy: TapHandler.WithinBounds
            onTapped: {}
        }

        // --- 1. COLLAPSED CARD HEADER VIEW ---
        Item {
            id: collapsedView
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64
            visible: opacity > 0
            enabled: !cardRoot.panelExpanded
            opacity: cardRoot.panelExpanded ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Item {
                anchors.fill: parent
                anchors.margins: 10

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: Config.cornerRadius / 2
                        color: cardRoot.activeCount > 0 
                            ? (iconHover.hovered ? Qt.lighter(Config.accent, 1.1) : Config.accent)
                            : (iconHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08))
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: cardRoot.activeCount > 0 ? "notifications_active" : "notifications"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: cardRoot.activeCount > 0 ? Config.bgBase : Config.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cardRoot.panelExpanded = true
                        }
                        HoverHandler { id: iconHover }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        clip: true

                        Text {
                            text: "Notifications"
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            color: Config.textMain
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: cardRoot.activeCount > 0 ? (cardRoot.activeCount + " active") : "Inbox Clear"
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: cardRoot.activeCount > 0
                            color: cardRoot.activeCount > 0 ? Config.accent : Config.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "chevron_right"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: cardHover.hovered ? Config.textMain : Config.textMuted
                        opacity: 0.7
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.leftMargin: 52
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cardRoot.panelExpanded = true
                }
            }
        }

        // --- 2. EXPANDED FULL PANEL VIEW ---
        Item {
            id: expandedView
            anchors.fill: parent
            anchors.margins: 14
            visible: opacity > 0
            enabled: cardRoot.panelExpanded
            opacity: cardRoot.panelExpanded ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            RowLayout {
                id: notifHeaderRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 44
                spacing: 10

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    Layout.alignment: Qt.AlignVCenter
                    color: backHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 2
                    border.color: backHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: backHover.hovered ? Config.accent : Config.textMain
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.panelExpanded = false
                    }
                    HoverHandler { id: backHover }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Item {
                        implicitWidth: notifExpTitleText.implicitWidth
                        implicitHeight: notifExpTitleText.implicitHeight
                        Layout.fillWidth: true

                        Text {
                            id: notifExpTitleText
                            text: "NOTIFICATIONS"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                            elide: Text.ElideRight
                        }

                        Glow {
                            anchors.fill: notifExpTitleText
                            source: notifExpTitleText
                            radius: 6
                            samples: 12
                            color: Config.accent
                            spread: 0.2
                            transparentBorder: true
                            visible: Config.clockShowGlow
                        }
                    }

                    Text {
                        text: cardRoot.activeCount > 0 ? (cardRoot.activeCount + " unread alerts") : "No incoming alerts"
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        color: cardRoot.activeCount > 0 ? Config.accent : Config.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    implicitWidth: clearText.implicitWidth + 14
                    implicitHeight: 32
                    radius: 16
                    Layout.alignment: Qt.AlignVCenter
                    visible: cardRoot.activeCount > 0
                    color: clearHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 2
                    border.color: clearHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "CLEAR ALL"
                        color: clearHover.hovered ? Config.accent : Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.clearAll()
                    }
                    HoverHandler { id: clearHover }
                }
            }

            Item {
                anchors.top: notifHeaderRow.bottom
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true

                ListView {
                    id: notifListView
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    model: (typeof notifServer !== "undefined" && notifServer.trackedNotifications) 
                        ? notifServer.trackedNotifications.values 
                        : []

                    delegate: Rectangle {
                        id: notifCard
                        width: notifListView.width
                        implicitHeight: cardTextCol.implicitHeight + 18
                        radius: Config.cornerRadius * 0.5
                        color: itemHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            id: cardTextCol
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 9
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: (modelData && modelData.appName) ? modelData.appName.toUpperCase() : "SYSTEM"
                                    color: Config.accent
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontMicro)
                                    font.bold: true
                                    font.italic: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                visible: modelData && modelData.summary !== ""
                                text: (modelData && modelData.summary) ? modelData.summary : ""
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                font.bold: true
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            Text {
                                visible: modelData && modelData.body !== ""
                                text: (modelData && modelData.body) ? modelData.body : ""
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontMicro)
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.rightMargin: 8
                            anchors.topMargin: 8
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: closeHover.hovered ? Qt.rgba(255, 255, 255, 0.2) : "transparent"
                            opacity: itemHover.hovered ? 1.0 : 0.0
                            z: 5

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                color: closeHover.hovered ? Config.accent : Config.textMuted
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                            }

                            TapHandler {
                                onTapped: {
                                    if (modelData) modelData.dismiss();
                                }
                            }
                            HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                        }

                        HoverHandler { id: itemHover }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: cardRoot.activeCount === 0

                    Text {
                        text: "inbox"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 48
                        color: Config.textMuted
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "No Active Notifications"
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                        color: Config.textMain
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "You're all caught up! New alerts will appear here."
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        color: Config.textMuted
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.maximumWidth: 260
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}