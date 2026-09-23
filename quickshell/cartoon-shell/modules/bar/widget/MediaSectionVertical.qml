import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services
import qs.commons
import qs.components

Item {
    id: root
    property real animationProgress: 0
    ColumnLayout {
        anchors.fill: parent
        spacing: ScalerService.s(8)
        Item {

            Layout.fillWidth: true
            Layout.fillHeight: true

            // Xoay toàn bộ container 90 độ để text chạy dọc
            Item {
                anchors.centerIn: parent
                width: parent.height  // Đảo width và height
                height: parent.width
                rotation: -90
                transformOrigin: Item.Center
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        SoundService.playSound("pick");
                        VisibleService.togglePanel("music");
                    }
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                }

                // Text container bên trong (đã xoay)
                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScalerService.s(2)
                    clip: true

                    // Song title
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(10)

                        Text {
                            id: songTextVertical
                            text: Players.mprisPlayer?.trackTitle ?? "Not Playing"
                            color: theme.primary.foreground
                            font.family: "ComicShannsMono Nerd Font"
                            font.pixelSize: ScalerService.s(12)
                            width: parent.width
                            opacity: root.animationProgress > 0.25 ? 1 : 0

                            // Marquee effect ngang (sẽ thành dọc sau khi xoay)
                            x: 0

                            property bool needsMarquee: contentHeight > parent.height

                            SequentialAnimation on y {
                                id: artistMarqueeAnimation
                                running: artistTextVertical.needsMarquee
                                loops: Animation.Infinite

                                PauseAnimation {
                                    duration: 2000
                                }
                                NumberAnimation {
                                    to: -(artistTextVertical.contentHeight - parent.height)
                                    duration: Math.max(2000, (artistTextVertical.contentHeight - parent.height) * 20)
                                    easing.type: Easing.Linear
                                }
                                PauseAnimation {
                                    duration: 2000
                                }
                                NumberAnimation {
                                    to: 0
                                    duration: Math.max(2000, (artistTextVertical.contentHeight - parent.height) * 20)
                                    easing.type: Easing.Linear
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }

                    // Artist name
                    CustomText {
                        name: Players.mprisPlayer ? (Players.mprisPlayer.trackArtist || "Unknown Artist") : "Unknown Artist"
                        color: theme.primary.dim_foreground
                        opacity: root.animationProgress > 0.3 ? 1 : 0
                        size: "xs"
                        width: parent.width
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: ScalerService.s(8)
            Layout.preferredHeight: ScalerService.s(24)

            // Play/Pause button
            ButtonIconText {
                name: Players.mprisPlayer && Players.mprisPlayer.isPlaying ? "pause" : "play_arrow"
                size: "small"

                opacity: root.animationProgress > 0.35 ? 1 : 0
                Layout.alignment: Qt.AlignVCenter
                onClicked: Players?.mprisPlayer.togglePlaying()
            }
        }
    }
}
