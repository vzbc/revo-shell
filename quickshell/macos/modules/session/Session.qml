import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../common"

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    visible: ShellController.sessionOpen
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "macos:session"
    WlrLayershell.keyboardFocus: ShellController.sessionOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Dim backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: 0
        NumberAnimation on opacity {
            running: root.visible
            from: 0
            to: 1
            duration: 160
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellController.toggle("session")
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 14
        z: 2

        // Icon
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 72
            Layout.preferredHeight: 72
            radius: 36
            color: Qt.rgba(255, 255, 255, 0.1)
            Text {
                anchors.centerIn: parent
                text: "⏻"
                font { pixelSize: 32 }
                color: Appearance.fg
            }
        }

        // Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "What would you like to do?"
            font { family: Appearance.fontFamily; pixelSize: 18; weight: Font.DemiBold }
            color: Appearance.fg
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.preferredWidth: 300
            Layout.preferredHeight: sessionList.height
            radius: 16
            color: Qt.rgba(0.12, 0.12, 0.14, 0.94)
            border.color: Appearance.border
            border.width: 1

            ColumnLayout {
                id: sessionList
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                component SessionItem: Rectangle {
                    id: item
                    required property string label
                    required property string iconText
                    required property string action
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 10
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        Text {
                            text: item.iconText
                            font { pixelSize: 16 }
                            color: Appearance.fg
                        }
                        Text {
                            Layout.fillWidth: true
                            text: item.label
                            font { family: Appearance.fontFamily; pixelSize: 14 }
                            color: Appearance.fg
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: item.color = Qt.rgba(255, 255, 255, 0.08)
                        onExited: item.color = "transparent"
                        onClicked: {
                            ShellController.closeAll();
                            if (item.action.endsWith("-confirm"))
                                ShellController.requestAction(item.action.replace("-confirm", ""));
                            else
                                ShellController.action(item.action);
                        }
                    }
                }

                SessionItem { label: "Lock Screen"; iconText: "🔒"; action: "lock" }
                SessionItem { label: "Log Out"; iconText: "🚪"; action: "logout-confirm" }
                SessionItem { label: "Sleep"; iconText: "🌙"; action: "sleep" }
                SessionItem { label: "Restart"; iconText: "🔄"; action: "restart-confirm" }
                SessionItem { label: "Shut Down"; iconText: "⏻"; action: "shutdown-confirm" }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    color: Qt.rgba(255, 255, 255, 0.08)
                }

                SessionItem { label: "Cancel"; iconText: "✕"; action: "" }
            }
        }
    }
}
