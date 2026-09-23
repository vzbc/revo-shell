import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property QtObject systemStats
    required property QtObject systemHealth

    signal closeRequested()

    function open() {
        forceActiveFocus();
    }

    function resetTransientState() {
    }

    implicitWidth: theme.dashboardWidth
    implicitHeight: dashboardColumn.implicitHeight + theme.space4 * 2 + theme.shadowOffset
    focus: true
    Keys.onEscapePressed: root.closeRequested()

    Ui.RaisedSurface {
        anchors.fill: parent
        theme: root.theme
        fill: root.theme.surface
        surfaceRadius: root.theme.radiusPanel
        padding: root.theme.space4

        ColumnLayout {
            id: dashboardColumn

            anchors.fill: parent
            spacing: root.theme.space3

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                spacing: root.theme.space3

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: root.theme.radiusControl
                    color: root.theme.green
                    border.width: root.theme.borderWidth
                    border.color: root.theme.ink

                    Image {
                        anchors.centerIn: parent
                        width: root.theme.iconMd
                        height: root.theme.iconMd
                        source: Quickshell.shellDir + "/assets/icons/dashboard.svg"
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "Control desk"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXl
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "A quiet view of system health"
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 34
                    iconSource: Quickshell.shellDir + "/assets/icons/close.svg"
                    accessibleName: "Close control desk"
                    fill: root.theme.surfaceRaised
                    onClicked: root.closeRequested()
                }

            }

            SystemHealth {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                theme: root.theme
                systemStats: root.systemStats
                systemHealth: root.systemHealth
            }

        }

    }

}
