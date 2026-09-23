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
    visible: ShellController.pendingConfirm !== ""
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "macos:confirmdialog"
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property color accent: "#315bdc"

    readonly property string actionName: {
        if (ShellController.pendingConfirm === "restart") return "Restart";
        if (ShellController.pendingConfirm === "shutdown") return "Shut Down";
        if (ShellController.pendingConfirm === "logout") return "Log Out";
        return "";
    }

    readonly property string iconText: {
        if (ShellController.pendingConfirm === "restart") return "\u21BB";
        if (ShellController.pendingConfirm === "shutdown") return "\u23FB";
        if (ShellController.pendingConfirm === "logout") return "\u21A9";
        return "";
    }

    readonly property string message: {
        if (ShellController.pendingConfirm === "restart") return "Are you sure you want to restart your computer now?";
        if (ShellController.pendingConfirm === "shutdown") return "Are you sure you want to shut down your computer now?";
        if (ShellController.pendingConfirm === "logout") return "Are you sure you want to quit all applications and log out now?";
        return "";
    }

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
        onClicked: ShellController.cancelPending()
    }

    Rectangle {
        id: dialog
        width: 360
        height: dialogColumn.implicitHeight + 40
        anchors.centerIn: parent
        radius: 18
        color: Qt.rgba(0.13, 0.13, 0.15, 0.97)
        border.color: Appearance.border
        border.width: 1
        z: 2

        scale: root.visible ? 1 : 0.92
        opacity: root.visible ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: dialogColumn
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // Icon circle
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: 32
                color: Qt.rgba(255, 255, 255, 0.08)
                Text {
                    anchors.centerIn: parent
                    text: root.iconText
                    font { family: Appearance.fontFamily; pixelSize: 28 }
                    color: Appearance.fg
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.actionName
                font { family: Appearance.fontFamily; pixelSize: 16; weight: Font.DemiBold }
                color: Appearance.fg
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.message
                font { family: Appearance.fontFamily; pixelSize: 13 }
                color: Appearance.fgDim
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 10

                component DialogButton: Rectangle {
                    id: dlgBtn
                    property string label: ""
                    property bool primary: false
                    property var onClick: null
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: primary ? root.accent : Qt.rgba(255, 255, 255, 0.09)
                    Text {
                        anchors.centerIn: parent
                        text: dlgBtn.label
                        font { family: Appearance.fontFamily; pixelSize: 13; weight: Font.DemiBold }
                        color: "#ffffff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: dlgBtn.color = dlgBtn.primary ? Qt.lighter(root.accent, 1.15) : Qt.rgba(255, 255, 255, 0.15)
                        onExited: dlgBtn.color = dlgBtn.primary ? root.accent : Qt.rgba(255, 255, 255, 0.09)
                        onClicked: if (dlgBtn.onClick) dlgBtn.onClick()
                    }
                }

                DialogButton {
                    label: "Cancel"
                    onClick: () => ShellController.cancelPending()
                }
                DialogButton {
                    label: root.actionName
                    primary: true
                    onClick: () => ShellController.confirmPending()
                }
            }
        }
    }
}
