import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../Data" as Dat
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import QtQuick.Effects

import qs.Widgets as Wid

Scope {
    id: root
    property bool forcedOpen: false

    IpcHandler {
        target: "searchapp"
        function toggle() {
            root.forcedOpen = !root.forcedOpen;
        }
        function open() {
            root.forcedOpen = true;
        }
        function close() {
            root.forcedOpen = false;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            property var modelData
            screen: modelData
            visible: root.forcedOpen
            anchors {
                top: true
                left: true
                bottom: true
            }
            implicitWidth: 450
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "searchapp"
            WlrLayershell.keyboardFocus: root.forcedOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            property var filteredApps: {
                const stxt = search ? search.text.toLowerCase() : "";
                if (stxt === "")
                    return DesktopEntries.applications.values;
                return DesktopEntries.applications.values.filter(app => {
                    const ntxt = app.name.toLowerCase();
                    let ni = 0;
                    for (let si = 0; si < stxt.length; ++si) {
                        const sc = stxt[si];
                        while (ni < ntxt.length) {
                            if (ntxt[ni++] == sc)
                                break;
                            if (ni == ntxt.length)
                                return false;
                        }
                    }
                    return true;
                });
            }
            Timer {
                id: focusTimer
                interval: 50
                repeat: false
                onTriggered: {
                    if (window.visible) {
                        search.forceActiveFocus();
                        appList.currentIndex = 0;
                    }
                }
            }

            onVisibleChanged: {
                if (visible) {
                    search.text = "";
                    focusTimer.restart();
                }
            }

            Item {
                id: panelRoot
                anchors.left: parent.left
                anchors.leftMargin: 50
                anchors.verticalCenter: parent.verticalCenter
                width: 380
                height: 700
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    color: "transparent"
                    border.color: "#ffffff"
                    border.width: 3
                    radius: 6
                    transform: Matrix4x4 {
                        matrix: Qt.matrix4x4(1, -0.04, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: "#111827"
                    radius: 4
                    opacity: 0.97
                    transform: Matrix4x4 {
                        matrix: Qt.matrix4x4(1, -0.04, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                    }
                }
                Column {
                    anchors.fill: parent
                    anchors.margins: 0
                    spacing: 0
                    Item {
                        width: parent.width
                        height: 80
                        Canvas {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            width: 160
                            height: 50
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.beginPath();
                                ctx.moveTo(0, 0);
                                ctx.lineTo(width, 0);
                                ctx.lineTo(width - 20, height);
                                ctx.lineTo(0, height);
                                ctx.closePath();
                                ctx.fillStyle = "#1a6aff";
                                ctx.fill();
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "APPS"
                                font.pixelSize: 22
                                font.bold: true
                                color: "#ffffff"
                                font.letterSpacing: 3
                            }
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            width: 160
                            height: 32
                            color: "transparent"
                            border.color: "#1a6aff"
                            border.width: 1
                            radius: 3

                            TextInput {
                                id: search
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                color: "#ffffff"
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: 13
                                clip: true

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Search..."
                                    color: "#44ffffff"
                                    font.pixelSize: 13
                                    visible: search.text === ""
                                }

                                Keys.onEscapePressed: root.forcedOpen = false
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Up) {
                                        appList.currentIndex = Math.max(0, appList.currentIndex - 1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Down) {
                                        appList.currentIndex = Math.min(filteredApps.length - 1, appList.currentIndex + 1);
                                        event.accepted = true;
                                    }
                                }
                                onAccepted: {
                                    if (filteredApps.length > 0) {
                                        filteredApps[appList.currentIndex].execute();
                                        root.forcedOpen = false;
                                    }
                                }
                                onTextChanged: appList.currentIndex = 0
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 2
                        color: "#1a6aff"
                        opacity: 0.6
                    }
                    ListView {
                        id: appList
                        width: parent.width
                        height: panelRoot.height - 82
                        clip: true
                        currentIndex: 0
                        model: filteredApps

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 4
                                color: "#1a6aff"
                                opacity: 0.6
                                radius: 2
                            }
                        }

                        delegate: Item {
                            id: delegateRoot
                            required property var modelData
                            required property int index
                            width: appList.width
                            height: 80

                            property bool isActive: appList.currentIndex === index

                            Rectangle {
                                anchors.fill: parent
                                color: delegateRoot.isActive ? "#ffffff" : "transparent"
                                opacity: delegateRoot.isActive ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 4
                                color: "#1a6aff"
                                visible: delegateRoot.isActive
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 0
                                spacing: 0
                                Item {
                                    width: 56
                                    height: parent.height

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 48
                                        height: 48
                                        color: delegateRoot.isActive ? "#1a6aff" : "#1e2a3a"
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            source: delegateRoot.modelData.icon ? "image://icon/" + delegateRoot.modelData.icon : ""
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            visible: status === Image.Ready
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: delegateRoot.modelData.name ? delegateRoot.modelData.name.charAt(0).toUpperCase() : "?"
                                            color: "#ffffff"
                                            font.pixelSize: 18
                                            font.bold: true
                                            visible: parent.children[0].status !== Image.Ready
                                        }
                                    }
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    width: parent.width - 36 - 56 - 16

                                    Row {
                                        spacing: 6

                                        Text {
                                            text: delegateRoot.modelData.name || ""
                                            font.pixelSize: 15
                                            font.bold: true
                                            color: delegateRoot.isActive ? "#111111" : "#ffffff"
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: delegateRoot.modelData.comment || delegateRoot.modelData.genericName || ""
                                        font.pixelSize: 12
                                        color: delegateRoot.isActive ? "#333333" : "#7dd4fc"
                                        elide: Text.ElideRight
                                        width: parent.width
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 36
                                height: 1
                                color: "#ffffff"
                                opacity: 0.08
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: appList.currentIndex = delegateRoot.index
                                onClicked: {
                                    delegateRoot.modelData.execute();
                                    root.forcedOpen = false;
                                }
                            }
                        }
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.forcedOpen = false
            }
        }
    }
}
