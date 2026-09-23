import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import ".."

Flickable {
    id: flickableRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        active: flickableRoot.moving || flickableRoot.flicking
    }

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    // Reusable Geometric / Square Toggle Switch Component
    component ToggleSwitch : Rectangle {
        id: sw
        property bool checked: false
        
        implicitWidth: 40
        implicitHeight: 22
        radius: 6
        color: checked ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.4)
        border.width: sw.checked ? 2 : 1
        border.color: checked ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        // Square Thumb / Slider
        Rectangle {
            id: thumb
            x: sw.checked ? (sw.width - width - 3) : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 4
            color: sw.checked ? Config.accent : Qt.rgba(255, 255, 255, 0.2)
            border.width: 0
            border.color: sw.checked ? Qt.lighter(Config.accent, 1.2) : Qt.rgba(255, 255, 255, 0.25)

            Behavior on x { 
                NumberAnimation { 
                    duration: 160
                    easing.type: Easing.OutCubic 
                } 
            }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
    }

    property var allFonts: Qt.fontFamilies()
    property var filteredFonts: {
        let filter = Config.fontSearchFilter ? Config.fontSearchFilter.trim().toLowerCase() : ""
        if (filter === "") return allFonts
        return allFonts.filter(f => f.toLowerCase().includes(filter))
    }

    ColumnLayout {
        id: contentColumn
        width: Math.min(flickableRoot.width - (flickableRoot.cardMargin * 2), 620)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: flickableRoot.cardMargin

        // SECTION HEADER
        Text {
            Layout.fillWidth: true
            text: "TYPOGRAPHY & SCALING"
            color: Config.textMain
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontSubhead)
            font.bold: true
        }

        Text {
            text: "Customize the global shell font family, typographical hierarchy, and UI scaling presets across all Synoptik panels."
            color: Config.textMuted
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontCaption)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        // ==========================================
        // 1. LIVE INTERACTIVE SHOWCASE CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: showcaseCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: showcaseCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Header Row with Active Badge & Reset
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "LIVE TYPE SPECIMEN"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Real-time preview of the active font family and scaling."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Reset to Default Button
                    Rectangle {
                        visible: Config.sysFont !== ""
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        implicitWidth: 120
                        implicitHeight: 30
                        radius: 15
                        color: resetHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.15)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: "restart_alt"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 15
                                color: Config.textMain
                            }
                            Text {
                                text: "Reset Default"
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: Config.textMain
                            }
                        }

                        MouseArea {
                            id: resetHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.sysFont = ""
                        }
                    }
                }

                // Interactive Specimen Board
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: specimenContent.implicitHeight + 24
                    radius: Config.cornerRadius - 2
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)

                    ColumnLayout {
                        id: specimenContent
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        // Active Font Name Banner
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                implicitWidth: 24; implicitHeight: 24; radius: 6
                                color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.18)
                                border.width: 1
                                border.color: Config.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: "font_download"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 14
                                    color: Config.accent
                                }
                            }

                            Text {
                                text: Config.sysFont !== "" ? Config.sysFont : "System Default (Sans-Serif)"
                                color: Config.accent
                                font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                implicitWidth: scaleLabel.implicitWidth + 14
                                implicitHeight: 22
                                radius: 11
                                color: Qt.rgba(255, 255, 255, 0.08)

                                Text {
                                    id: scaleLabel
                                    anchors.centerIn: parent
                                    text: Config.fontScaleIndex === 0 ? "Compact 85%" : (Config.fontScaleIndex === 2 ? "Large 120%" : "Standard 100%")
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Config.textMuted
                                }
                            }
                        }

                        // Headline Specimen
                        Text {
                            Layout.fillWidth: true
                            text: "The quick brown fox jumps over the lazy dog."
                            color: Config.textMain
                            font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        // Subtitle & Body Specimen
                        Text {
                            Layout.fillWidth: true
                            text: "Sphinx of black quartz, judge my vow. 0123456789 — $ € £ ¥ • @ # % & * ( ) [ ] { }"
                            color: Config.textMuted
                            font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.letterSpacing: 0.5
                            wrapMode: Text.WordWrap
                        }

                        // Mini UI Widgets Preview Mockup
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 18
                            color: Qt.rgba(255, 255, 255, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.08)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 10

                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: "schedule"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 15
                                        color: Config.accent
                                    }
                                    Text {
                                        text: Qt.formatTime(new Date(), "hh:mm ap")
                                        font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: true
                                        color: Config.textMain
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RowLayout {
                                    spacing: 6
                                    Repeater {
                                        model: ["1", "2", "3", "4"]
                                        delegate: Rectangle {
                                            implicitWidth: 20; implicitHeight: 20; radius: 10
                                            color: index === 0 ? Config.accent : Qt.rgba(255, 255, 255, 0.08)
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: index === 0 ? Config.bgBase : Config.textMain
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: "battery_charging_full"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 15
                                        color: "#00E676"
                                    }
                                    Text {
                                        text: "98%"
                                        font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                        font.pixelSize: Config.size(Config.fontMicro)
                                        font.bold: true
                                        color: Config.textMain
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. FONT SCALING PRESETS CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: scaleCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: scaleCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "UI FONT SCALING"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontBody)
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: [
                            { name: "Small", desc: "Compact (85%)", icon: "format_size", index: 0 },
                            { name: "Normal", desc: "Standard (100%)", icon: "text_fields", index: 1 },
                            { name: "Large", desc: "Comfortable (120%)", icon: "format_size", index: 2 }
                        ]

                        delegate: Rectangle {
                            id: scaleBtn
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 48
                            radius: Config.cornerRadius / 2
                            readonly property bool isSelected: Config.fontScaleIndex === modelData.index
                            color: isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.16) : (scaleBtnHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 8

                                Rectangle {
                                    implicitWidth: 26; implicitHeight: 26; radius: 13
                                    color: scaleBtn.isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.06)
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 14
                                        color: scaleBtn.isSelected ? Config.bgBase : Config.textMuted
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        text: modelData.name
                                        color: scaleBtn.isSelected ? Config.accent : Config.textMain
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: scaleBtn.isSelected
                                    }
                                    Text {
                                        text: modelData.desc
                                        color: Config.textMuted
                                        font.family: Config.sysFont
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            MouseArea {
                                id: scaleBtnHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.fontScaleIndex = modelData.index
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 3. FONT RASTERIZATION & RENDER ENGINE CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fontEngineCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: fontEngineCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "FONT RASTERIZATION & SHARPNESS"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                // Toggle Row for Native Subpixel FreeType Rendering
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: nativeRenderRow.implicitHeight + 16
                    radius: Config.cornerRadius / 2
                    color: nativeRenderHover.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)

                    RowLayout {
                        id: nativeRenderRow
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Crisp Native Font Rendering (FreeType & Subpixel Hinting)"
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                            }

                            Text {
                                text: "Bypasses Qt Distance Field rendering in favor of native FreeType subpixel antialiasing and stem hinting for pixel-sharp text clarity."
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        ToggleSwitch {
                            checked: Config.nativeFontRendering
                        }
                    }

                    MouseArea {
                        id: nativeRenderHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Config.nativeFontRendering = !Config.nativeFontRendering
                    }
                }
            }
        }

        // ==========================================
        // 4. FONT LIBRARY & SEARCH CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fontLibCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: fontLibCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "SYSTEM FONT LIBRARY"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Select any installed typography family to apply system-wide."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Count Badge
                    Rectangle {
                        implicitWidth: fontCountText.implicitWidth + 16
                        implicitHeight: 24
                        radius: 12
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            id: fontCountText
                            anchors.centerIn: parent
                            text: flickableRoot.filteredFonts.length + " Fonts"
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            font.bold: true
                            color: Config.textMuted
                        }
                    }
                }

                // Search Field Container
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Config.cornerRadius / 2
                    color: fontInputHover.hovered || fontSearchInput.activeFocus ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.25)
                    border.color: fontSearchInput.activeFocus ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1

                    HoverHandler { 
                        id: fontInputHover
                        cursorShape: Qt.IBeamCursor
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "search"
                            color: fontSearchInput.activeFocus ? Config.accent : Config.textMuted
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                        }

                        TextInput {
                            id: fontSearchInput
                            Layout.fillWidth: true
                            text: Config.fontSearchFilter
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            clip: true
                            selectByMouse: true
                            onTextChanged: Config.fontSearchFilter = text
                        }

                        Text {
                            text: "Search fonts by name..."
                            color: Qt.rgba(255, 255, 255, 0.3)
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            visible: fontSearchInput.text.length === 0
                        }

                        Text {
                            text: "close"
                            color: Config.textMuted
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            visible: fontSearchInput.text.length > 0

                            TapHandler {
                                onTapped: {
                                    fontSearchInput.text = ""
                                    Config.fontSearchFilter = ""
                                }
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }

                // Scrollable Font List Box
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 320
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: Config.cornerRadius / 2
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)
                    clip: true

                    ListView {
                        id: fontListView
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 3
                        model: flickableRoot.filteredFonts

                        delegate: Rectangle {
                            id: fontRow
                            required property string modelData
                            width: ListView.view.width
                            implicitHeight: 42
                            radius: 8

                            readonly property bool isSelected: Config.sysFont === modelData
                            color: isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.16) : (fRowHover.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : "transparent")
                            border.width: isSelected ? 1 : 0
                            border.color: isSelected ? Config.accent : "transparent"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 10

                                // Left: Font Name & Active Pill
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 2
                                    spacing: 1

                                    Text {
                                        text: fontRow.modelData
                                        color: fontRow.isSelected ? Config.accent : Config.textMain
                                        font.family: fontRow.modelData
                                        font.pixelSize: Config.size(Config.fontBody)
                                        font.bold: fontRow.isSelected
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                // Right: Specimen Sample rendered in the font itself
                                Text {
                                    text: "Aa Bb Gg 123"
                                    font.family: fontRow.modelData
                                    font.pixelSize: Config.size(Config.fontBody)
                                    color: fontRow.isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.6)
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                }

                                // Checkmark Badge
                                Rectangle {
                                    implicitWidth: 20; implicitHeight: 20; radius: 10
                                    color: fontRow.isSelected ? Config.accent : "transparent"
                                    visible: fontRow.isSelected

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: Config.bgBase
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                id: fRowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.sysFont = fontRow.modelData
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            active: fontListView.moving || fontListView.flicking
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; implicitHeight: 20 }
    }
}