import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../../"
import "../shared"

Item {
    id: root

    property real _scaleVal: UIScale.value
    property real _fontVal: UIScale.fontScale
    property real _spacingVal: UIScale.spacingScale
    property real _radiusVal: UIScale.radiusScale

    // Palette being edited in the Colors section, and the role whose picker is
    // currently open (only one at a time).
    property string _editPalette: ThemeState.palette
    property string _openRole: ""

    readonly property var _swatchClusters: [["background", "surface_container", "surface_container_high", "outline_variant"], ["primary", "primary_fixed_dim", "primary_container", "on_primary"], ["on_background", "on_surface_variant"], ["bar"]]

    Timer {
        id: writeTimer
        interval: 0
        onTriggered: UIScale.write(root._scaleVal, root._fontVal, root._spacingVal, root._radiusVal)
    }

    function _roleById(id) {
        if (!id)
            return null;
        var roles = ColorOverrides.roles;
        for (var i = 0; i < roles.length; i++) {
            if (roles[i].id === id)
                return roles[i];
        }
        return null;
    }

    function _effectiveColor(roleId) {
        var raw = root._editPalette === "dark" ? Colors.rawDarkPalette : Colors.rawLightPalette;
        if (roleId === "bar") {
            var bar = ColorOverrides.get(root._editPalette, "bar");
            return bar.length > 0 ? bar : raw.background;
        }
        var ov = ColorOverrides.get(root._editPalette, roleId);
        return ov.length > 0 ? ov : (raw[roleId] || "#000000");
    }

    // Whether a role's effective color actually differs from what this
    // wallpaper's own matugen generation would give it. isOverridden() alone
    // isn't enough: applying a saved theme writes every role into
    // ColorOverrides (Themes.qml snapshots the full palette, not just the
    // roles that were hand-picked), so right after loading a theme every
    // role would otherwise read as "customized" even the ones that just
    // happen to match the wallpaper's own colors. "bar" has no wallpaper
    // role to compare against, so it stays presence-based.
    function _isCustomized(roleId) {
        if (roleId === "bar")
            return ColorOverrides.isOverridden(root._editPalette, "bar");
        var raw = root._editPalette === "dark" ? Colors.rawDarkPalette : Colors.rawLightPalette;
        var baseline = raw[roleId];
        if (!baseline)
            return ColorOverrides.isOverridden(root._editPalette, roleId);
        return root._effectiveColor(roleId).toLowerCase() !== baseline.toLowerCase();
    }

    // The picker fires on every drag step; coalesce so a drag doesn't turn into
    // a write per frame.
    property string _pendingRole: ""
    property string _pendingHex: ""

    function _queueColor(roleId, hex) {
        root._pendingRole = roleId;
        root._pendingHex = hex;
        colorWriteTimer.restart();
    }

    Timer {
        id: colorWriteTimer
        interval: 120
        onTriggered: ColorOverrides.set(root._editPalette, root._pendingRole, root._pendingHex)
    }

    // Overwriting an existing theme needs a second click within a few
    // seconds to confirm, same two-step pattern as the destructive actions
    // in PowerMenu.qml - saving a brand new name (no existing match) still
    // goes through in one click.
    property string _saveArmedFor: ""

    Timer {
        id: saveArmTimer
        interval: 3000
        onTriggered: root._saveArmedFor = ""
    }

    readonly property string _typedName: themeNameField.text.trim()
    readonly property bool _typedMatchesActive: root._typedName.length === 0 && Themes.activeIsDirty

    function _saveTheme() {
        if (root._typedMatchesActive) {
            Themes.save(Themes.activeThemeName);
            root._saveArmedFor = "";
            return;
        }
        var name = root._typedName;
        if (name.length === 0)
            return;
        if (Themes.exists(name) && root._saveArmedFor !== name) {
            root._saveArmedFor = name;
            saveArmTimer.restart();
            return;
        }
        Themes.save(name);
        themeNameField.text = "";
        root._saveArmedFor = "";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("appearance.breadcrumb")
            title: I18n.t("appearance.title")
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: content.implicitHeight + UIScale.spacingLg * 2
            clip: true
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: content
                x: UIScale.panelPad
                y: UIScale.spacingLg
                width: parent.width - UIScale.panelPad * 2
                spacing: UIScale.spacingMd

                // Sizing
                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm
                        SectionLabel {
                            text: I18n.t("appearance.sizing")
                        }
                        InfoTooltip {
                            text: I18n.t("appearance.sizingDescription")
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: I18n.t("appearance.interfaceScale")
                            color: Colors.text
                            font.bold: true
                            font.pixelSize: UIScale.fontBody
                            Layout.fillWidth: true
                        }
                        Text {
                            text: I18n.t("appearance.multiplier", [root._scaleVal.toFixed(2)])
                            color: Colors.accent
                            font.bold: true
                            font.pixelSize: UIScale.fontBody
                        }
                    }
                    SettingSlider {
                        Layout.fillWidth: true
                        from: 0.5
                        to: 2.0
                        step: 0.05
                        value: root._scaleVal
                        onMoved: function (v) {
                            root._scaleVal = v;
                            writeTimer.restart();
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm
                        Repeater {
                            model: [[I18n.t("appearance.small"), 0.85], [I18n.t("appearance.normal"), 1.0], [I18n.t("appearance.large"), 1.3]]
                            delegate: Rectangle {
                                id: scalePreset
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Math.round(28 * UIScale.value)
                                radius: UIScale.radiusSm
                                color: Math.abs(root._scaleVal - scalePreset.modelData[1]) < 0.01 ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                                border.color: Math.abs(root._scaleVal - scalePreset.modelData[1]) < 0.01 ? Colors.accent : "transparent"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: scalePreset.modelData[0]
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontCaption
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root._scaleVal = scalePreset.modelData[1];
                                        writeTimer.restart();
                                    }
                                }
                            }
                        }
                    }

                    Divider {
                        Layout.topMargin: UIScale.spacingXs
                        color: Colors.withAlpha(Colors.text, 0.06)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: I18n.t("appearance.fontSize")
                            color: Colors.text
                            font.bold: true
                            font.pixelSize: UIScale.fontBody
                            Layout.fillWidth: true
                        }
                        Text {
                            text: I18n.t("appearance.multiplier", [root._fontVal.toFixed(2)])
                            color: Colors.accent
                            font.bold: true
                            font.pixelSize: UIScale.fontBody
                        }
                    }
                    SettingSlider {
                        Layout.fillWidth: true
                        from: 0.5
                        to: 2.0
                        step: 0.05
                        value: root._fontVal
                        onMoved: function (v) {
                            root._fontVal = v;
                            writeTimer.restart();
                        }
                    }

                    Divider {
                        Layout.topMargin: UIScale.spacingXs
                        color: Colors.withAlpha(Colors.text, 0.06)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: I18n.t("appearance.spacing")
                            color: Colors.text
                            font.bold: true
                            font.pixelSize: UIScale.fontBody
                            Layout.fillWidth: true
                        }
                        Text {
                            text: I18n.t("appearance.multiplier", [root._spacingVal.toFixed(2)])
                            color: Colors.accent
                            font.bold: true
                            font.pixelSize: UIScale.fontBody
                        }
                    }
                    SettingSlider {
                        Layout.fillWidth: true
                        from: 0.5
                        to: 2.0
                        step: 0.05
                        value: root._spacingVal
                        onMoved: function (v) {
                            root._spacingVal = v;
                            writeTimer.restart();
                        }
                    }

                    Divider {
                        Layout.topMargin: UIScale.spacingXs
                        color: Colors.withAlpha(Colors.text, 0.06)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: I18n.t("appearance.radius")
                            color: Colors.text
                            font.bold: true
                            font.pixelSize: UIScale.fontBody
                            Layout.fillWidth: true
                        }
                        Text {
                            text: I18n.t("appearance.multiplier", [root._radiusVal.toFixed(2)])
                            color: Colors.accent
                            font.bold: true
                            font.pixelSize: UIScale.fontBody
                        }
                    }
                    SettingSlider {
                        Layout.fillWidth: true
                        from: 0.5
                        to: 2.0
                        step: 0.05
                        value: root._radiusVal
                        onMoved: function (v) {
                            root._radiusVal = v;
                            writeTimer.restart();
                        }
                    }
                }

                // Palette colors
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingXs
                    spacing: UIScale.spacingSm
                    SectionLabel {
                        text: I18n.t("appearance.colors")
                    }
                    InfoTooltip {
                        text: I18n.t("appearance.colorsDescription")
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }

                // Master color override switch
                SettingCard {
                    Layout.topMargin: UIScale.spacingXs

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: I18n.t("appearance.overridesEnabled")
                                color: Colors.text
                                font.weight: Font.DemiBold
                                font.pixelSize: UIScale.fontBody
                            }
                            Text {
                                Layout.fillWidth: true
                                text: ColorOverrides.enabled ? I18n.t("appearance.overridesEnabledHint") : I18n.t("appearance.overridesDisabledHint")
                                color: Colors.muted
                                font.pixelSize: UIScale.fontTiny
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: ColorOverrides.enabled
                            onToggled: ColorOverrides.setEnabled(!ColorOverrides.enabled)
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: ColorOverrides.enabled
                    visible: active
                    sourceComponent: Component {
                        // Colors override body
                        ColumnLayout {
                            spacing: UIScale.spacingMd

                            // Scope + Editing + the color picker
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: UIScale.spacingLg

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    Layout.alignment: Qt.AlignTop
                                    spacing: UIScale.spacingSm

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: UIScale.spacingLg

                                        // Edits apply to the active wallpaper or globally
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 0
                                            Layout.alignment: Qt.AlignTop
                                            spacing: UIScale.spacingSm

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: UIScale.spacingSm
                                                SectionLabel {
                                                    text: I18n.t("appearance.scopeLabel")
                                                }
                                                InfoTooltip {
                                                    text: ColorOverrides.scope === "global" ? I18n.t("appearance.scopeGlobalDescription") : I18n.t("appearance.scopeWallpaperDescription")
                                                }
                                                Item {
                                                    Layout.fillWidth: true
                                                }
                                            }
                                            OptionRow {
                                                Layout.fillWidth: true
                                                model: [I18n.t("appearance.scopeWallpaper"), I18n.t("appearance.scopeGlobal")]
                                                currentIndex: ColorOverrides.scope === "global" ? 1 : 0
                                                onActivated: index => ColorOverrides.setScope(index === 1 ? "global" : "wallpaper")
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 0
                                            Layout.alignment: Qt.AlignTop
                                            spacing: UIScale.spacingSm

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: UIScale.spacingSm
                                                SectionLabel {
                                                    text: I18n.t("appearance.editingLabel")
                                                }
                                                InfoTooltip {
                                                    text: I18n.t("appearance.editingDescription")
                                                }
                                                Item {
                                                    Layout.fillWidth: true
                                                }
                                            }
                                            OptionRow {
                                                id: paletteRow
                                                Layout.fillWidth: true
                                                readonly property var _labels: [ThemeState.palette === "dark" ? I18n.t("appearance.paletteActive", [I18n.t("appearance.dark")]) : I18n.t("appearance.dark"), ThemeState.palette === "light" ? I18n.t("appearance.paletteActive", [I18n.t("appearance.light")]) : I18n.t("appearance.light")]
                                                model: paletteRow._labels
                                                currentIndex: root._editPalette === "light" ? 1 : 0
                                                onActivated: index => {
                                                    root._editPalette = index === 1 ? "light" : "dark";
                                                    root._openRole = "";
                                                }
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                visible: root._editPalette !== ThemeState.palette
                                                text: I18n.t("appearance.editingInactive", [root._editPalette === "dark" ? I18n.t("appearance.dark") : I18n.t("appearance.light")])
                                                color: Colors.muted
                                                font.pixelSize: UIScale.fontCaption
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                    }

                                    // Editor for the tile that's open
                                    Rectangle {
                                        id: roleEditorFrame
                                        Layout.fillWidth: true
                                        visible: roleEditor.role !== null
                                        implicitHeight: roleEditor.implicitHeight + UIScale.spacingMd * 2
                                        radius: UIScale.radiusMd
                                        color: Colors.withAlpha(Colors.text, 0.025)
                                        border.color: Colors.withAlpha(Colors.text, 0.05)
                                        border.width: 1

                                        ColumnLayout {
                                            id: roleEditor
                                            anchors.fill: parent
                                            anchors.margins: UIScale.spacingMd
                                            spacing: UIScale.spacingSm

                                            readonly property var role: root._roleById(root._openRole)

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: UIScale.spacingSm

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 0
                                                    Text {
                                                        text: roleEditor.role ? roleEditor.role.label : ""
                                                        color: Colors.text
                                                        font.bold: true
                                                        font.pixelSize: UIScale.fontBody
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: roleEditor.role ? roleEditor.role.desc : ""
                                                        color: Colors.muted
                                                        font.pixelSize: UIScale.fontTiny
                                                        wrapMode: Text.WordWrap
                                                    }
                                                }
                                                ActionButton {
                                                    visible: root._isCustomized(root._openRole)
                                                    label: I18n.t("appearance.reset")
                                                    onActivated: ColorOverrides.clear(root._editPalette, root._openRole)
                                                }
                                            }

                                            ColorPicker {
                                                Layout.fillWidth: true
                                                value: root._effectiveColor(root._openRole)
                                                onPicked: function (hex) {
                                                    root._queueColor(root._openRole, hex);
                                                }
                                            }
                                        }
                                    }
                                }

                                // Swatch grid, palette column
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    Layout.alignment: Qt.AlignTop
                                    spacing: UIScale.spacingSm

                                    SectionLabel {
                                        text: I18n.t("appearance.colorPalette")
                                    }

                                    Flow {
                                        id: clusterFlow
                                        Layout.fillWidth: true
                                        spacing: Math.round(18 * UIScale.value)

                                        Repeater {
                                            model: root._swatchClusters
                                            delegate: Grid {
                                                id: clusterGrid

                                                required property var modelData
                                                readonly property var _tileRoles: clusterGrid.modelData.map(id => root._roleById(id))
                                                readonly property real _cellPitch: Math.round(52 * UIScale.value) + UIScale.spacingSm
                                                readonly property real _availableWidth: clusterGrid.parent ? clusterGrid.parent.width : 0
                                                readonly property int _maxCols: Math.max(1, Math.floor((clusterGrid._availableWidth + UIScale.spacingSm) / clusterGrid._cellPitch))

                                                columns: Math.min(clusterGrid._tileRoles.length, clusterGrid._maxCols)
                                                columnSpacing: UIScale.spacingSm
                                                rowSpacing: UIScale.spacingSm

                                                Repeater {
                                                    model: clusterGrid._tileRoles
                                                    delegate: Item {
                                                        id: roleTile

                                                        required property var modelData
                                                        readonly property string roleId: roleTile.modelData.id
                                                        readonly property bool overridden: ColorOverrides.enabled && root._isCustomized(roleTile.roleId)
                                                        readonly property bool selected: root._openRole === roleTile.roleId

                                                        implicitWidth: Math.round(52 * UIScale.value)
                                                        implicitHeight: Math.round(70 * UIScale.value)

                                                        Rectangle {
                                                            id: tileSwatch
                                                            anchors.top: parent.top
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            width: Math.round(46 * UIScale.value)
                                                            height: Math.round(46 * UIScale.value)
                                                            radius: Math.round(10 * UIScale.value)
                                                            color: root._effectiveColor(roleTile.roleId)
                                                            border.color: roleTile.overridden ? Colors.accent : Colors.withAlpha(Colors.text, 0.08)
                                                            border.width: roleTile.overridden ? 2 : 1
                                                            Behavior on border.color {
                                                                ColorAnimation {
                                                                    duration: Anim.fast
                                                                }
                                                            }

                                                            Rectangle {
                                                                anchors.fill: parent
                                                                anchors.margins: -Math.round(3 * UIScale.value)
                                                                radius: parent.radius + Math.round(3 * UIScale.value)
                                                                color: "transparent"
                                                                visible: roleTile.selected
                                                                border.color: Colors.withAlpha(Colors.accent, 0.5)
                                                                border.width: roleTile.selected ? 2 : 0
                                                                Behavior on border.width {
                                                                    NumberAnimation {
                                                                        duration: Anim.fast
                                                                    }
                                                                }
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root._openRole = roleTile.selected ? "" : roleTile.roleId
                                                            }
                                                        }

                                                        Text {
                                                            anchors.top: tileSwatch.bottom
                                                            anchors.topMargin: UIScale.spacingXs
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: roleTile.modelData.label
                                                            color: roleTile.selected ? Colors.accent : Colors.textDim
                                                            font.pixelSize: Math.round(9 * UIScale.value)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            ActionButton {
                                Layout.topMargin: UIScale.spacingXs
                                ghost: true
                                label: I18n.t("appearance.resetPaletteColors", [root._editPalette === "dark" ? I18n.t("appearance.dark") : I18n.t("appearance.light")])
                                onActivated: ColorOverrides.clearPalette(root._editPalette)
                            }
                        }
                    }
                }

                Divider {
                    color: Colors.withAlpha(Colors.accent, 0.1)
                }

                // Saved themes
                RowLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingSm
                    SectionLabel {
                        text: I18n.t("appearance.themes")
                    }
                    InfoTooltip {
                        text: I18n.t("appearance.themesDescription")
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingXs
                    spacing: UIScale.spacingSm

                    StyledTextInput {
                        id: themeNameField
                        Layout.fillWidth: true
                        placeholder: I18n.t("appearance.themeNamePlaceholder")
                        onAccepted: root._saveTheme()
                    }
                    ActionButton {
                        readonly property bool _armed: root._saveArmedFor !== "" && root._saveArmedFor === root._typedName
                        readonly property bool _disabled: root._typedName.length === 0 && !root._typedMatchesActive
                        label: _armed ? I18n.t("appearance.saveThemeConfirm") : root._typedMatchesActive ? I18n.t("appearance.updateTheme", [Themes.activeThemeName]) : I18n.t("appearance.saveTheme")
                        enabled: !_disabled
                        onActivated: root._saveTheme()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingSm
                    visible: Themes.themes.length === 0
                    text: I18n.t("appearance.noThemesSaved")
                    color: Colors.muted
                    font.pixelSize: UIScale.fontCaption
                }

                Repeater {
                    model: Themes.themes
                    delegate: Item {
                        id: themeRow
                        required property var modelData
                        readonly property bool hasWallpaper: Themes.hasWallpaper(themeRow.modelData)
                        readonly property bool isActive: ColorOverrides.enabled && Themes.activeThemeName === themeRow.modelData.name
                        readonly property bool isDirty: themeRow.isActive && Themes.isDirty(themeRow.modelData.name)
                        readonly property string wallpaperPath: Themes.primaryWallpaper(themeRow.modelData)
                        property bool renaming: false

                        function confirmRename() {
                            if (Themes.rename(themeRow.modelData.name, renameField.text))
                                themeRow.renaming = false;
                        }

                        Layout.fillWidth: true
                        Layout.topMargin: UIScale.spacingSm
                        implicitHeight: rowCard.implicitHeight

                        HoverHandler {
                            id: rowHover
                        }

                        Rectangle {
                            id: rowCard
                            anchors.left: parent.left
                            anchors.right: parent.right
                            radius: UIScale.radiusMd
                            color: Colors.withAlpha(Colors.text, rowHover.hovered ? 0.05 : 0.03)
                            border.color: themeRow.isActive ? Colors.withAlpha(Colors.accent, 0.35) : Colors.withAlpha(Colors.text, 0.06)
                            border.width: 1
                            implicitHeight: rowContent.implicitHeight + UIScale.spacingMd * 2
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                z: -1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (!themeRow.renaming)
                                    Themes.apply(themeRow.modelData.name)
                            }

                            ColumnLayout {
                                id: rowContent
                                anchors.fill: parent
                                anchors.margins: UIScale.spacingMd
                                spacing: Math.round(4 * UIScale.value)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: UIScale.spacingSm

                                    Rectangle {
                                        id: thumbRect
                                        implicitWidth: Math.round(34 * UIScale.value)
                                        implicitHeight: implicitWidth
                                        radius: UIScale.radiusSm
                                        color: Colors.surfaceHigh
                                        clip: true

                                        Image {
                                            id: thumbImg
                                            anchors.fill: parent
                                            visible: themeRow.hasWallpaper
                                            source: themeRow.hasWallpaper ? ("file://" + ThemeState.thumbsDir + "/" + themeRow.wallpaperPath.substring(themeRow.wallpaperPath.lastIndexOf("/") + 1) + ".jpg") : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            onStatusChanged: {
                                                if (status === Image.Error && !thumbGen.running)
                                                    thumbGen.running = true;
                                            }
                                        }

                                        Process {
                                            id: thumbGen
                                            command: ["magick", themeRow.wallpaperPath, "-resize", "68x68^", "-gravity", "Center", "-extent", "68x68", ThemeState.thumbsDir + "/" + themeRow.wallpaperPath.substring(themeRow.wallpaperPath.lastIndexOf("/") + 1) + ".jpg"]
                                            onExited: (code, status) => {
                                                if (code === 0) {
                                                    thumbImg.source = "";
                                                    thumbImg.source = "file://" + ThemeState.thumbsDir + "/" + themeRow.wallpaperPath.substring(themeRow.wallpaperPath.lastIndexOf("/") + 1) + ".jpg";
                                                } else {
                                                    thumbImg.source = "file://" + themeRow.wallpaperPath;
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        visible: !themeRow.renaming
                                        text: themeRow.modelData.name
                                        color: themeRow.isActive ? Colors.accent : Colors.text
                                        font.bold: themeRow.isActive
                                        font.pixelSize: UIScale.fontBody
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: Math.round(220 * UIScale.value)
                                    }

                                    StyledTextInput {
                                        id: renameField
                                        visible: themeRow.renaming
                                        Layout.fillWidth: true
                                        text: themeRow.modelData.name
                                        onAccepted: themeRow.confirmRename()
                                        onEscapePressed: themeRow.renaming = false
                                        onVisibleChanged: if (visible)
                                            field.forceActiveFocus()
                                    }

                                    // Rename
                                    Rectangle {
                                        visible: !themeRow.renaming
                                        opacity: rowHover.hovered ? 1 : 0
                                        implicitWidth: Math.round(26 * UIScale.value)
                                        implicitHeight: Math.round(26 * UIScale.value)
                                        radius: UIScale.radiusSm
                                        color: renameHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            font.family: "Material Icons"
                                            font.pixelSize: Math.round(14 * UIScale.value)
                                            color: Colors.textDim
                                        }
                                        HoverHandler {
                                            id: renameHov
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: themeRow.renaming = true
                                        }
                                    }

                                    Item {
                                        visible: !themeRow.renaming
                                        Layout.fillWidth: true
                                    }

                                    // Active / Active-edited badge
                                    RowLayout {
                                        visible: themeRow.isActive && !themeRow.renaming
                                        spacing: Math.round(4 * UIScale.value)
                                        Rectangle {
                                            implicitWidth: Math.round(7 * UIScale.value)
                                            implicitHeight: implicitWidth
                                            radius: implicitWidth / 2
                                            color: Colors.accent
                                        }
                                        Text {
                                            text: themeRow.isDirty ? I18n.t("appearance.themeActiveEdited") : I18n.t("appearance.themeActive")
                                            color: Colors.accent
                                            font.pixelSize: UIScale.fontTiny
                                            font.weight: themeRow.isDirty ? Font.DemiBold : Font.Normal
                                        }
                                    }

                                    ActionButton {
                                        visible: themeRow.renaming
                                        label: I18n.t("appearance.renameConfirm")
                                        onActivated: themeRow.confirmRename()
                                    }
                                    ActionButton {
                                        visible: themeRow.renaming
                                        label: I18n.t("appearance.renameCancel")
                                        onActivated: themeRow.renaming = false
                                    }

                                    // Pinned persistent state
                                    ToggleSwitch {
                                        visible: !themeRow.renaming
                                        checked: !!themeRow.modelData.pinned
                                        onToggled: Themes.togglePinned(themeRow.modelData.name)
                                    }
                                    Text {
                                        visible: !themeRow.renaming
                                        text: I18n.t("appearance.pinned")
                                        color: Colors.textDim
                                        font.pixelSize: UIScale.fontTiny
                                    }

                                    // Delete
                                    ActionButton {
                                        visible: !themeRow.renaming
                                        ghost: true
                                        opacity: rowHover.hovered ? 1 : 0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                        label: I18n.t("appearance.deleteTheme")
                                        onActivated: Themes.remove(themeRow.modelData.name)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: themeRow.modelData.pinned && !themeRow.hasWallpaper
                                    text: I18n.t("appearance.pinnedNoWallpaperHint")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontTiny
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
