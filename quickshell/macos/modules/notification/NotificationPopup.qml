import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core.system
import "../../services"
import "../common"

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors {
        top: true
        right: true
    }
    margins {
        top: 44
        right: 10
    }
    width: 390
    height: root.current && root.current.body ? 110 : 82
    color: "transparent"
    visible: root.current !== null && !NotificationDaemon.popupInhibited

    property var current: null

    Connections {
        target: Notifications
        function onNotify(notification) {
            root.current = notification;
            root._timer.restart();
        }
        function onDiscard(id) {
            if (root.current && root.current.id === id) root.current = null;
        }
    }

    Timer {
        id: _timer
        interval: 7000
        onTriggered: root.current = null
    }

    // Whole-popup click -> dismiss (plain Rectangle below does not block it)
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.current) Notifications.dismiss(root.current);
            root.current = null;
        }
    }

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(0.10, 0.10, 0.12, 0.92)
        border.color: Appearance.border
        border.width: 1
        opacity: 0
        NumberAnimation on opacity {
            running: root.current !== null
            from: 0
            to: 1
            duration: 200
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Image {
                id: appIcon
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                source: root.current ? Notifications.iconFor(root.current) : ""
                asynchronous: true
                mipmap: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    Layout.fillWidth: true
                    text: root.current?.appName ?? ""
                    font { family: Appearance.fontFamily; pixelSize: 12; weight: Font.DemiBold }
                    color: Appearance.fgDim
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.current?.summary ?? ""
                    font { family: Appearance.fontFamily; pixelSize: 13; weight: Font.DemiBold }
                    color: Appearance.fg
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.current ? !!root.current.body : false
                    text: root.current?.body ?? ""
                    font { family: Appearance.fontFamily; pixelSize: 12 }
                    color: Appearance.fgDim
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }
            }

            Rectangle {
                id: closeButton
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 11
                color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font { family: Appearance.fontFamily; pixelSize: 11 }
                    color: Appearance.fgDim
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: closeButton.color = Appearance.fieldHover
                    onExited: closeButton.color = "transparent"
                    onClicked: {
                        if (root.current) Notifications.dismiss(root.current);
                        root.current = null;
                    }
                }
            }
        }
    }
}
