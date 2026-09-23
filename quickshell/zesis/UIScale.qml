pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/uiscale.json"

    property real value: scaleData.value
    property real fontScale: scaleData.fontScale
    property real spacingScale: scaleData.spacingScale
    property real radiusScale: scaleData.radiusScale

    // Font tokens, use with font.pixelSize
    readonly property int fontTiny: Math.round(10.5 * value * fontScale)   // all-caps section labels
    readonly property int fontCaption: Math.round(11 * value * fontScale)  // breadcrumbs, meta info
    readonly property int fontSmall: Math.round(12 * value * fontScale)    // secondary text, buttons
    readonly property int fontBody: Math.round(13 * value * fontScale)     // primary body
    readonly property int fontLead: Math.round(14 * value * fontScale)     // nav items, labels
    readonly property int fontSubhead: Math.round(15 * value * fontScale)  // card titles
    readonly property int fontTitle: Math.round(22 * value * fontScale)    // widget/section title
    readonly property int fontHero: Math.round(26 * value * fontScale)     // page title

    // Spacing
    readonly property real spacingXs: 4 * value * spacingScale    // fine gaps, divider insets
    readonly property real spacingSm: 8 * value * spacingScale    // icon-label gaps, row item spacing, button padding
    readonly property real spacingMd: 14 * value * spacingScale   // panel content margins, section gaps, button horizontal padding
    readonly property real spacingLg: 20 * value * spacingScale   // outer panel margins, major section separation
    readonly property real panelPad: 30 * value * spacingScale    // settings panel side padding

    // Radius
    readonly property real radiusSm: 6 * value * radiusScale      // chips, badges, inline buttons, list rows
    readonly property real radiusMd: 10 * value * radiusScale     // popup panels, input fields, card sections
    readonly property real radiusLg: 14 * value * radiusScale     // large panel containers, notification cards
    readonly property real radiusXl: 16 * value * radiusScale     // large cards / hero

    function resetLivePreview() {
        value = Qt.binding(function () {
            return scaleData.value;
        });
    }

    function write(scaleV, fontV, spacingV, radiusV) {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && echo '{" + "\"value\":" + scaleV.toFixed(2) + "," + "\"fontScale\":" + fontV.toFixed(2) + "," + "\"spacingScale\":" + spacingV.toFixed(2) + "," + "\"radiusScale\":" + radiusV.toFixed(2) + "}' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: scaleData
        property real value: 1.0
        property real fontScale: 1.0
        property real spacingScale: 1.0
        property real radiusScale: 1.0
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: scaleData
        onFileChanged: reload()
    }

    Process {
        id: writeProc
        running: false
    }
}
