import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../../services"
import "../common"

Item {
    id: root

    Layout.preferredWidth: collapsedPill.width
    Layout.preferredHeight: parent ? parent.height : 28
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

    // ── state ─────────────────────────────────────────────────────
    property bool expanded: false
    property bool showNotification: false

    // ── media ─────────────────────────────────────────────────────
    property var activePlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    readonly property bool isPlaying: activePlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing) : false
    readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "No Media Playing") : "macOS Tahoe"
    readonly property string trackArtist: activePlayer ? (activePlayer.trackArtists ? activePlayer.trackArtists.join(", ") : "") : "Quickshell"
    readonly property string artUrl: activePlayer ? (activePlayer.artUrl || "") : ""

    // ── notification ──────────────────────────────────────────────
    readonly property var notif: Notifications.latest
    readonly property string notifIcon: notif ? Notifications.iconFor(notif) : ""
    readonly property var notifActions: notif ? Notifications.buttons(notif) : []

    // expand on song change
    onTrackTitleChanged: {
        if (isPlaying && !showNotification) {
            root.expanded = true
            autoCollapseTimer.restart()
        }
    }

    // expand on new notification
    Connections {
        target: Notifications
        function onNotify() {
            root.showNotification = true
            root.expanded = true
            notifTimer.restart()
        }
    }

    Timer {
        id: autoCollapseTimer
        interval: 3500
        onTriggered: {
            if (!pillMouseArea.containsMouse && !popupMouseArea.containsMouse)
                root.expanded = false
        }
    }

    Timer {
        id: notifTimer
        interval: 5000
        onTriggered: {
            if (!pillMouseArea.containsMouse && !popupMouseArea.containsMouse) {
                root.showNotification = false
                root.expanded = false
                Notifications.dismissToast()
            }
        }
    }

    // ─── Collapsed Pill ──────────────────────────────────────────
    Rectangle {
        id: collapsedPill
        anchors.centerIn: parent

        width: {
            if (root.showNotification && root.notif)
                return Math.min(Math.max(notifTitleMetrics.width + 70, 160), 260)
            if (root.isPlaying)
                return Math.min(Math.max(titleMetrics.width + 65, 150), 220)
            return 120
        }
        height: 24
        radius: 12

        color: "#0a0a0c"
        border.color: root.expanded ? "#315bdc" : Qt.rgba(1, 1, 1, 0.18)
        border.width: 1

        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        TextMetrics {
            id: titleMetrics
            text: root.trackTitle
            font { family: Appearance.fontFamily; pixelSize: 11; weight: Font.DemiBold }
        }

        TextMetrics {
            id: notifTitleMetrics
            text: root.notif ? root.notif.summary : ""
            font { family: Appearance.fontFamily; pixelSize: 11; weight: Font.DemiBold }
        }

        MouseArea {
            id: pillMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.expanded = true
            onExited: {
                if (!autoCollapseTimer.running && !notifTimer.running && !popupMouseArea.containsMouse)
                    root.expanded = false
            }
            onClicked: root.expanded = !root.expanded
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            // icon
            Rectangle {
                width: 14; height: 14; radius: 7
                color: root.showNotification ? "#e74c3c" : (root.isPlaying ? "#315bdc" : "#44444c")
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.showNotification ? root.notifIcon : ""
                    fillMode: Image.PreserveAspectFit
                    visible: root.showNotification && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.showNotification
                    text: root.isPlaying ? "🎵" : ""
                    font.pixelSize: 9
                }
            }

            // label
            Text {
                Layout.fillWidth: true
                text: root.showNotification && root.notif
                    ? root.notif.summary.replace(/\s*\n\s*/g, " ")
                    : root.trackTitle
                font { family: Appearance.fontFamily; pixelSize: 11; weight: Font.DemiBold }
                color: "#ffffff"
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // equalizer (media only)
            Row {
                spacing: 2
                visible: root.isPlaying && !root.showNotification
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 2
                        height: index === 1 ? 10 : (index === 0 ? 6 : 8)
                        radius: 1
                        color: "#315bdc"

                        SequentialAnimation on height {
                            running: root.isPlaying
                            loops: Animation.Infinite
                            NumberAnimation { to: 12; duration: 300 + index * 100 }
                            NumberAnimation { to: 4; duration: 300 + index * 100 }
                        }
                    }
                }
            }

            // close btn (notification)
            Rectangle {
                width: 14; height: 14; radius: 7
                color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                visible: root.showNotification
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 8
                    color: "#a0a0a8"
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.notif) Notifications.dismiss(root.notif)
                        root.showNotification = false
                        root.expanded = false
                    }
                }
            }
        }
    }

    // ─── Expanded Popup ──────────────────────────────────────────
    PopupWindow {
        id: islandPopup
        visible: root.expanded
        color: "transparent"

        anchor.window: root.Window.window
        anchor.rect.x: (root.Window.window ? root.Window.window.width / 2 - 170 : 0)
        anchor.rect.y: Appearance.barHeight + 6

        implicitWidth: 340
        implicitHeight: root.showNotification ? 94 : 94

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#0d0d11"
            border.color: Qt.rgba(1, 1, 1, 0.22)
            border.width: 1

            scale: root.expanded ? 1.0 : 0.85
            opacity: root.expanded ? 1.0 : 0.0

            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
            Behavior on opacity { NumberAnimation { duration: 180 } }

            MouseArea {
                id: popupMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onExited: {
                    if (!pillMouseArea.containsMouse)
                        root.expanded = false
                }
                onClicked: {
                    if (root.showNotification && root.notif) {
                        Notifications.activate(root.notif)
                        Notifications.dismissToast()
                        root.showNotification = false
                        root.expanded = false
                    }
                }
            }

            // ── notification view ──
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                visible: root.showNotification && root.notif

                Rectangle {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    Layout.alignment: Qt.AlignVCenter
                    radius: 14
                    color: "#1a1a22"
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 8
                        source: root.notifIcon
                        fillMode: Image.PreserveAspectFit
                        visible: root.notifIcon.length > 0 && status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.notifIcon.length === 0
                        text: "🔔"
                        font.pixelSize: 24
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: root.notif ? root.notif.appName : ""
                        font { family: Appearance.fontFamily; pixelSize: 10; weight: Font.DemiBold }
                        color: "#a0a0a8"
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.notif ? root.notif.summary.replace(/\s*\n\s*/g, " ") : ""
                        font { family: Appearance.fontFamily; pixelSize: 13; weight: Font.Bold }
                        color: "#ffffff"
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.notif && !!root.notif.body
                        text: root.notif ? root.notif.body.replace(/\s*\n\s*/g, " ") : ""
                        font { family: Appearance.fontFamily; pixelSize: 11 }
                        color: "#a0a0a8"
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                    }

                    // action buttons
                    RowLayout {
                        visible: root.notifActions.length > 0
                        spacing: 6
                        Layout.topMargin: 2

                        Repeater {
                            model: root.notifActions

                            delegate: Rectangle {
                                id: actionChip
                                required property var modelData
                                Layout.preferredWidth: Math.min(actionLabel.implicitWidth + 16, 120)
                                Layout.preferredHeight: 22
                                radius: 11
                                color: actionMouse.containsMouse ? "#315bdc" : "#1a1a22"

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: actionChip.modelData.text
                                    font { family: Appearance.fontFamily; pixelSize: 10; weight: Font.DemiBold }
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Notifications.invokeAction(root.notif, actionChip.modelData)
                                        Notifications.dismissToast()
                                        root.showNotification = false
                                        root.expanded = false
                                    }
                                }
                            }
                        }
                    }
                }

                // close
                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 11
                    color: notifCloseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 10
                        color: "#a0a0a8"
                    }

                    MouseArea {
                        id: notifCloseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.notif) Notifications.dismiss(root.notif)
                            root.showNotification = false
                            root.expanded = false
                        }
                    }
                }
            }

            // ── media view ──
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 14
                visible: !root.showNotification

                Rectangle {
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 68
                    radius: 12
                    color: "#1a1a22"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: root.artUrl !== ""
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.artUrl === ""
                        text: "🎵"
                        font.pixelSize: 32
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: root.trackTitle
                        font { family: Appearance.fontFamily; pixelSize: 14; weight: Font.Bold }
                        color: "#ffffff"
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackArtist
                        font { family: Appearance.fontFamily; pixelSize: 12 }
                        color: "#a0a0a8"
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        spacing: 20
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            text: "⏮"
                            font.pixelSize: 18
                            color: "#ffffff"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.activePlayer) root.activePlayer.previous()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 14
                            color: "#315bdc"

                            Text {
                                anchors.centerIn: parent
                                text: root.isPlaying ? "⏸" : "▶"
                                font.pixelSize: 13
                                color: "#ffffff"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.activePlayer) root.activePlayer.playPause()
                            }
                        }

                        Text {
                            text: "⏭"
                            font.pixelSize: 18
                            color: "#ffffff"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.activePlayer) root.activePlayer.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
