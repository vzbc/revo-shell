import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import ".."

Flickable {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: width
    contentHeight: mainColumn.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        active: root.moving || root.flicking
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

    // Custom Thicker Horizontal Slider with Dot Handle
    component ThickHorizontalSlider : Slider {
        id: slider
        implicitHeight: 24

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            implicitHeight: 6
            height: implicitHeight
            radius: 3
            color: Qt.rgba(255, 255, 255, 0.1)

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                color: Config.accent
                radius: 3
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 16
            implicitHeight: 16
            radius: 8
            color: slider.pressed ? Config.accent : Config.textMain
            border.width: 2
            border.color: Config.bgBase
        }
    }

    ColumnLayout {
        id: mainColumn
        width: Math.min(root.width - (root.cardMargin * 2), 620)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.cardMargin

        // SECTION HEADER
        Text {
            Layout.fillWidth: true
            text: "APPEARANCE & THEMES"
            color: Config.textMain
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontSubhead)
            font.bold: true
        }

        Text {
            text: "Fine-tune the shell geometry, corner roundings, border styles, glassmorphic effects, and color themes."
            color: Config.textMuted
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontCaption)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        // ==========================================
        // 1. UNIFIED SURFACE GEOMETRY CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: geomCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: geomCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "SURFACE GEOMETRY & SPACING"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Adjust corner curvature, border line weights, and layout paddings."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }
                }

                // Corners Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        spacing: 6
                        Layout.preferredWidth: 80
                        Text {
                            text: "rounded_corner"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: Config.textMuted
                        }
                        Text {
                            text: "Corners"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                        }
                    }

                    ThickHorizontalSlider {
                        id: cornersSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 40
                        stepSize: 1
                        value: Config.surfaceRadius
                        onValueChanged: Config.surfaceRadius = value
                    }

                    Rectangle {
                        implicitWidth: 42; implicitHeight: 22; radius: 6
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1; border.color: Config.accent
                        Text {
                            anchors.centerIn: parent
                            text: Math.round(cornersSlider.value) + "px"
                            color: Config.accent
                            font.family: Config.sysFont
                            font.bold: true
                            font.pixelSize: 10
                        }
                    }
                }

                // Border Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        spacing: 6
                        Layout.preferredWidth: 80
                        Text {
                            text: "border_style"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: Config.textMuted
                        }
                        Text {
                            text: "Border"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                        }
                    }

                    ThickHorizontalSlider {
                        id: borderSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 10
                        stepSize: 1
                        value: (Config.borderThickness !== undefined) ? Config.borderThickness : 3
                        onValueChanged: Config.borderThickness = value
                    }

                    Rectangle {
                        implicitWidth: 42; implicitHeight: 22; radius: 6
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1; border.color: Config.accent
                        Text {
                            anchors.centerIn: parent
                            text: Math.round(borderSlider.value) + "px"
                            color: Config.accent
                            font.family: Config.sysFont
                            font.bold: true
                            font.pixelSize: 10
                        }
                    }
                }

                // Margin Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        spacing: 6
                        Layout.preferredWidth: 80
                        Text {
                            text: "padding"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: Config.textMuted
                        }
                        Text {
                            text: "Margin"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                        }
                    }

                    ThickHorizontalSlider {
                        id: marginSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 32
                        stepSize: 1
                        value: (Config.cardMargin !== undefined) ? Config.cardMargin : 12
                        onValueChanged: Config.cardMargin = value
                    }

                    Rectangle {
                        implicitWidth: 42; implicitHeight: 22; radius: 6
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1; border.color: Config.accent
                        Text {
                            anchors.centerIn: parent
                            text: Math.round(marginSlider.value) + "px"
                            color: Config.accent
                            font.family: Config.sysFont
                            font.bold: true
                            font.pixelSize: 10
                        }
                    }
                }

                // Opacity Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        spacing: 6
                        Layout.preferredWidth: 80
                        Text {
                            text: "opacity"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: Config.textMuted
                        }
                        Text {
                            text: "Opacity"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                        }
                    }

                    ThickHorizontalSlider {
                        id: opacitySlider
                        Layout.fillWidth: true
                        from: 0.1
                        to: 1.0
                        value: Config.shellOpacity !== undefined ? Config.shellOpacity : 1.0
                        onValueChanged: Config.shellOpacity = value
                    }

                    Rectangle {
                        implicitWidth: 42; implicitHeight: 22; radius: 6
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1; border.color: Config.accent
                        Text {
                            anchors.centerIn: parent
                            text: Math.round(opacitySlider.value * 100) + "%"
                            color: Config.accent
                            font.family: Config.sysFont
                            font.bold: true
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. VISUAL EFFECTS & RENDERING ENGINES CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fxCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: fxCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "VISUAL EFFECTS & RENDERING"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Toggle compositor shaders, backdrop filters, and dynamic themer."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }
                }

                readonly property bool hasBorders: (Config.borderThickness !== undefined ? Config.borderThickness : 3) > 0

                // 1. Animated Gradient Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    opacity: fxCol.hasBorders ? 1.0 : 0.4

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Animated Gradient Borders"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Smooth animated color sweep along window borders (requires Border > 0px)"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: fxCol.hasBorders && Config.animateGradient

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: fxCol.hasBorders ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (fxCol.hasBorders) Config.animateGradient = !Config.animateGradient
                            }
                        }
                    }
                }

                // 2. Background Blur Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Background Blur"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Hardware-accelerated frosted glass backdrop filtering"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.enableBlur

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.enableBlur = !Config.enableBlur
                        }
                    }
                }

                // 3. X-Ray Mode Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    opacity: Config.enableBlur ? 1.0 : 0.4

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "X-Ray Mode"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Ultra-translucent window pass-through layer (requires Blur)"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.enableBlur && Config.enableXray

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Config.enableBlur ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (Config.enableBlur) Config.enableXray = !Config.enableXray
                            }
                        }
                    }
                }

                // 4. Watermarks Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Shell Watermarks"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Show decorative branding glyphs on lockscreen and shell panels"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.showWatermarks

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.showWatermarks = !Config.showWatermarks
                        }
                    }
                }

                // 5. Floating / Bouncing Watermarks Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    opacity: Config.showWatermarks ? 1.0 : 0.4

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Floating Ambient Drift"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Watermarks slowly drift within panel cards (requires Watermarks)"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.showWatermarks && Config.bounceWatermarks

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Config.showWatermarks ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (Config.showWatermarks) Config.bounceWatermarks = !Config.bounceWatermarks
                            }
                        }
                    }
                }

                // 6. Auto-Color (Iris) Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Auto-Color (Iris)"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Dynamically extract and apply theme colors from current wallpaper"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.enableIris

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.enableIris = !Config.enableIris
                        }
                    }
                }
            }
        }

        // ==========================================
        // 3. COLOR THEMES & PALETTES CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: themeCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: themeCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "COLOR PALETTES & THEMES"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: Config.enableIris ? "Iris auto-theming is active (based on wallpaper)" : (Config.useCustomColors ? "Custom Hex Overrides Active" : (Config.themes && Config.themes[Config.currentThemeIndex] ? Config.themes[Config.currentThemeIndex].name : "Standard Theme"))
                            color: Config.accent
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Count Badge
                    Rectangle {
                        implicitWidth: themeCountText.implicitWidth + 16
                        implicitHeight: 24
                        radius: 12
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            id: themeCountText
                            anchors.centerIn: parent
                            text: (Config.themes ? Config.themes.length : 0) + " Palettes"
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            font.bold: true
                            color: Config.textMuted
                        }
                    }
                }

                // Palette Swatches Box
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: paletteGrid.implicitHeight + 20
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: Config.cornerRadius / 2
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)
                    enabled: !Config.enableIris
                    opacity: Config.enableIris ? 0.35 : (Config.useCustomColors ? 0.5 : 1.0)

                    GridLayout {
                        id: paletteGrid
                        anchors.fill: parent
                        anchors.margins: 12
                        columns: 10
                        rowSpacing: 10
                        columnSpacing: 10

                        Repeater {
                            model: {
                                let total = Config.themes ? Config.themes.length : 0
                                let cols = 10
                                let remainder = total % cols
                                let dummyCount = remainder === 0 ? 0 : (cols - remainder)

                                let list = []
                                for (let i = 0; i < total; i++) {
                                    list.push({ theme: Config.themes[i], realIndex: i, isDummy: false })
                                }
                                for (let d = 0; d < dummyCount; d++) {
                                    list.push({ theme: null, realIndex: -1, isDummy: true })
                                }
                                return list
                            }

                            delegate: Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32

                                readonly property var itemData: modelData
                                readonly property bool isDummy: itemData.isDummy
                                readonly property int themeIdx: itemData.realIndex
                                readonly property var themeObj: itemData.theme
                                readonly property bool isCustomTheme: !isDummy && themeObj && themeObj.isCustom === true
                                readonly property bool isSelected: !isDummy && !Config.useCustomColors && Config.currentThemeIndex === themeIdx

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 16
                                    color: isDummy ? "transparent" : (themeObj.bgBase || Qt.rgba(0,0,0,0.5))
                                    border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.15)
                                    border.width: isSelected ? 2.5 : 1
                                    visible: !isDummy

                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    // Inner Accent Pip
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 14; height: 14; radius: 7
                                        color: themeObj ? themeObj.accent : "transparent"
                                    }

                                    TapHandler {
                                        enabled: !isDummy
                                        acceptedButtons: Qt.LeftButton
                                        onTapped: {
                                            Config.useCustomColors = false
                                            Config.setTheme(themeIdx)
                                        }
                                    }

                                    TapHandler {
                                        enabled: !isDummy
                                        acceptedButtons: Qt.RightButton
                                        onTapped: {
                                            if (isCustomTheme) deletePalette(themeIdx)
                                        }
                                    }

                                    HoverHandler {
                                        id: pSwHover
                                        enabled: !isDummy
                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    // Delete badge for custom palettes
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: -2
                                        width: 14; height: 14; radius: 7
                                        color: "#E74C3C"
                                        visible: isCustomTheme && pSwHover.hovered

                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            color: "white"
                                            font.pixelSize: 11
                                            font.bold: true
                                            anchors.verticalCenterOffset: -1
                                        }

                                        TapHandler {
                                            acceptedButtons: Qt.LeftButton
                                            onTapped: deletePalette(themeIdx)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 4. CUSTOM HEX OVERRIDES CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: hexCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: hexCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    opacity: Config.enableIris ? 0.35 : 1.0

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "CUSTOM HEX OVERRIDES"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Define custom hex values for surface backgrounds, panels, and accent highlights."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ToggleSwitch {
                        checked: !Config.enableIris && Config.useCustomColors
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            enabled: !Config.enableIris
                            cursorShape: Config.enableIris ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                            onClicked: Config.useCustomColors = !Config.useCustomColors
                        }
                    }
                }

                // Custom Hex Inputs (Base, Panel, Accent)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    enabled: Config.useCustomColors && !Config.enableIris
                    opacity: (Config.useCustomColors && !Config.enableIris) ? 1.0 : 0.4

                    // Base
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "Base Background"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Config.cornerRadius / 2
                            color: Qt.rgba(0, 0, 0, 0.3)
                            border.color: baseInput.activeFocus ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6

                                Rectangle {
                                    implicitWidth: 16; implicitHeight: 16; radius: 8
                                    color: Config.customBgBase || "#111111"
                                    border.width: 1; border.color: Qt.rgba(255, 255, 255, 0.2)
                                }

                                TextInput {
                                    id: baseInput
                                    Layout.fillWidth: true
                                    text: Config.customBgBase
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    selectByMouse: true
                                    onEditingFinished: if (text.length > 0) Config.customBgBase = text
                                    HoverHandler { cursorShape: Qt.IBeamCursor }
                                }
                            }
                        }
                    }

                    // Panel
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "Panel Surface"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Config.cornerRadius / 2
                            color: Qt.rgba(0, 0, 0, 0.3)
                            border.color: panelInput.activeFocus ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6

                                Rectangle {
                                    implicitWidth: 16; implicitHeight: 16; radius: 8
                                    color: Config.customBgPanel || "#222222"
                                    border.width: 1; border.color: Qt.rgba(255, 255, 255, 0.2)
                                }

                                TextInput {
                                    id: panelInput
                                    Layout.fillWidth: true
                                    text: Config.customBgPanel
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    selectByMouse: true
                                    onEditingFinished: if (text.length > 0) Config.customBgPanel = text
                                    HoverHandler { cursorShape: Qt.IBeamCursor }
                                }
                            }
                        }
                    }

                    // Accent
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "Accent Color"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Config.cornerRadius / 2
                            color: Qt.rgba(0, 0, 0, 0.3)
                            border.color: accentInput.activeFocus ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6

                                Rectangle {
                                    implicitWidth: 16; implicitHeight: 16; radius: 8
                                    color: Config.customAccent || "#00E676"
                                    border.width: 1; border.color: Qt.rgba(255, 255, 255, 0.2)
                                }

                                TextInput {
                                    id: accentInput
                                    Layout.fillWidth: true
                                    text: Config.customAccent
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    selectByMouse: true
                                    onEditingFinished: if (text.length > 0) Config.customAccent = text
                                    HoverHandler { cursorShape: Qt.IBeamCursor }
                                }
                            }
                        }
                    }
                }

                // Save Palette Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: Config.useCustomColors && !Config.enableIris

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Config.cornerRadius / 2
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.color: nameInput.activeFocus ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                        border.width: 1

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            text: "Enter new palette name..."
                            color: Qt.rgba(255, 255, 255, 0.3)
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                            visible: nameInput.text.length === 0 && !nameInput.activeFocus
                        }

                        TextInput {
                            id: nameInput
                            anchors.fill: parent
                            anchors.leftMargin: 10; anchors.rightMargin: 10
                            text: ""
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            onAccepted: saveCurrentPalette()
                            HoverHandler { cursorShape: Qt.IBeamCursor }
                        }
                    }

                    Rectangle {
                        implicitWidth: 110
                        implicitHeight: 32
                        radius: Config.cornerRadius / 2
                        color: saveHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Config.accent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "save"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                                color: saveHover.hovered ? Config.accent : Config.bgBase
                            }
                            Text {
                                text: "Save Palette"
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: saveHover.hovered ? Config.accent : Config.bgBase
                            }
                        }

                        TapHandler { onTapped: saveCurrentPalette() }
                        HoverHandler { id: saveHover; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; implicitHeight: 20 }
    }

    function saveCurrentPalette() {
        var paletteName = nameInput.text.trim()
        if (paletteName.length === 0) {
            paletteName = "Custom " + (Config.themes.length + 1)
        }

        var newTheme = {
            name: paletteName,
            bgBase: Config.customBgBase,
            bgPanel: Config.customBgPanel,
            accent: Config.customAccent,
            isCustom: true
        }

        Config.addCustomTheme(newTheme)
        nameInput.text = ""
        Config.useCustomColors = false
    }

    function deletePalette(idx) {
        Config.removeCustomTheme(idx)
    }
}