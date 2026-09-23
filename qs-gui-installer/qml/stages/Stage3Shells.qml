// Stage3Shells.qml — pick ready Quickshell shells as circles
import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    signal confirmed(string shellId, string shellPath)

    // Populated from Python / filesystem scan (monorepo + installed + catalog)
    property var shells: []
    property string selectedId: ""
    property string selectedPath: ""
    property bool loading: false

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
                text: loading
                      ? "Scanning monorepo and ~/.config/quickshell…"
                      : shells.length > 0
                        ? shells.length + " shells ready — tap a circle to select."
                        : "No shells found yet."
                size: 15
                tone: "#6E6E73"
            }
        }

        // Circle grid (scroll when there are many shells)
        Flickable {
            id: flick
            width: parent.width
            height: Math.min(root.height * 0.52, 420)
            contentWidth: width
            contentHeight: grid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Flow {
                id: grid
                width: flick.width
                spacing: 36

                Repeater {
                    model: root.shells

                    delegate: Item {
                        id: cell
                        required property var modelData
                        readonly property var shell: modelData

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

            // Scroll hint when content overflows
            Label {
                visible: flick.contentHeight > flick.height
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Scroll for more ↓"
                size: 11
                tone: "#6E6E73"
            }
        }

        // Empty state
        Label {
            visible: root.shells.length === 0 && !root.loading
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No shells found. Run the installer from the revo-shell monorepo, or install first, then come back."
            size: 14
            tone: "#6E6E73"
            wrapMode: Text.WordWrap
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        // Auto-select first shell so users are never stuck on an empty choice
        Component.onCompleted: Qt.callLater(function() {
            if (root.selectedId.length < 1 && root.shells.length > 0)
                root.selectShell(root.shells[0].id, root.shells[0].path)
        })

        onShellsChanged: {
            if (root.selectedId.length < 1 && root.shells.length > 0)
                root.selectShell(root.shells[0].id, root.shells[0].path)
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
