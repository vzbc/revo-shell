// Stage3Shells.qml — pick ready Quickshell shells as circles
import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    signal confirmed(string shellId, string shellPath)

    // Populated from Python / filesystem scan of ~/.config/quickshell
    property var shells: []
    property string selectedId: ""
    property string selectedPath: ""

    readonly property var selectedShell: {
        for (var i = 0; i < shells.length; i++) {
            if (shells[i].id === selectedId)
                return shells[i]
        }
        return null
    }

    function selectShell(id, path) {
        selectedId = id
        selectedPath = path || ""
    }

    function confirm() {
        if (selectedId.length > 0)
            confirmed(selectedId, selectedPath)
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 880)
        spacing: 40

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Choose a Shell"
                size: 36
                weight: Font.Bold
                tone: "#FFFFFF"
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: shells.length > 0
                      ? "Ready builds from ~/.config/quickshell — tap a circle to select."
                      : "Scanning ~/.config/quickshell for available shells…"
                size: 15
                tone: "#6E6E73"
            }
        }

        // Circle grid
        Flow {
            id: grid
            width: parent.width
            spacing: 36
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: root.shells.length

                delegate: Item {
                    id: cell
                    required property int index
                    readonly property var shell: root.shells[index]

                    width: 140
                    height: 150

                    ShellCircle {
                        id: circle
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        label: ""
                        iconText: shell.icon || (shell.name ? shell.name.substring(0, 2).toUpperCase() : "QS")
                        selected: root.selectedId === shell.id
                        opacity: shell.available !== false ? 1 : 0.4
                        onClicked: root.selectShell(shell.id, shell.path)
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: circle.bottom
                        anchors.topMargin: 12
                        width: parent.width
                        text: shell.name || shell.id
                        size: 13
                        weight: circle.selected ? Font.DemiBold : Font.Normal
                        tone: circle.selected ? "#FFFFFF" : "#A1A1A1"
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Empty state
        Label {
            visible: root.shells.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No shells found yet. Add folders under ~/.config/quickshell and re-open the installer."
            size: 14
            tone: "#6E6E73"
            wrapMode: Text.WordWrap
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        // Confirm bar
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: root.selectedId.length > 0
                      ? "Selected: " + (root.selectedShell ? (root.selectedShell.name || root.selectedId) : root.selectedId)
                      : "Select a shell to continue"
                size: 14
                tone: root.selectedId.length > 0 ? "#FFFFFF" : "#6E6E73"
            }

            Rectangle {
                id: confirmBtn
                enabled: root.selectedId.length > 0
                opacity: enabled ? 1 : 0.4
                height: 46
                width: confirmRow.implicitWidth + 48
                radius: 12
                color: confirmMouse.containsMouse && enabled ? "#E5E5EA" : "#FFFFFF"

                Behavior on color { ColorAnimation { duration: 160 } }

                Row {
                    id: confirmRow
                    anchors.centerIn: parent
                    spacing: 8

                    Label {
                        text: "Confirm Selection"
                        size: 15
                        weight: Font.Medium
                        tone: "#000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        text: "→"
                        size: 16
                        weight: Font.Medium
                        tone: "#000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: confirmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: parent.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.confirm()
                }
            }
        }
    }
}
