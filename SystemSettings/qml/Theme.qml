import QtQuick

QtObject {
    id: theme

    readonly property bool dark: Shell.userCfg && Shell.userCfg["darkMode"] === true

    readonly property color accent: (Shell.userCfg && Shell.userCfg["accentColor"]) ? Shell.userCfg["accentColor"] : "#0A84FF"
    readonly property color accentPressed: "#2688FF"
    readonly property color link: (Shell.userCfg && Shell.userCfg["highlightColor"]) ? Shell.userCfg["highlightColor"] : "#0A6CFF"

    readonly property int sidebarIconSize: {
        var a = (Shell.userCfg && Shell.userCfg["appearance"]) ? Shell.userCfg["appearance"] : null
        var m = a ? a["sidebarIconSize"] : undefined
        return m === "Small" ? 20 : (m === "Large" ? 28 : 24)
    }

    // Surfaces
    readonly property color sidebarBg: dark ? "#212121" : "#FAFAF9"
    readonly property color windowBg: dark ? "#1E1E1E" : "#FFFFFF"
    readonly property color cardBg: dark ? "#2C2C2E" : "#F7F7F7"
    readonly property color separator: dark ? "#3A3A3C" : "#EBEBEB"
    readonly property color hairline: dark ? "#38383A" : "#E3E3E3"
    readonly property color selectedBg: dark ? "#3A3A3C" : "#D7D7D7"
    readonly property color pressedBg: dark ? "#48484A" : "#CCCCCC"
    readonly property color searchBg: dark ? "#2C2C2E" : "#E6E6E6"
    readonly property color trackBg: dark ? "#3A3A3C" : "#E8E8EA"

    // Text
    readonly property color textPrimary: dark ? "#FFFFFF" : "#000000"
    readonly property color textDetail: dark ? "#E8E8E8" : "#262626"
    readonly property color textSecondary: dark ? "#989898" : "#7C7C7C"
    readonly property color textTertiary: dark ? "#6E6E73" : "#A8A8A8"
    readonly property color chevron: dark ? "#6E6E73" : "#B4B4B8"

    // Buttons
    readonly property color btnBg: dark ? "#3A3A3C" : "#ECECEE"
    readonly property color btnBgHover: dark ? "#48484A" : "#E4E4E6"
    readonly property color btnBgDisabled: dark ? "#2C2C2E" : "#F4F4F5"
    readonly property color btnText: dark ? "#FFFFFF" : "#1C1C1E"
    readonly property color btnTextDisabled: dark ? "#6E6E73" : "#B0B0B4"
    readonly property color btnBorder: Qt.rgba(0, 0, 0, 0.06)

    // Controls (pickers, popups, toggles, sliders)
    readonly property color controlBg: dark ? "#3A3A3C" : "#F1F1F2"
    readonly property color controlBorder: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.07)
    readonly property color menuBg: dark ? "#2C2C2E" : "#FAFAFB"
    readonly property color menuBorder: dark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)
    readonly property color toggleOff: dark ? "#39393D" : "#EFEFF0"
    readonly property color sliderTrack: dark ? "#3A3A3C" : "#DCDCDE"
    readonly property color checkBg: dark ? "#2C2C2E" : "#FFFFFF"
    readonly property color checkBorder: dark ? "#5A5A5E" : "#C6C6C8"

    // Toolbar (back/forward)
    readonly property color toolbarBtn: dark ? "#3A3A3C" : "#F1F1F3"
    readonly property color toolbarBtnHover: dark ? "#48484A" : "#E4E4E6"
    readonly property color toolbarBtnText: dark ? "#FFFFFF" : "#1C1C1E"
    readonly property color toolbarBtnTextDisabled: dark ? "#6E6E73" : "#C4C4C8"

    // Misc glyphs
    readonly property color glyphBg: dark ? "#3A3A3C" : "#E9E9EB"
    readonly property color glyphBgHover: dark ? "#48484A" : "#DEDEE0"
    readonly property color glyphFg: dark ? "#989898" : "#8A8A8E"
    readonly property color dotStroke: dark ? "#6E6E73" : "#A8A8AE"
    readonly property color dotFg: dark ? "#989898" : "#8E8E93"
    readonly property color placeholder: dark ? "#8A8A8E" : "#727272"
    readonly property color stroke: dark ? "#989898" : "#6E6E73"
    readonly property color red: "#E5484D"

    readonly property string fontText: "SF Pro Text"
    readonly property string fontDisplay: "SF Pro Display"
    readonly property string fontRounded: "SF Pro Rounded"

    readonly property int sidebarWidth: 215
    readonly property int detailWidth: 500
    readonly property int rowHeight: 38
    readonly property int iconSize: dark ? 24 : 24
    readonly property int detailRowHeight: 49
    readonly property int cardMargin: 12
    readonly property int cardRadius: 10

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
