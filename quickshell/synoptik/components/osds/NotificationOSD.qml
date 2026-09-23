import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Notifications as Notifs
import ".."

Item {
    id: osdRoot

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    // Static bounds to prevent UnifiedSurface evaluation loops
    implicitWidth: 500
    implicitHeight: Math.max(80, contentColumn.implicitHeight + (cardMargin * 4))

    property string notifTitle: ""
    property string notifBody: ""
    property string notifApp: ""
    property int notifUrgency: Notifs.NotificationUrgency.Normal

    SoundEffect {
        id: notifSoundPlayer
        // Inline Comment: Dynamically target notification sound WAV asset from Quickshell directory
        source: Qt.resolvedUrl(Quickshell.shellDir.toString() + "/assets/" + (Config.notificationSoundPath || "sound1.wav"))
        volume: 0.25
    }

    function playNotificationSound() {
        if (!Config.playNotificationSounds) return
        // Inline Comment: Instant sample trigger without FFmpeg demuxer buffer rewinds
        notifSoundPlayer.play()
    }

    readonly property string appIcon: {
        let app = osdRoot.notifApp.toLowerCase()
        if (app.includes("discord") || app.includes("vesktop")) return "forum"
        if (app.includes("spotify") || app.includes("music")) return "music_note"
        if (app.includes("terminal") || app.includes("kitty") || app.includes("foot")) return "terminal"
        if (app.includes("code") || app.includes("nvim")) return "code"
        if (app.includes("firefox") || app.includes("chrome") || app.includes("browser")) return "language"
        if (app.includes("steam") || app.includes("game")) return "sports_esports"
        return "notifications_active"
    }

    Connections {
        target: (typeof notifServer !== "undefined" && notifServer !== null) ? notifServer : null
        ignoreUnknownSignals: true

        function onNotification(notif) {
            if (!notif) return;
            notif.tracked = true;

            // Block OSD if DND is active or if the main Notification panel is already open
            if ((typeof notifServer !== "undefined" && notifServer && notifServer.dnd) || (typeof Config.showNotifications !== "undefined" && Config.showNotifications)) return;

            osdRoot.notifApp = notif.appName ? notif.appName : "System";
            osdRoot.notifTitle = notif.summary ? notif.summary : "Notification";
            osdRoot.notifBody = notif.body ? notif.body : "";
            osdRoot.notifUrgency = notif.urgency;
            
            osdRoot.trigger();
        }
    }

    function trigger() {
        osdHideTimer.stop()
        Config.showNotificationOsd = true
        
        // Play notification arrival sound effect
        osdRoot.playNotificationSound()

        if (osdRoot.notifUrgency !== Notifs.NotificationUrgency.Critical) {
            osdHideTimer.restart()
        }
    }

    function dismiss() {
        Config.showNotificationOsd = false
        osdHideTimer.stop()
    }

    Timer {
        id: osdHideTimer
        interval: 4000
        repeat: false
        onTriggered: osdRoot.dismiss()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: osdRoot.dismiss()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: osdRoot.cardMargin
        spacing: osdRoot.cardMargin

        Rectangle {
            implicitWidth: 48
            implicitHeight: 48
            radius: Config.cornerRadius / 2
            color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: osdRoot.appIcon
                color: osdRoot.notifUrgency === Notifs.NotificationUrgency.Critical ? "#ef4444" : Config.accent
                font.family: "Material Symbols Outlined"
                font.pixelSize: 24
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Config.cornerRadius / 2
            color: Qt.rgba(255, 255, 255, 0.05)

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.leftMargin: osdRoot.cardMargin
                anchors.rightMargin: osdRoot.cardMargin
                anchors.topMargin: osdRoot.cardMargin
                anchors.bottomMargin: osdRoot.cardMargin
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: senderText.implicitHeight

                        Text {
                            id: senderText
                            anchors.fill: parent
                            text: osdRoot.notifApp.toUpperCase()
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            font.italic: true
                            font.letterSpacing: 0.8
                            elide: Text.ElideRight
                        }

                        Glow {
                            anchors.fill: senderText
                            source: senderText
                            radius: 8
                            samples: 24
                            color: Config.accent
                            spread: 0.1
                            visible: true 
                        }
                    }

                    Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 11
                        color: closeArea.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            color: closeArea.containsMouse ? Config.accent : Config.textMuted
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                mouse.accepted = true
                                osdRoot.dismiss()
                            }
                        }
                    }
                }

                Text {
                    text: osdRoot.notifTitle
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontSubhead)
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    visible: osdRoot.notifBody !== ""
                    text: osdRoot.notifBody
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontBody)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}