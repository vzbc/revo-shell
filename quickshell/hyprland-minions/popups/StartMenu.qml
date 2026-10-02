import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.config

// Start menu: glossy side banner, type-to-search application list and
// session buttons. Up/Down + Enter work from the search box; if nothing
// matches, Enter runs the text as a shell command.
BarPopup {
    id: menu

    property string query: ""

    signal themesRequested()

    readonly property var apps: [...DesktopEntries.applications.values]
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var results: {
        const q = query.trim().toLowerCase()
        if (q === "") return apps
        const matches = apps.filter(a =>
            [a.name, a.genericName, a.comment, ...a.keywords].join(" ").toLowerCase().includes(q))
        // Names that start with the query first.
        return matches.sort((a, b) =>
            (b.name.toLowerCase().startsWith(q) - a.name.toLowerCase().startsWith(q)) || a.name.localeCompare(b.name))
    }

    function launch(entry) {
        if (entry) {
            if (entry.runInTerminal)
                Quickshell.execDetached([Theme.terminal, "-e", ...entry.command])
            else
                entry.execute()
        } else if (query.trim() !== "") {
            Quickshell.execDetached(["sh", "-c", query])
        }
        close()
    }

    align: Qt.AlignLeft
    padding: 0
    implicitWidth: 300
    implicitHeight: 440

    onShownChanged: {
        if (!shown) return
        search.text = ""
        list.currentIndex = 0
        list.positionViewAtBeginning()
        search.focusInput()
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        // Vertical banner
        Bevel {
            Layout.fillHeight: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            Layout.leftMargin: 6
            implicitWidth: 28
            radius: Theme.radiusLarge - 4
            faceColor: Theme.selection

            BarText {
                rotation: -90
                x: (parent.width - width) / 2
                y: parent.height - 14 - height / 2 - width / 2
                text: Theme.startLabel
                font.pixelSize: 16
                font.bold: true
                color: Theme.selectionText
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 6
            spacing: 6

            TextField {
                id: search

                Layout.fillWidth: true
                placeholder: "Search or run..."
                onTextChanged: {
                    menu.query = text
                    list.currentIndex = 0
                }
                onAccepted: menu.launch(menu.results[list.currentIndex] ?? null)
                onDownPressed: list.incrementCurrentIndex()
                onUpPressed: list.decrementCurrentIndex()
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Bevel {
                    anchors.fill: parent
                    sunken: true
                    faceColor: Theme.field
                }

                ListView {
                    id: list

                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0
                    model: menu.results

                    delegate: MenuRow {
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        icon: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        text: modelData.name
                        highlighted: ListView.isCurrentItem
                        onHoveredChanged: if (hovered) list.currentIndex = index
                        onClicked: menu.launch(modelData)
                    }
                }

                MenuRow {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 4
                    visible: menu.results.length === 0 && menu.query.trim() !== ""
                    highlighted: true
                    text: "Run: " + menu.query
                    onClicked: menu.launch(null)
                }
            }

            BarButton {
                Layout.fillWidth: true
                implicitHeight: 26
                text: "Themes..."
                onClicked: menu.themesRequested()
            }

            Separator {
                vertical: false
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 4
                columnSpacing: 4

                SessionButton {
                    label: "Log Off"
                    command: ["hyprctl", "dispatch", Hyprland.usingLua ? "hl.dsp.exit()" : "exit"]
                }

                SessionButton {
                    label: "Suspend"
                    confirm: false
                    command: ["loginctl", "suspend"]
                }

                SessionButton {
                    label: "Restart"
                    command: ["loginctl", "reboot"]
                }

                SessionButton {
                    label: "Shut Down"
                    command: ["loginctl", "poweroff"]
                }
            }
        }
    }

    // Needs a second click within a few seconds, so a stray click doesn't
    // power the machine off.
    component SessionButton: BarButton {
        id: button

        required property var command
        property bool confirm: true
        property bool armed: false
        property string label

        Layout.fillWidth: true
        implicitHeight: 26
        active: armed
        text: armed ? "Sure?" : label

        onClicked: {
            if (confirm && !armed) {
                armed = true
                disarm.restart()
                return
            }
            armed = false
            menu.close()
            Quickshell.execDetached(command)
        }

        Timer {
            id: disarm
            interval: 3000
            onTriggered: button.armed = false
        }

        Connections {
            target: menu

            function onShownChanged() {
                button.armed = false
            }
        }
    }
}
