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
    width: 364
    height: root.current ? Math.max(86, Math.min(notifCol.height + 28, 190)) : 86
    color: "transparent"
    visible: root.current !== null && !NotificationDaemon.popupInhibited

    property var current: null
    property bool hovered: popMouse.containsMouse

    Connections {
        target: Notifications
        function onNotify(notification) {
            root.current = notification;
            root._timer.restart();
            contentRect.y = -14;
            contentRect.opacity = 0;
            enterAnim.start();
            enterFade.start();
        }
        function onDiscard(id) {
            if (root.current && root.current.id === id) root.current = null;
        }
    }

    Timer {
        id: _timer
        interval: 4000
        onTriggered: root.current = null
    }

    MouseArea {
        id: popMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            const n = root.current;
            root.current = null;
            if (n) Notifications.dismiss(n);
        }
    }

    NumberAnimation {
        id: enterAnim
        target: contentRect
        property: "y"
        to: 0
        duration: 280
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: enterFade
        target: contentRect
        property: "opacity"
        to: 1
        duration: 200
    }

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(0.18, 0.18, 0.22, 0.5)
        border.color: Appearance.menuBorder
        border.width: 1

        Item {
            x: 14
            y: 15
            width: 44
            height: 44

            Rectangle {
                anchors.fill: parent
                radius: 10
                visible: iconImg.status !== Image.Ready
                color: "#315bdc"

                Text {
                    anchors.centerIn: parent
                    text: "🔔"
                    font.pixelSize: 20
                }
            }

            Image {
                id: iconImg
                anchors.fill: parent
                source: root.current ? Notifications.iconFor(root.current) : ""
                sourceSize.width: 96
                sourceSize.height: 96
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: status === Image.Ready
            }
        }

        Column {
            id: notifCol
            x: 70
            y: 14
            width: parent.width - 70 - 40
            spacing: 1

            Text {
                width: parent.width
                text: root.current?.appName ?? ""
                font { family: Appearance.fontFamily; pixelSize: 14; weight: Font.DemiBold }
                color: Appearance.fgDim
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.current?.summary ?? ""
                font { family: Appearance.fontFamily; pixelSize: 14; weight: Font.Bold }
                color: "#ffffff"
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: root.current ? !!root.current.body : false
                text: root.current?.body ?? ""
                font { family: Appearance.fontFamily; pixelSize: 13 }
                color: Appearance.fgDim
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: closeButton
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 10
            width: 22
            height: 22
            radius: 11
            color: closeArea.containsMouse ? Appearance.fieldHover : Qt.rgba(1, 1, 1, 0.08)
            visible: root.hovered

            Text {
                anchors.centerIn: parent
                text: "✕"
                font { family: Appearance.fontFamily; pixelSize: 11 }
                color: Appearance.fgDim
            }
            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    const n = root.current;
                    root.current = null;
                    if (n) Notifications.dismiss(n);
                }
            }
        }
    }
}
