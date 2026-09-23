import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia
import Quickshell
import ".."

ColumnLayout {
    id: soundSettingsRoot
    spacing: Config.cardMargin

    // Reusable Geometric / Square Toggle Switch Component
    component ToggleSwitch : Rectangle {
        id: sw
        property bool checked: false
        
        implicitWidth: 40
        implicitHeight: 22
        radius: 6
        color: checked ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.4)
        border.width: sw.checked ? 2 : 1
        border.color: checked ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        // Square Thumb / Slider
        Rectangle {
            id: thumb
            x: sw.checked ? (sw.width - width - 3) : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 4
            color: sw.checked ? Config.accent : Qt.rgba(255, 255, 255, 0.2)
            border.width: 0
            border.color: sw.checked ? Qt.lighter(Config.accent, 1.2) : Qt.rgba(255, 255, 255, 0.25)

            Behavior on x { 
                NumberAnimation { 
                    duration: 160
                    easing.type: Easing.OutCubic 
                } 
            }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
    }

    readonly property var soundFiles: [
        "sound1.wav", "sound2.wav", "sound3.wav",
        "sound4.wav", "sound5.wav", "sound6.wav",
        "sound7.wav", "sound8.wav", "sound9.wav"
    ]

    function formatSoundName(fileName) {
        // Inline Comment: Convert raw filename 'sound1.wav' to display label 'Sound 1'
        let clean = fileName.replace(".wav", "")
        return clean.charAt(0).toUpperCase() + clean.slice(1).replace(/(\d+)/, " $1")
    }

    SoundEffect {
        id: previewPlayer
        volume: 0.25
    }

    function previewSound(fileName) {
        if (!fileName) return
        let baseDir = Quickshell.shellDir.toString()
        if (!baseDir.endsWith("/")) baseDir += "/"
        
        // Inline Comment: Convert to a strict QUrl to keep QtMultimedia happy
        let fullUrl = Qt.resolvedUrl(baseDir + "assets/" + fileName)
        
        previewPlayer.stop()
        previewPlayer.source = fullUrl
        previewPlayer.play()
    }

    Text {
        text: "SYSTEM SOUNDS"
        color: Config.textMain
        font.family: Config.sysFont
        font.pixelSize: Config.size(Config.fontSubhead)
        font.bold: true
    }

    Text {
        text: "Configure audio feedback and select custom sound assets for windows and desktop notifications."
        color: Config.textMuted
        font.family: Config.sysFont
        font.pixelSize: Config.size(Config.fontCaption)
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    // SELECTION CARD: WINDOW SOUNDS
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: windowCol.implicitHeight + 24
        color: Qt.rgba(0, 0, 0, 0.2)
        radius: Config.cornerRadius / 2
        border.width: 0
        opacity: Config.playWindowSounds ? 1.0 : 0.4

        ColumnLayout {
            id: windowCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                Text {
                    text: "web_asset"
                    color: Config.accent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                }

                Text {
                    text: "Windows & Panel Open Sound"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontBody)
                    font.bold: true
                    Layout.fillWidth: true
                }

                ToggleSwitch {
                    checked: Config.playWindowSounds !== false

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Config.isLoaded) {
                                Config.playWindowSounds = !Config.playWindowSounds
                            }
                        }
                    }
                }
            }

            GridLayout {
                columns: 3
                Layout.fillWidth: true
                columnSpacing: 6
                rowSpacing: 6
                enabled: Config.playWindowSounds

                Repeater {
                    model: soundSettingsRoot.soundFiles

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Config.cornerRadius / 2

                        readonly property bool isSelected: Config.windowSoundPath === modelData
                        color: isSelected ? Qt.rgba(255, 255, 255, 0.12) : (btnHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent")
                        border.width: isSelected ? (Config.showBorders ? 2 : 1) : 0
                        border.color: Config.accent

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 4

                            Text {
                                text: isSelected ? "radio_button_checked" : "radio_button_unchecked"
                                color: isSelected ? Config.accent : Config.textMuted
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                            }

                            Text {
                                text: soundSettingsRoot.formatSoundName(modelData)
                                color: isSelected ? Config.accent : Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                font.bold: isSelected
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.windowSoundPath = modelData
                                soundSettingsRoot.previewSound(modelData)
                            }
                        }
                        HoverHandler { id: btnHover }
                    }
                }
            }
        }
    }

    // SELECTION CARD: NOTIFICATION SOUNDS
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: notifCol.implicitHeight + 24
        color: Qt.rgba(0, 0, 0, 0.2)
        radius: Config.cornerRadius / 2
        border.width: 0
        opacity: Config.playNotificationSounds ? 1.0 : 0.4

        ColumnLayout {
            id: notifCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                Text {
                    text: "notifications"
                    color: Config.accent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                }

                Text {
                    text: "Notification Arrival Sound"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontBody)
                    font.bold: true
                    Layout.fillWidth: true
                }

                ToggleSwitch {
                    checked: Config.playNotificationSounds !== false

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Config.isLoaded) {
                                Config.playNotificationSounds = !Config.playNotificationSounds
                            }
                        }
                    }
                }
            }

            GridLayout {
                columns: 3
                Layout.fillWidth: true
                columnSpacing: 6
                rowSpacing: 6
                enabled: Config.playNotificationSounds

                Repeater {
                    model: soundSettingsRoot.soundFiles

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Config.cornerRadius / 2

                        readonly property bool isSelected: Config.notificationSoundPath === modelData
                        color: isSelected ? Qt.rgba(255, 255, 255, 0.12) : (btnHover2.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent")
                        border.width: isSelected ? (Config.showBorders ? 2 : 1) : 0
                        border.color: Config.accent

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 4

                            Text {
                                text: isSelected ? "radio_button_checked" : "radio_button_unchecked"
                                color: isSelected ? Config.accent : Config.textMuted
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                            }

                            Text {
                                text: soundSettingsRoot.formatSoundName(modelData)
                                color: isSelected ? Config.accent : Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                font.bold: isSelected
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.notificationSoundPath = modelData
                                soundSettingsRoot.previewSound(modelData)
                            }
                        }
                        HoverHandler { id: btnHover2 }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}