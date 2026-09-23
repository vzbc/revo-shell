pragma ComponentBehavior: Bound

// revo-editorial — Motion Frames × Editorial Collage
// Run: qs -c revo-editorial

import QtQuick
import Quickshell
import Quickshell.Wayland
import "components"

ShellRoot {
    id: root

    // ── Optional Phase 2 + optional qs-install (never forced) ──
    property bool phase2Enabled: false
    property bool runQsInstall: false
    readonly property string qsInstallPath: (Quickshell.env("HOME") || "~") + "/.config/quickshell/qs-install"

    // Shared design tokens
    readonly property color paper: "#F4F1EA"
    readonly property color ink: "#0E0E0C"
    readonly property color accent: "#E23D28"
    readonly property color muted: "#6B675F"
    readonly property string displayFont: "SF Pro"
    readonly property string monoFont: "monospace"

    // Ticking clock
    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    function two(n) {
        return (n < 10 ? "0" : "") + n
    }

    function timeString(d) {
        return two(d.getHours()) + ":" + two(d.getMinutes()) + ":" + two(d.getSeconds())
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 156 + (root.phase2Enabled ? 140 : 0)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "revo-editorial"

            Behavior on implicitHeight {
                NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
            }

            // ══════════════════════════════════════════════
            // Stage: asymmetric editorial grid
            // ══════════════════════════════════════════════
            Item {
                id: stage
                anchors.fill: parent
                anchors.margins: 14

                // ── LEFT · masthead (bold block + ticking issue) ──
                Rectangle {
                    id: masthead
                    x: 0
                    y: 8
                    width: Math.max(220, stage.width * 0.22)
                    height: stage.height - 16
                    color: root.ink
                    radius: 2
                    z: 2

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.topMargin: 6
                        z: -1
                        color: root.accent
                        radius: 2
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 16
                        spacing: 6

                        Text {
                            width: parent.width
                            text: "REVO"
                            color: root.paper
                            font.family: root.displayFont
                            font.pixelSize: 42
                            font.bold: true
                            font.letterSpacing: 6
                            textFormat: Text.PlainText
                        }
                        Text {
                            width: parent.width
                            text: "EDITORIAL / MOTION"
                            color: root.accent
                            font.family: root.displayFont
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            textFormat: Text.PlainText
                        }

                        Row {
                            spacing: 10
                            Text {
                                text: "ISSUE"
                                color: Qt.rgba(1, 1, 1, 0.45)
                                font.family: root.displayFont
                                font.pixelSize: 10
                                font.letterSpacing: 2
                            }
                            Text {
                                text: root.timeString(root.now)
                                color: root.paper
                                font.family: root.monoFont
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }
                    }
                }

                // ── CENTER · overlapping collage ──
                Item {
                    id: collage
                    x: masthead.width + 28
                    y: 0
                    width: Math.max(300, stage.width * 0.48)
                    height: stage.height

                    CollageTile {
                        id: cardA
                        x: 8
                        y: 10
                        width: collage.width * 0.58
                        height: collage.height - 20
                        paper: root.paper
                        ink: root.ink
                        accent: root.accent
                        baseRotation: -1.2
                        featured: true
                        kicker: "SINGLE FRAME"
                        headline: "MOTION"
                        z: 2

                        // print-bar loop under headline
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 14
                            height: 4
                            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12)
                            clip: true

                            Rectangle {
                                width: parent.width * 0.4
                                height: parent.height
                                color: root.accent
                                SequentialAnimation on x {
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: stage.width * 0.2
                                        duration: 1600
                                        easing.type: Easing.InOutCubic
                                    }
                                    NumberAnimation {
                                        to: 0
                                        duration: 1600
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: cardB
                        x: collage.width * 0.42
                        y: 24
                        width: collage.width * 0.42
                        height: collage.height * 0.55
                        color: root.accent
                        rotation: 2.4
                        z: 3
                        border.color: root.ink
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "01"
                            color: root.paper
                            font.family: root.displayFont
                            font.pixelSize: 56
                            font.bold: true
                        }
                    }

                    Rectangle {
                        id: cardC
                        x: collage.width * 0.3
                        y: collage.height * 0.48
                        width: collage.width * 0.55
                        height: collage.height * 0.42
                        color: root.ink
                        rotation: -0.6
                        z: 4
                        border.color: root.accent
                        border.width: 1

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 14
                            text: "COLLAGE"
                            color: root.paper
                            font.family: root.displayFont
                            font.pixelSize: 18
                            font.bold: true
                            font.letterSpacing: 4
                        }

                        // qs-install chip — opt-in only
                        Rectangle {
                            id: qsChip
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: qsChipLabel.implicitWidth + 20
                            height: 26
                            radius: 13
                            color: root.runQsInstall ? "#34D399" : Qt.rgba(1, 1, 1, 0.12)
                            border.color: Qt.rgba(1, 1, 1, 0.25)

                            Text {
                                id: qsChipLabel
                                anchors.centerIn: parent
                                text: root.runQsInstall ? "qs-install ON" : "qs-install off"
                                color: root.runQsInstall ? root.ink : root.paper
                                font.family: root.displayFont
                                font.pixelSize: 10
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runQsInstall = !root.runQsInstall
                            }
                        }
                    }

                    // marquee under collage
                    TickerStrip {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        z: 5
                        text: "SMOOTH LOOPS · ROTATING RINGS · TICKING FRAMES · ASYMMETRIC GRIDS · "
                        fg: root.ink
                        bg: root.paper
                        pixelSize: 10
                    }
                }

                // ── RIGHT · ring + Phase 2 badge ──
                Item {
                    id: rightCol
                    x: collage.x + collage.width + 20
                    width: Math.max(160, stage.width - (collage.x + collage.width + 36))
                    height: stage.height

                    TypographyRing {
                        id: ring
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        width: Math.min(rightCol.width, rightCol.height - 36)
                        height: width
                        ringText: "MOTION FRAMES · EDITORIAL COLLAGE · REVO DOTS · "
                        accent: root.accent
                        ink: root.ink
                        periodMs: 18000
                    }

                    // Phase 2 toggle badge (secondary / optional)
                    Rectangle {
                        id: phase2Badge
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: phase2Row.implicitWidth + 18
                        height: 24
                        radius: 12
                        color: root.phase2Enabled ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12) : "transparent"
                        border.color: root.phase2Enabled ? root.accent : root.muted
                        border.width: 1

                        Row {
                            id: phase2Row
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                radius: 4
                                color: root.phase2Enabled ? root.accent : "transparent"
                                border.color: root.muted
                                border.width: root.phase2Enabled ? 0 : 1
                            }
                            Text {
                                text: "Phase 2 · optional"
                                color: root.phase2Enabled ? root.accent : root.muted
                                font.family: root.displayFont
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.phase2Enabled = !root.phase2Enabled
                        }
                    }
                }
            }

            // ── Phase 2 sheet (optional, sits below the stage) ──
            OptionalPhase2 {
                id: phase2Sheet
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 156
                open: root.phase2Enabled
                runQsInstall: root.runQsInstall
                qsInstallPath: root.qsInstallPath
                paper: root.paper
                ink: root.ink
                accent: root.accent
                muted: root.muted
                onRequestClose: root.phase2Enabled = false
                onRunQsInstallToggled: (enabled) => root.runQsInstall = enabled
            }
        }
    }
}
