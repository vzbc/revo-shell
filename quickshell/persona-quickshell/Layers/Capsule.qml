import Quickshell.Wayland
import Quickshell
import "../Data" as Dat
import "../Widgets" as Wid
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Scope {
    id: capsuleScope
    property var mpris: Mpris.players.values[0] || null
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: pmusicWindow
            anchors {
                bottom: true
                left: true
            }
            required property var modelData
            screen: modelData
            color: "transparent"
            implicitWidth: 800
            implicitHeight: 300
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "music-player-interactive"
            focusable: false

            Image {
                id: dialogueBox
                source: "../Assets/components/player.png"
                transformOrigin: Item.Center
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -170
                anchors.verticalCenterOffset: -15
                width: 500
                height: 500
                rotation: 10
                fillMode: Image.PreserveAspectFit
            }

            Item {
                anchors.centerIn: dialogueBox
                anchors.horizontalCenterOffset: 70
                anchors.verticalCenterOffset: 10
                rotation: 10
                width: 100
                height: 60

                Row {
                    anchors.centerIn: parent
                    spacing: -10
                    // Track info
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        width: 80
                        leftPadding: 20
                        anchors.verticalCenterOffset: -15

                        Item {
                            width: parent.width
                            height: artistMarquee.implicitHeight + 3
                            Wid.Marquee {
                                id: artistMarquee
                                anchors.bottom: parent.bottom
                                text: capsuleScope.mpris ? (capsuleScope.mpris.trackArtist || "") : ""
                                maxWidth: 100
                                font: "Linux Biolinum"
                                size: 12
                                color: Dat.Colors.color3
                                scrollRate: 50
                                pauseDuration: 2000
                                visible: text !== ""
                            }
                        }

                        Item {
                            width: parent.width
                            height: songname.implicitHeight - 20
                            Wid.Marquee {
                                id: songname
                                text: capsuleScope.mpris ? (capsuleScope.mpris.trackTitle || "No title") : "No Media"
                                maxWidth: 100
                                font: "Linux Biolinum"
                                size: 16
                                color: "black"
                                scrollRate: 50
                                pauseDuration: 2000
                            }
                        }
                    }

                    // Disk + prev/next
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        leftPadding: 50
                        Item {
                            width: 106
                            height: 1
                            Item {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30

                                Text {
                                    id: prevIcon
                                    anchors.centerIn: parent
                                    text: "skip_previous"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 30
                                    color: prevMouse.containsMouse ? Dat.Colors.color3 : Dat.Colors.color15
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                                MouseArea {
                                    id: prevMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (capsuleScope.mpris?.canGoPrevious)
                                        capsuleScope.mpris.previous()
                                }
                            }

                            Item {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -5
                                width: 60
                                height: 60

                                Image {
                                    id: imgDisk
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    fillMode: Image.PreserveAspectCrop
                                    source: capsuleScope.mpris ? (capsuleScope.mpris.trackArtUrl || "") : ""
                                    smooth: true
                                    mipmap: true
                                    layer.enabled: true
                                    layer.smooth: true
                                    layer.effect: MultiEffect {
                                        antialiasing: true
                                        maskEnabled: true
                                        maskSpreadAtMin: 1.0
                                        maskThresholdMax: 1.0
                                        maskThresholdMin: 0.5
                                        maskSource: Image {
                                            layer.smooth: true
                                            mipmap: true
                                            smooth: true
                                            source: "../Assets/components/AlbumCover-by-Squirrel-Modeller.svg"
                                        }
                                    }
                                    Behavior on rotation {
                                        NumberAnimation {
                                            duration: diskTimer.interval
                                            easing.type: Easing.Linear
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (capsuleScope.mpris?.canTogglePlaying)
                                        capsuleScope.mpris.togglePlaying()
                                    onEntered: imgDisk.scale = 0.8
                                    onExited: imgDisk.scale = 1.0
                                }
                                Timer {
                                    id: diskTimer
                                    interval: 500
                                    repeat: true
                                    running: capsuleScope.mpris !== null && capsuleScope.mpris.playbackState === MprisPlaybackState.Playing
                                    onTriggered: imgDisk.rotation += 3
                                }
                            }

                            Item {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30

                                Text {
                                    id: nextIcon
                                    anchors.centerIn: parent
                                    text: "skip_next"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 30
                                    color: nextMouse.containsMouse ? Dat.Colors.color3 : Dat.Colors.color15
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                                MouseArea {
                                    id: nextMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (capsuleScope.mpris?.canGoNext)
                                        capsuleScope.mpris.next()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
