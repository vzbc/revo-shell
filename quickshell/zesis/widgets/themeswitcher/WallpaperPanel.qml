pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../"
import "../shared"

Item {
    id: root

    // "" means the wallpaper grid below applies to every monitor.
    // Otherwise it's a ShellScreen.name and clicks only retarget that one output.
    property string targetMonitor: ""
    readonly property string _displayedWallpaper: root.targetMonitor === "" ? ThemeState.lastWallpaper : (ThemeState.perMonitorWallpaper[root.targetMonitor] || ThemeState.lastWallpaper)

    readonly property bool _currentBackendHasDaemon: {
        for (var i = 0; i < ThemeState.wallpaperBackends.length; i++) {
            if (ThemeState.wallpaperBackends[i].id === ThemeState.wallpaperBackend)
                return !!ThemeState.wallpaperBackends[i].daemonProcess;
        }
        return false;
    }

    readonly property real paneMargin: Math.round(28 * UIScale.value)

    // Container-aware split, see docs/qml-patterns.md #2. Both sides of the threshold are
    // measured from content. The grid needs at least two target-sized columns to be worth
    // its own pane, and the right pane needs at least as much as its widest row requires.
    readonly property real _gridTargetCellWidth: Math.round(150 * UIScale.value)
    readonly property real _leftMinWidth: root._gridTargetCellWidth * 2 + UIScale.spacingSm * 2 + UIScale.radiusMd
    readonly property real _leftMaxWidth: Math.round(520 * UIScale.value)
    readonly property real leftColWidth: Math.max(root._leftMinWidth, Math.min(root._leftMaxWidth, Math.round(root.width * 0.36)))
    readonly property real _rightMinWidth: Math.max(headerRow.implicitWidth, backendRow.implicitWidth) + root.paneMargin * 2
    readonly property bool sideBySide: root.width > 0 && root.width >= root._leftMinWidth + 1 + root._rightMinWidth
    readonly property real stackedGridHeight: Math.max(Math.round(240 * UIScale.value), Math.round(root.height * 0.4))

    Component.onCompleted: scanner.running = true
    Connections {
        target: ThemeState // qmllint disable incompatible-type
        function onWallpapersDirChanged() {
            scanner.running = true;
        }
    }

    ListModel {
        id: wallpapers
    }
    ListModel {
        id: filteredWallpapers
    }

    function _updateFilter(search) {
        filteredWallpapers.clear();
        for (var i = 0; i < wallpapers.count; i++) {
            var p = wallpapers.get(i).path;
            if (search === "" || p.toLowerCase().includes(search.toLowerCase()))
                filteredWallpapers.append({
                    path: p
                });
        }
    }

    Process {
        id: scanner
        command: ["bash", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort > \"$2\"", "--", ThemeState.wallpapersDir, Quickshell.env("HOME") + "/.cache/zesis/wallpapers.txt"]
        stdout: StdioCollector {}
        onExited: () => listReader.reload()
    }

    FileView {
        id: listReader
        path: Quickshell.env("HOME") + "/.cache/zesis/wallpapers.txt"
        onLoaded: {
            var lines = text().split("\n");
            wallpapers.clear();
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line !== "")
                    wallpapers.append({
                        path: line
                    });
            }
            root._updateFilter("");
        }
    }

    component WallpaperCell: Item {
        id: cell
        required property string path
        readonly property bool selected: root._displayedWallpaper === cell.path
        readonly property string _baseName: cell.path.substring(cell.path.lastIndexOf("/") + 1)
        readonly property string _displayName: cell._baseName.replace(/\.[^.]+$/, "")
        readonly property string _thumbPath: ThemeState.thumbsDir + "/" + cell._baseName + ".jpg"

        Rectangle {
            id: cellBg
            anchors.fill: parent
            anchors.margins: UIScale.spacingXs
            radius: UIScale.radiusSm
            color: cell.selected ? Colors.withAlpha(Colors.accent, 0.12) : (cellHover.hovered ? Colors.surfaceHigh : "transparent")
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Rectangle {
                id: thumbRect
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: UIScale.spacingXs
                height: Math.round(width * 9 / 16)
                radius: UIScale.radiusSm
                color: Colors.surface
                clip: true

                Image {
                    id: thumbImg
                    anchors.fill: parent
                    source: "file://" + cell._thumbPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    onStatusChanged: {
                        if (status === Image.Error && !thumbGen.running)
                            thumbGen.running = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.surface
                    visible: thumbImg.status !== Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Colors.accent
                    border.width: Math.round(2 * UIScale.value)
                    opacity: cell.selected ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.rgba(0, 0, 0, 0.5)
                    visible: ThemeState.applying && cell.selected

                    Text {
                        anchors.centerIn: parent
                        text: "..."
                        color: "white"
                        font.pixelSize: UIScale.fontLead
                    }
                }
            }

            Text {
                anchors.top: thumbRect.bottom
                anchors.topMargin: UIScale.spacingXs
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: UIScale.spacingXs
                anchors.rightMargin: UIScale.spacingXs
                text: cell._displayName
                color: cell.selected ? Colors.accent : Colors.textDim
                font.pixelSize: UIScale.fontTiny
                font.weight: cell.selected ? Font.Medium : Font.Normal
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
        }

        HoverHandler {
            id: cellHover
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.targetMonitor === "" ? ThemeState.apply(cell.path) : ThemeState.applyToMonitor(cell.path, root.targetMonitor)
        }

        Process {
            id: thumbGen
            command: ["magick", cell.path, "-resize", "240x135^", "-gravity", "Center", "-extent", "240x135", cell._thumbPath]
            onExited: (code, status) => {
                if (code === 0) {
                    thumbImg.source = "";
                    thumbImg.source = "file://" + cell._thumbPath;
                } else {
                    thumbImg.source = "file://" + cell.path;
                }
            }
        }
    }

    readonly property var _darkSwatches: [
        {
            c: Colors.darkPalette.background,
            label: "bg"
        },
        {
            c: Colors.darkPalette.surface_container,
            label: "surface"
        },
        {
            c: Colors.darkPalette.surface_container_high,
            label: "surf+"
        },
        {
            c: Colors.darkPalette.outline_variant,
            label: "border"
        },
        {
            c: Colors.darkPalette.primary,
            label: "primary"
        },
        {
            c: Colors.darkPalette.primary_container,
            label: "p.cont"
        },
        {
            c: Colors.darkPalette.on_primary,
            label: "on-p"
        },
        {
            c: Colors.darkPalette.on_background,
            label: "text"
        },
        {
            c: Colors.darkPalette.on_surface_variant,
            label: "dim"
        },
    ]
    readonly property var _lightSwatches: [
        {
            c: Colors.lightPalette.background,
            label: "bg"
        },
        {
            c: Colors.lightPalette.surface_container,
            label: "surface"
        },
        {
            c: Colors.lightPalette.surface_container_high,
            label: "surf+"
        },
        {
            c: Colors.lightPalette.outline_variant,
            label: "border"
        },
        {
            c: Colors.lightPalette.primary,
            label: "primary"
        },
        {
            c: Colors.lightPalette.primary_container,
            label: "p.cont"
        },
        {
            c: Colors.lightPalette.on_primary,
            label: "on-p"
        },
        {
            c: Colors.lightPalette.on_background,
            label: "text"
        },
        {
            c: Colors.lightPalette.on_surface_variant,
            label: "dim"
        },
    ]

    component PaletteRow: Item {
        id: paletteRow
        required property string rowLabel
        required property var swatches
        implicitHeight: Math.max(rowLabelText.implicitHeight, swatchGrid.implicitHeight)

        readonly property real _availableWidth: paletteRow.width - rowLabelText.width - UIScale.spacingSm
        readonly property real _cellPitch: Math.round(42 * UIScale.value) + UIScale.spacingSm
        readonly property int _maxCols: Math.max(1, Math.floor((paletteRow._availableWidth + UIScale.spacingSm) / paletteRow._cellPitch))
        readonly property int _rows: Math.max(1, Math.ceil(paletteRow.swatches.length / paletteRow._maxCols))
        readonly property int _balancedCols: Math.ceil(paletteRow.swatches.length / paletteRow._rows)

        Text {
            id: rowLabelText
            anchors.top: parent.top
            anchors.left: parent.left
            width: Math.round(38 * UIScale.value)
            text: paletteRow.rowLabel
            color: Colors.textDim
            font.pixelSize: UIScale.fontCaption
            font.weight: Font.Medium
            topPadding: UIScale.spacingXs
        }

        Grid {
            id: swatchGrid
            anchors.top: parent.top
            anchors.left: rowLabelText.right
            anchors.leftMargin: UIScale.spacingSm
            columns: paletteRow._balancedCols
            columnSpacing: UIScale.spacingSm
            rowSpacing: UIScale.spacingSm

            Repeater {
                model: paletteRow.swatches
                Item {
                    id: swatchDelegate
                    required property var modelData
                    implicitWidth: Math.round(42 * UIScale.value)
                    implicitHeight: Math.round(62 * UIScale.value)

                    Rectangle {
                        id: swatch
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.round(38 * UIScale.value)
                        height: Math.round(38 * UIScale.value)
                        radius: Math.round(9 * UIScale.value)
                        color: swatchDelegate.modelData.c
                        border.color: Colors.withAlpha(Colors.text, 0.08)
                        border.width: 1

                        HoverHandler {
                            id: swatchHover
                        }

                        ToolTip {
                            visible: swatchHover.hovered
                            delay: 600
                            text: swatchDelegate.modelData.c
                        }
                    }

                    Text {
                        anchors.top: swatch.bottom
                        anchors.topMargin: UIScale.spacingXs
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: swatchDelegate.modelData.label
                        color: Colors.textDim
                        font.pixelSize: Math.round(9 * UIScale.value)
                    }
                }
            }
        }
    }

    Item {
        id: bodyArea
        anchors.fill: parent

        // Left: wallpaper list
        ColumnLayout {
            id: leftCol
            anchors.top: parent.top
            anchors.left: parent.left
            width: root.sideBySide ? root.leftColWidth : parent.width
            height: root.sideBySide ? parent.height : root.stackedGridHeight
            spacing: UIScale.spacingSm

            StyledTextInput {
                id: searchField
                Layout.fillWidth: true
                Layout.topMargin: UIScale.spacingLg
                Layout.leftMargin: Math.round(16 * UIScale.value)
                Layout.rightMargin: Math.round(16 * UIScale.value)
                showClearButton: true
                placeholder: I18n.t("wallpaper.searchPlaceholder")
                onTextChanged: root._updateFilter(text)
            }

            GridView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: UIScale.spacingSm
                Layout.rightMargin: UIScale.spacingSm
                Layout.bottomMargin: UIScale.radiusMd
                clip: true
                model: filteredWallpapers
                // Column count follows the space available
                readonly property int _columns: Math.max(2, Math.min(5, Math.floor(width / root._gridTargetCellWidth)))
                cellWidth: Math.floor(width / Math.max(1, _columns))
                cellHeight: Math.round(cellWidth * 9 / 16) + Math.round(28 * UIScale.value)

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                WheelHandler {
                    onWheel: event => {
                        gridView.contentY = Math.max(gridView.originY, Math.min(gridView.originY + gridView.contentHeight - gridView.height, gridView.contentY - event.angleDelta.y * 0.5));
                    }
                }

                delegate: WallpaperCell {
                    width: gridView.cellWidth
                    height: gridView.cellHeight
                }

                Text {
                    anchors.centerIn: parent
                    visible: filteredWallpapers.count === 0 && !scanner.running
                    text: wallpapers.count === 0 ? I18n.t("wallpaper.noneFoundIn", [ThemeState.wallpapersDir]) : I18n.t("wallpaper.noResults")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Vertical divider in side-by-side mode, horizontal once stacked
        Rectangle {
            id: divider
            anchors.top: root.sideBySide ? parent.top : leftCol.bottom
            anchors.left: root.sideBySide ? leftCol.right : parent.left
            width: root.sideBySide ? 1 : bodyArea.width
            height: root.sideBySide ? bodyArea.height : 1
            color: Colors.withAlpha(Colors.outline, 0.5)
        }

        // Right: preview + palette, scrollable so a short/narrow settings window doesn't
        // clip the palette instead of just needing to scroll to it
        Flickable {
            id: rightFlick
            anchors.top: root.sideBySide ? parent.top : divider.bottom
            anchors.left: root.sideBySide ? divider.right : parent.left
            width: root.sideBySide ? bodyArea.width - leftCol.width - divider.width : bodyArea.width
            height: root.sideBySide ? bodyArea.height : bodyArea.height - leftCol.height - divider.height
            clip: true
            contentWidth: width
            contentHeight: controlsCol.implicitHeight + root.paneMargin * 2

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: controlsCol
                x: root.paneMargin
                y: root.paneMargin
                width: rightFlick.width - root.paneMargin * 2
                spacing: 0

                Text {
                    text: I18n.t("wallpaper.breadcrumb")
                    color: Colors.accent
                    font.pixelSize: UIScale.fontCaption
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    font.family: "monospace"
                }

                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingXs
                    Layout.bottomMargin: UIScale.spacingLg
                    spacing: UIScale.spacingSm

                    Text {
                        text: I18n.t("wallpaper.title")
                        color: Colors.text
                        font.pixelSize: UIScale.fontTitle
                        font.weight: Font.ExtraBold
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Scheme type dropdown
                    StyledComboBox {
                        id: schemeDropdown
                        Layout.preferredHeight: Math.round(32 * UIScale.value)
                        model: [
                            {
                                value: "scheme-tonal-spot",
                                label: "Tonal Spot"
                            },
                            {
                                value: "scheme-vibrant",
                                label: "Vibrant"
                            },
                            {
                                value: "scheme-expressive",
                                label: "Expressive"
                            },
                            {
                                value: "scheme-fidelity",
                                label: "Fidelity"
                            },
                            {
                                value: "scheme-content",
                                label: "Content"
                            },
                            {
                                value: "scheme-neutral",
                                label: "Neutral"
                            },
                            {
                                value: "scheme-monochrome",
                                label: "Monochrome"
                            },
                            {
                                value: "scheme-rainbow",
                                label: "Rainbow"
                            },
                            {
                                value: "scheme-fruit-salad",
                                label: "Fruit Salad"
                            },
                        ]
                        selectedValue: ThemeState.schemeType
                        onChosen: value => {
                            ThemeState.schemeType = value;
                            if (ThemeState.lastWallpaper !== "")
                                ThemeState.apply(ThemeState.lastWallpaper);
                            else
                                ThemeState._persistState();
                        }
                    }

                    // Dark / Light toggle
                    Rectangle {
                        Layout.preferredWidth: Math.round(120 * UIScale.value)
                        Layout.preferredHeight: Math.round(32 * UIScale.value)
                        radius: Math.round(16 * UIScale.value)
                        color: Colors.surface

                        Rectangle {
                            width: Math.round(56 * UIScale.value)
                            height: Math.round(26 * UIScale.value)
                            radius: Math.round(13 * UIScale.value)
                            anchors.verticalCenter: parent.verticalCenter
                            x: ThemeState.palette === "dark" ? Math.round(3 * UIScale.value) : Math.round(61 * UIScale.value)
                            color: Colors.accent
                            Behavior on x {
                                NumberAnimation {
                                    duration: Anim.medium
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("wallpaper.dark")
                                color: ThemeState.palette === "dark" ? Colors.bg : Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.medium
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("wallpaper.light")
                                color: ThemeState.palette === "light" ? Colors.bg : Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.medium
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ThemeState.togglePalette()
                        }
                    }
                }

                // Which folder the wallpaper grid is scanned from
                RowLayout {
                    id: wallpapersDirRow
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingLg
                    spacing: UIScale.spacingSm

                    Text {
                        text: I18n.t("wallpaper.wallpapersFolderLabel")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                    }

                    StyledTextInput {
                        id: wallpapersDirField
                        Layout.fillWidth: true
                        placeholder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
                        text: ThemeState.wallpapersDir
                        onAccepted: ThemeState.setWallpapersDirOverride(wallpapersDirField.text.trim())
                    }

                    ActionButton {
                        visible: ThemeState.wallpapersDirOverride !== ""
                        label: I18n.t("wallpaper.resetToDefault")
                        onActivated: ThemeState.setWallpapersDirOverride("")
                    }
                }

                // Wallpaper backend picker
                RowLayout {
                    id: backendRow
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingLg
                    spacing: UIScale.spacingSm

                    Text {
                        text: I18n.t("wallpaper.backendLabel")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                    }

                    StyledComboBox {
                        id: backendComboBox
                        model: ThemeState.wallpaperBackends.map(b => ({
                                    value: b.id,
                                    label: b.label
                                }))
                        selectedValue: ThemeState.wallpaperBackend
                        onChosen: value => {
                            ThemeState.wallpaperBackend = value;
                            ThemeState._persistState();
                            ThemeState.ensureWallpaperDaemon();
                        }
                    }

                    StyledTextInput {
                        id: customCmdField
                        visible: ThemeState.wallpaperBackend === "custom"
                        Layout.fillWidth: true
                        placeholder: I18n.t("wallpaper.customCommandPlaceholder")
                        text: ThemeState.customWallpaperCommand
                        onAccepted: {
                            ThemeState.customWallpaperCommand = customCmdField.text;
                            ThemeState._persistState();
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        visible: !customCmdField.visible
                    }
                }

                // Whether to launch the backend's daemon on startup if it's not already running
                RowLayout {
                    id: daemonRow
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingLg
                    spacing: UIScale.spacingSm
                    visible: root._currentBackendHasDaemon

                    Text {
                        text: I18n.t("wallpaper.autoStartDaemon")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }

                    ToggleSwitch {
                        checked: ThemeState.autoStartWallpaperDaemon
                        onToggled: {
                            ThemeState.autoStartWallpaperDaemon = !ThemeState.autoStartWallpaperDaemon;
                            ThemeState._persistState();
                            if (ThemeState.autoStartWallpaperDaemon)
                                ThemeState.ensureWallpaperDaemon();
                        }
                    }
                }

                // Which output the wallpaper grid below targets
                RowLayout {
                    id: targetRow
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingLg
                    spacing: UIScale.spacingSm
                    visible: Quickshell.screens.length > 1

                    Text {
                        text: I18n.t("wallpaper.applyTo")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                    }

                    StyledComboBox {
                        id: targetComboBox
                        model: [
                            {
                                value: "",
                                label: I18n.t("wallpaper.allMonitors")
                            }
                        ].concat(Quickshell.screens.map(s => ({
                                    value: s.name,
                                    label: s.name
                                })))
                        selectedValue: root.targetMonitor
                        onChosen: value => root.targetMonitor = value
                    }

                    ActionButton {
                        visible: root.targetMonitor !== "" && (root.targetMonitor in ThemeState.perMonitorWallpaper)
                        label: I18n.t("wallpaper.resetToGlobal")
                        onActivated: ThemeState.resetMonitor(root.targetMonitor)
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                // Which monitor's wallpaper the color scheme (matugen) is computed from
                RowLayout {
                    id: colorSourceRow
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingLg
                    spacing: UIScale.spacingSm
                    visible: Quickshell.screens.length > 1

                    Text {
                        text: I18n.t("wallpaper.colorsFromLabel")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                    }

                    StyledComboBox {
                        id: colorSourceComboBox
                        model: [
                            {
                                value: "",
                                label: I18n.t("wallpaper.allMonitors")
                            }
                        ].concat(Quickshell.screens.map(s => ({
                                    value: s.name,
                                    label: s.name
                                })))
                        selectedValue: ThemeState.colorSourceMonitor
                        onChosen: value => ThemeState.setColorSourceMonitor(value)
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingSm
                    visible: ThemeState.lastError !== ""
                    text: ThemeState.lastError
                    color: "#e05c5c"
                    font.pixelSize: UIScale.fontTiny
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingSm
                    visible: ThemeState.lastTemplateWarning !== ""
                    text: I18n.t("wallpaper.templateWarning", [ThemeState.lastTemplateWarning])
                    color: "#e0a15c"
                    font.pixelSize: UIScale.fontTiny
                    wrapMode: Text.WordWrap
                }

                // Current wallpaper preview
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(180 * UIScale.value)
                    Layout.bottomMargin: Math.round(24 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.surface
                    clip: true
                    visible: root._displayedWallpaper !== ""

                    Image {
                        anchors.fill: parent
                        source: root._displayedWallpaper !== "" ? ("file://" + root._displayedWallpaper) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(0, 0, 0, 0.45)
                        visible: ThemeState.applying

                        Text {
                            anchors.centerIn: parent
                            text: I18n.t("wallpaper.applying")
                            color: "white"
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.Medium
                        }
                    }
                }

                Text {
                    text: I18n.t("wallpaper.colorPalette")
                    color: Colors.text
                    font.pixelSize: UIScale.fontLead
                    font.weight: Font.DemiBold
                    Layout.bottomMargin: Math.round(16 * UIScale.value)
                }

                PaletteRow {
                    Layout.fillWidth: true
                    rowLabel: I18n.t("wallpaper.dark")
                    swatches: root._darkSwatches
                }
                PaletteRow {
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.radiusMd
                    rowLabel: I18n.t("wallpaper.light")
                    swatches: root._lightSwatches
                }
            }
        }
    }
}
