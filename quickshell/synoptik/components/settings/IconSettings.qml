import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

ColumnLayout {
    id: iconSettingsRoot
    anchors.fill: parent
    spacing: Config.cardMargin / 2 || 10

    property string selectedIconId: ""
    property string searchQuery: ""
    property var allIconsList: []
    property bool isLoadingIcons: true

    // Helper check to disable reordering for unselected or workspace icons
    readonly property bool canMoveSelected: {
        if (!iconSettingsRoot.selectedIconId) return false
        if (iconSettingsRoot.selectedIconId === "batt" || iconSettingsRoot.selectedIconId === "cc") return false
        return Config.leftCardOrder.includes(iconSettingsRoot.selectedIconId) 
            || Config.rightCardOrder.includes(iconSettingsRoot.selectedIconId)
    }

    Process {
        id: iconFetcher
        running: true
        command: ["fish", "-c", "
            if test -f /usr/share/fonts/material-symbols/MaterialSymbolsOutlined.codepoints;
                cat /usr/share/fonts/material-symbols/MaterialSymbolsOutlined.codepoints | cut -d' ' -f1;
            else if test -f ~/.local/share/fonts/MaterialSymbolsOutlined.codepoints;
                cat ~/.local/share/fonts/MaterialSymbolsOutlined.codepoints | cut -d' ' -f1;
            else
                curl -sS --max-time 10 'https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsOutlined%5BFILL%2CGRAD%2Copsz%2Cwght%5D.codepoints' | cut -d' ' -f1;
            end
        "]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text ? this.text.trim() : ""
                if (txt.length > 0) {
                    let lines = txt.split('\n').map(l => l.trim()).filter(l => l.length > 0)
                    iconSettingsRoot.allIconsList = lines
                }
                iconSettingsRoot.isLoadingIcons = false
            }
        }
    }

    Text {
        text: "CUSTOMIZE ICONS"
        color: Config.textMain
        font.family: Config.sysFont
        font.pixelSize: Config.size(Config.fontSubhead)
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            id: iconHelpText
            textFormat: Text.StyledText
            text: 'Click any icon in the bar mockup to select it, or search installed Material Symbols below. You can also browse glyph names on <a href="https://fonts.google.com/icons">fonts.google.com/icons</a>.'
            color: Config.textMuted
            linkColor: Config.accent
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontCaption)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap

            onLinkActivated: function(link) {
                Qt.openUrlExternally(link)
            }

            HoverHandler {
                cursorShape: iconHelpText.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }

    // --- MULTI-ROW BAR MOCKUP SECTION ---
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: mockupColumn.implicitHeight + 12
        radius: Config.cornerRadius / 2
        color: Qt.rgba(0, 0, 0, 0.25)

        ColumnLayout {
            id: mockupColumn
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6

            // Dynamic label width matching the longest text string automatically
            readonly property real labelWidth: Math.max(leftLabel.implicitWidth, rightLabel.implicitWidth)

            // ROW 1: LEFT MODULES
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    id: leftLabel
                    text: "Left/Top Icons:"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    font.bold: true
                    Layout.preferredWidth: mockupColumn.labelWidth
                    verticalAlignment: Text.AlignVCenter
                }

                // Dynamic Pill Capsule (snug to icon content)
                Rectangle {
                    implicitWidth: leftIconsRow.implicitWidth + 12
                    implicitHeight: 30
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(255, 255, 255, 0.05)

                    RowLayout {
                        id: leftIconsRow
                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: (Config.leftCardOrder || ["power", "recorder", "mirror", "network", "clipboard", "wallpaper", "launcher", "audio", "settings", "screenshot"]).filter(id => id !== "batt")

                            delegate: Rectangle {
                                implicitWidth: 26; implicitHeight: 26; radius: 6
                                readonly property bool isSelected: iconSettingsRoot.selectedIconId === modelData
                                color: isSelected ? Qt.rgba(255, 255, 255, 0.2) : (btnHoverL.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent")
                                border.color: isSelected ? Config.accent : "transparent"
                                border.width: isSelected ? 1.5 : 0

                                Text {
                                    anchors.centerIn: parent
                                    text: Config.getIcon(modelData)
                                    color: parent.isSelected ? Config.accent : Config.textMain
                                    font.family: "Material Symbols Outlined"
                                    font.weight: Font.Bold
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: iconSettingsRoot.selectedIconId = modelData
                                }
                                HoverHandler { id: btnHoverL }
                            }
                        }
                    }
                }

                // Absorbs leftover row width
                Item { Layout.fillWidth: true }
            }

            // ROW 2: RIGHT MODULES & WORKSPACES
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    id: rightLabel
                    text: "Right/Bottom Icons:"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    font.bold: true
                    Layout.preferredWidth: mockupColumn.labelWidth
                    verticalAlignment: Text.AlignVCenter
                }

                // Dynamic Pill Capsule (snug to icon content)
                Rectangle {
                    implicitWidth: rightIconsRow.implicitWidth + 12
                    implicitHeight: 30
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(255, 255, 255, 0.05)

                    RowLayout {
                        id: rightIconsRow
                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "cc", label: "Control Center" },
                                { id: "overview", label: "Overview" },
                                { id: "magic", label: "Magic" },
                                { id: "magic_active", label: "Magic (Active)" },
                                { id: "music", label: "Music" },
                                { id: "music_active", label: "Music (Active)" },
                                { id: "private", label: "Private" },
                                { id: "private_active", label: "Private (Active)" }
                            ]

                            delegate: Rectangle {
                                implicitWidth: 26; implicitHeight: 26; radius: 6
                                readonly property bool isSelected: iconSettingsRoot.selectedIconId === modelData.id
                                color: isSelected ? Qt.rgba(255, 255, 255, 0.2) : (btnHoverC.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent")
                                border.color: isSelected ? Config.accent : "transparent"
                                border.width: isSelected ? 1.5 : 0

                                Text {
                                    anchors.centerIn: parent
                                    text: Config.getIcon(modelData.id)
                                    color: parent.isSelected ? Config.accent : Config.textMain
                                    font.family: "Material Symbols Outlined"
                                    font.weight: Font.Bold
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: iconSettingsRoot.selectedIconId = modelData.id
                                }
                                HoverHandler { id: btnHoverC }
                            }
                        }
                    }
                }

                // Absorbs leftover row width
                Item { Layout.fillWidth: true }
            }
        }
    }

    // --- CENTERED REORDER CONTROLS ---
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4

        // Shift Left
        Rectangle {
            implicitWidth: 28; implicitHeight: 28; radius: 6
            opacity: canMoveSelected ? 1.0 : 0.35
            color: (canMoveSelected && moveLeftHover.hovered) ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(0, 0, 0, 0.2)

            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "arrow_back"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 16
                color: canMoveSelected ? Config.textMain : Config.textMuted
            }

            TapHandler {
                enabled: canMoveSelected
                onTapped: {
                    let isLeft = Config.leftCardOrder.includes(iconSettingsRoot.selectedIconId)
                    Config.moveModule(isLeft ? "left" : "right", iconSettingsRoot.selectedIconId, -1)
                }
            }
            HoverHandler { 
                id: moveLeftHover
                enabled: canMoveSelected
                cursorShape: canMoveSelected ? Qt.PointingHandCursor : Qt.ArrowCursor 
            }
        }

        // Shift Right
        Rectangle {
            implicitWidth: 28; implicitHeight: 28; radius: 6
            opacity: canMoveSelected ? 1.0 : 0.35
            color: (canMoveSelected && moveRightHover.hovered) ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(0, 0, 0, 0.2)

            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "arrow_forward"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 16
                color: canMoveSelected ? Config.textMain : Config.textMuted
            }

            TapHandler {
                enabled: canMoveSelected
                onTapped: {
                    let isLeft = Config.leftCardOrder.includes(iconSettingsRoot.selectedIconId)
                    Config.moveModule(isLeft ? "left" : "right", iconSettingsRoot.selectedIconId, 1)
                }
            }
            HoverHandler { 
                id: moveRightHover
                enabled: canMoveSelected
                cursorShape: canMoveSelected ? Qt.PointingHandCursor : Qt.ArrowCursor 
            }
        }
    }

    // --- SEARCH BAR & RESET BUTTON ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            color: Qt.rgba(0, 0, 0, 0.2)
            radius: Config.cornerRadius / 2
            border.color: (iconSearchInput.activeFocus || searchBoxHover.hovered) ? Config.accent : "transparent"
            border.width: 1.5

            Behavior on border.color { ColorAnimation { duration: 150 } }

            HoverHandler { id: searchBoxHover; cursorShape: Qt.PointingHandCursor }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "search"
                    color: Config.textMuted
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 16
                }

                TextInput {
                    id: iconSearchInput
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontBody)
                    selectByMouse: true

                    HoverHandler { cursorShape: Qt.IBeamCursor }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search Material Design Symbols (e.g. power, terminal, home, wifi)..."
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontBody)
                        visible: iconSearchInput.text === ""
                        elide: Text.ElideRight
                    }

                    onTextChanged: iconSettingsRoot.searchQuery = text.trim().toLowerCase()
                }
            }
        }

        Rectangle {
            implicitWidth: 100; implicitHeight: 34
            radius: Config.cornerRadius / 2
            color: resetHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2)
            border.color: resetHover.hovered ? Config.accent : "transparent"
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "Reset All"
                color: resetHover.hovered ? Config.accent : Config.textMuted
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontCaption)
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.resetIcons()
            }
            HoverHandler { id: resetHover }
        }
    }

    // --- ICON PICKER GRID ---
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Qt.rgba(0, 0, 0, 0.15)
        radius: Config.cornerRadius / 2
        clip: true

        Text {
            anchors.centerIn: parent
            text: iconSettingsRoot.selectedIconId === "" ? "Click an icon above to start customizing..." : "Loading Material Symbols list..."
            color: Config.textMuted
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontBody)
            visible: iconSettingsRoot.selectedIconId === "" || (iconSettingsRoot.isLoadingIcons && iconSettingsRoot.allIconsList.length === 0)
        }

        GridView {
            id: iconGrid
            anchors.fill: parent
            anchors.margins: 8
            clip: true

            readonly property real minCellWidth: 44
            readonly property int columns: Math.max(1, Math.floor(width / minCellWidth))
            
            cellWidth: width / columns
            cellHeight: 46

            visible: iconSettingsRoot.selectedIconId !== "" && (!iconSettingsRoot.isLoadingIcons || iconSettingsRoot.allIconsList.length > 0)

            model: {
                if (iconSettingsRoot.searchQuery === "") {
                    return iconSettingsRoot.allIconsList.slice(0, 300)
                }
                return iconSettingsRoot.allIconsList.filter(name => name.includes(iconSettingsRoot.searchQuery)).slice(0, 300)
            }

            delegate: Item {
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: 38
                    height: 38
                    radius: 6
                    readonly property bool isAssigned: iconSettingsRoot.selectedIconId !== "" && Config.getIcon(iconSettingsRoot.selectedIconId) === modelData
                    color: isAssigned ? Qt.rgba(255, 255, 255, 0.25) : (gridHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent")
                    border.color: isAssigned ? Config.accent : "transparent"
                    border.width: isAssigned ? 1.5 : 0

                    Text {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: parent.isAssigned ? Config.accent : Config.textMain
                        font.family: "Material Symbols Outlined"
                        font.weight: Font.Bold
                        font.pixelSize: 20
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: iconSettingsRoot.selectedIconId !== ""
                        onClicked: {
                            if (iconSettingsRoot.selectedIconId !== "") {
                                Config.setIconOverride(iconSettingsRoot.selectedIconId, modelData)
                            }
                        }
                    }

                    HoverHandler { id: gridHover }
                }
            }
        }
    }
}