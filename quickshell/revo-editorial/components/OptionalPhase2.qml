pragma ComponentBehavior: Bound

// OptionalPhase2 — simplified secondary panel (non-essential by design)
// Surfaces qs-install as an explicit opt-in; never launches automatically.

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: phase2

    property bool open: false
    property bool runQsInstall: false
    property string qsInstallPath: ""
    property color paper: "#F4F1EA"
    property color ink: "#0E0E0C"
    property color accent: "#E23D28"
    property color muted: "#6B675F"

    signal requestClose()
    signal runQsInstallToggled(bool enabled)

    height: open ? Math.max(88, body.implicitHeight + 24) : 0
    visible: height > 0
    Behavior on height {
        NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
    }

    radius: 0
    color: ink
    border.color: accent
    border.width: 1
    clip: true

    ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "PHASE 2 · OPTIONAL"
                color: accent
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 3
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "×"
                color: paper
                font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: phase2.requestClose()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Secondary workflow. Safe to ignore — the motion/editorial surface does not depend on it."
            color: Qt.rgba(1, 1, 1, 0.55)
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        // qs-install toggle — explicit, optional, never forced
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: installBtn.implicitWidth + 28
                Layout.preferredHeight: 36
                radius: 18
                color: phase2.runQsInstall ? accent : "transparent"
                border.color: phase2.runQsInstall ? accent : Qt.rgba(1, 1, 1, 0.3)
                border.width: 1

                Text {
                    id: installBtn
                    anchors.centerIn: parent
                    text: phase2.runQsInstall ? "✓ Queue qs-install" : "Run qs-install?"
                    color: phase2.runQsInstall ? paper : Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: 13
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: phase2.runQsInstallToggled(!phase2.runQsInstall)
                }
            }

            Text {
                Layout.fillWidth: true
                text: phase2.runQsInstall
                      ? ("will execute: " + phase2.qsInstallPath)
                      : "skipped — install stays manual"
                color: muted
                font.family: "monospace"
                font.pixelSize: 11
                elide: Text.ElideMiddle
            }
        }
    }
}
