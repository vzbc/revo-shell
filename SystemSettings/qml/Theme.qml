import QtQuick

// macOS 27 (Tahoe design language) tokens for System Settings.
// Metrics follow the Liquid Glass layout: floating inset sidebar, capsule
// controls, glass toolbar, rounded grouped forms.
QtObject {
    id: theme

    readonly property var cfg: Shell ? Shell.userCfg : ({})
    function cfgVal(k, d) {
        return (cfg && cfg[k] !== undefined && cfg[k] !== null && cfg[k] !== "") ? cfg[k] : d
    }

    readonly property bool dark: cfgVal("darkMode", false) === true

    readonly property color accent: cfgVal("accentColor", "#0A84FF")
    readonly property color accentPressed: Qt.darker(accent, 1.15)
    readonly property color link: cfgVal("highlightColor", "#0A6CFF")

    readonly property int sidebarIconSize: {
        var a = cfgVal("appearance", null)
        var m = a ? a["sidebarIconSize"] : undefined
        return m === "Small" ? 20 : (m === "Large" ? 28 : 24)
    }

    // ---- Liquid Glass ------------------------------------------------------
    // "Clear" lets more of the desktop through; "Tinted" is more opaque.
    readonly property string glassStyle: cfgVal("liquidGlass", "Clear")
    readonly property real glassTint: {
        var v = Number(cfgVal("liquidGlassIntensity", 0))
        return isNaN(v) ? 0 : Math.max(0, Math.min(1, v))
    }
    readonly property bool reduceTransparency: {
        var a = cfgVal("accessibility", null)
        return a ? a["reduceTransparency"] === true : false
    }
    readonly property bool increaseContrast: {
        var a = cfgVal("accessibility", null)
        return a ? a["increaseContrast"] === true : false
    }
    readonly property real glassAlpha: reduceTransparency ? 1.0
        : (glassStyle === "Tinted" ? 0.78 : 0.56) + glassTint * 0.2
    readonly property bool wallpaperTinting: {
        var a = cfgVal("appearance", null)
        return a ? a["wallpaperTinting"] === true : false
    }

    // Window
    readonly property int windowRadius: 26
    readonly property int sidebarInset: 8
    readonly property int sidebarRadius: windowRadius - sidebarInset   // concentric
    readonly property color windowFrame: dark ? "#1E1E1E" : "#F5F5F5"
    readonly property color windowStroke: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)

    // Glass surfaces
    readonly property color glassFill: dark ? Qt.rgba(0.19, 0.19, 0.20, glassAlpha)
                                            : Qt.rgba(0.97, 0.97, 0.98, glassAlpha)
    readonly property color glassStrokeTop: dark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.95)
    readonly property color glassStrokeBottom: dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color glassShadow: dark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color glassControl: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.78)
    readonly property color glassControlHover: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.95)
    readonly property color glassControlStroke: increaseContrast ? (dark ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.55))
                                                                 : (dark ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(0, 0, 0, 0.09))

    // Surfaces
    readonly property color sidebarBg: glassFill
    readonly property color windowBg: wallpaperTinting && !reduceTransparency
        ? (dark ? Qt.rgba(0.118, 0.118, 0.118, 0.90) : Qt.rgba(0.96, 0.96, 0.96, 0.90))
        : windowFrame
    readonly property color cardBg: dark ? Qt.rgba(1, 1, 1, 0.055) : "#FFFFFF"
    readonly property color cardStroke: increaseContrast ? (dark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45))
                                                         : (dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.055))
    readonly property color separator: increaseContrast ? (dark ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(0, 0, 0, 0.30))
                                                        : (dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.075))
    readonly property color hairline: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color selectedBg: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color hoverBg: dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.045)
    readonly property color pressedBg: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color searchBg: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
    readonly property color trackBg: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)

    // Text
    readonly property color textPrimary: dark ? "#F5F5F7" : "#1D1D1F"
    readonly property color textDetail: dark ? "#EDEDF0" : "#262626"
    readonly property color textSecondary: dark ? Qt.rgba(0.92, 0.92, 0.96, 0.55) : Qt.rgba(0, 0, 0, 0.50)
    readonly property color textTertiary: dark ? Qt.rgba(0.92, 0.92, 0.96, 0.30) : Qt.rgba(0, 0, 0, 0.26)
    readonly property color chevron: dark ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(0, 0, 0, 0.26)

    // Buttons (capsule, glass)
    readonly property color btnBg: glassControl
    readonly property color btnBgHover: glassControlHover
    readonly property color btnBgDisabled: dark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03)
    readonly property color btnText: textPrimary
    readonly property color btnTextDisabled: textTertiary
    readonly property color btnBorder: glassControlStroke

    // Controls
    readonly property color controlBg: glassControl
    readonly property color controlBorder: glassControlStroke
    readonly property color menuBg: dark ? Qt.rgba(0.16, 0.16, 0.17, 0.97) : Qt.rgba(0.98, 0.98, 0.99, 0.97)
    readonly property color menuBorder: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color toggleOff: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color sliderTrack: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color checkBg: dark ? Qt.rgba(1, 1, 1, 0.10) : "#FFFFFF"
    readonly property color checkBorder: dark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.20)
    readonly property color knob: "#FFFFFF"
    readonly property color knobShadow: Qt.rgba(0, 0, 0, dark ? 0.45 : 0.22)

    // Toolbar (back/forward capsule)
    readonly property color toolbarBtn: glassControl
    readonly property color toolbarBtnHover: glassControlHover
    readonly property color toolbarBtnText: textPrimary
    readonly property color toolbarBtnTextDisabled: textTertiary

    // Misc glyphs
    readonly property color glyphBg: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color glyphBgHover: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color glyphFg: textSecondary
    readonly property color dotStroke: dark ? Qt.rgba(1, 1, 1, 0.40) : Qt.rgba(0, 0, 0, 0.35)
    readonly property color dotFg: dark ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.45)
    readonly property color placeholder: dark ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(0, 0, 0, 0.40)
    readonly property color stroke: dark ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.50)
    readonly property color red: "#FF453A"

    readonly property string fontText: "SF Pro Text"
    readonly property string fontDisplay: "SF Pro Display"
    readonly property string fontRounded: "SF Pro Rounded"

    // Metrics
    readonly property int sidebarWidth: 230          // incl. inset
    readonly property int detailWidth: 500
    readonly property int rowHeight: 34
    readonly property int rowRadius: 10
    readonly property int iconSize: 24
    readonly property int detailRowHeight: 44
    readonly property int cardMargin: 16
    readonly property int cardRadius: 14
    readonly property int controlHeight: 24
    readonly property int toolbarHeight: 52

    function icon(name, px) {
        if (name.length === 0)
            return ""
        var n = name
        if (dark && name.indexOf("sb_") === 0)
            n = name + "_dk"
        if (px === undefined)
            px = iconSize
        var sizes = [24, 32, 64, 84]
        var best = sizes[sizes.length - 1]
        for (var i = 0; i < sizes.length; i++) {
            if (px <= sizes[i]) { best = sizes[i]; break }
        }
        return "qrc:/icons/" + n + "@" + best + ".png"
    }
}
