import QtQuick
import QtQuick.Controls
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
    visible: ShellController.forceQuitOpen
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "macos:forcequit"
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property color accent: "#315bdc"

    property string selectedAppId: ""

    // Unique running app ids from live toplevels
    readonly property var runningIds: {
        const ids = [];
        const seen = {};
        const tops = ToplevelManager.toplevels?.values ?? [];
        for (const t of tops) {
            if (!t || !t.appId || seen[t.appId]) continue;
            seen[t.appId] = true;
            ids.push(t.appId);
        }
        return ids;
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
        onClicked: ShellController.closeAll()
    }

    Rectangle {
        id: dialog
        width: 420
        height: dialogColumn.implicitHeight + 36
        anchors.centerIn: parent
        radius: 18
        color: Qt.rgba(0.13, 0.13, 0.15, 0.97)
        border.color: Appearance.border
        border.width: 1
        z: 2

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: dialogColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Force Quit Applications"
                font { family: Appearance.fontFamily; pixelSize: 15; weight: Font.DemiBold }
                color: Appearance.fg
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "If an app doesn't respond for a while, select its name and click Force Quit."
                font { family: Appearance.fontFamily; pixelSize: 12 }
                color: Appearance.fgDim
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(260, Math.max(120, list.contentHeight))
                radius: 10
                color: Qt.rgba(0, 0, 0, 0.28)
                border.color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                clip: true

                ListView {
                    id: list
                    anchors.fill: parent
                    anchors.margins: 4
                    model: root.runningIds
                    spacing: 2
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: list.contentHeight > list.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    }

                    delegate: Rectangle {
                        id: row
                        required property string modelData
                        required property int index
                        width: list.width
                        height: 40
                        radius: 8
                        color: root.selectedAppId === row.modelData
                            ? root.accent
                            : (rowMa.containsMouse ? Qt.rgba(255, 255, 255, 0.07) : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Image {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                source: DockApps.iconSource(DockApps.iconFor(row.modelData))
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.charAt(0).toUpperCase() + row.modelData.slice(1)
                                font { family: Appearance.fontFamily; pixelSize: 13 }
                                color: "#ffffff"
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedAppId = row.modelData
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.runningIds.length === 0
                    text: "No running applications"
                    font { family: Appearance.fontFamily; pixelSize: 13 }
                    color: Appearance.fgDim
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                component DialogButton: Rectangle {
                    id: dlgBtn
                    property string label: ""
                    property bool primary: false
                    property bool enabledBtn: true
                    property var onClick: null
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 10
                    opacity: dlgBtn.enabledBtn ? 1 : 0.45
                    color: primary ? root.accent : Qt.rgba(255, 255, 255, 0.09)
                    Text {
                        anchors.centerIn: parent
                        text: dlgBtn.label
                        font { family: Appearance.fontFamily; pixelSize: 13; weight: Font.DemiBold }
                        color: "#ffffff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: dlgBtn.enabledBtn
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: dlgBtn.color = dlgBtn.primary ? Qt.lighter(root.accent, 1.15) : Qt.rgba(255, 255, 255, 0.15)
                        onExited: dlgBtn.color = dlgBtn.primary ? root.accent : Qt.rgba(255, 255, 255, 0.09)
                        onClicked: if (dlgBtn.onClick) dlgBtn.onClick()
                    }
                }

                DialogButton {
                    label: "Cancel"
                    onClick: () => ShellController.closeAll()
                }
                DialogButton {
                    label: "Force Quit"
                    primary: true
                    enabledBtn: root.selectedAppId !== ""
                    onClick: () => {
                        if (!root.selectedAppId) return;
                        DockApps.forceKillApp([root.selectedAppId]);
                        root.selectedAppId = "";
                        ShellController.closeAll();
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (root.visible) GlobalFocusGrab.addDismissable(root);
        else { GlobalFocusGrab.removeDismissable(root); root.selectedAppId = ""; }
    }

    Connections {
        target: GlobalFocusGrab
        function onDismissed() { ShellController.closeAll(); }
    }
}
