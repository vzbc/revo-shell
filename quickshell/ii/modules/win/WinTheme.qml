import QtQuick
import qs.modules.common
pragma Singleton

/**
 * Windows 11 dark palette applied on top of the Material Appearance object.
 * These apps run in their own Quickshell process, so overriding the shared
 * Material palette here does not affect the rest of the shell.
 */
QtObject {
    id: root

    readonly property color bg: "#202020"
    readonly property color bgAlt: "#1b1b1b"
    readonly property color card: "#2b2b2b"
    readonly property color cardAlt: "#2f2f2f"
    readonly property color cardHover: "#303030"
    readonly property color cardPressed: "#353535"
    readonly property color border: "#3c3c3c"
    readonly property color text: "#ffffff"
    readonly property color textSecondary: "#9d9d9d"
    readonly property color textTertiary: "#6f6f6f"
    // Windows 11 default accent (blue). Used for toggles, buttons, sliders,
    // links, selection and the tinted navigation highlight.
    readonly property color accent: "#0067c0"
    readonly property color accentDark: "#00529b"
    readonly property color accentHover: "#1a86d9"
    readonly property color accentPressed: "#00498a"
    // Accent at low opacity, used as the selected sidebar/tile background.
    readonly property color accentSoft: "#300067c0"
    readonly property color onAccentColor: "#ffffff"
    readonly property color success: "#6ccb5f"
    readonly property color danger: "#ff6b68"
    readonly property color warning: "#ffb900"

    function apply() {
        // Solid, non-transparent surfaces for a native-feeling window
        Appearance.backgroundTransparency = 0
        Appearance.contentTransparency = 1

        const c = Appearance.m3colors
        c.transparent = false
        c.darkmode = true
        c.m3background = root.bg
        c.m3surface = root.bg
        c.m3surfaceDim = root.bgAlt
        c.m3surfaceBright = "#3a3a3a"
        c.m3surfaceContainerLowest = root.bgAlt
        c.m3surfaceContainerLow = root.card
        c.m3surfaceContainer = root.cardAlt
        c.m3surfaceContainerHigh = "#3a3a3a"
        c.m3surfaceContainerHighest = "#454545"
        c.m3onSurface = root.text
        c.m3surfaceVariant = "#3d3d3d"
        c.m3onSurfaceVariant = root.textSecondary
        c.m3inverseSurface = "#e6e1e1"
        c.m3inverseOnSurface = "#313030"
        c.m3outline = root.textTertiary
        c.m3outlineVariant = root.border
        c.m3shadow = "#000000"
        c.m3scrim = "#000000"
        c.m3surfaceTint = root.accent
        c.m3primary = root.accent
        c.m3onPrimary = root.onAccentColor
        c.m3primaryContainer = "#214a63"
        c.m3onPrimaryContainer = "#c9e9ff"
        c.m3inversePrimary = "#60cdff"
        c.m3secondary = "#d6e3ec"
        c.m3onSecondary = "#39464e"
        c.m3secondaryContainer = "#4a5760"
        c.m3onSecondaryContainer = "#e5f1fb"
        c.m3tertiary = "#c3e8c8"
        c.m3onTertiary = "#2a3a2d"
        c.m3tertiaryContainer = "#37513d"
        c.m3onTertiaryContainer = "#d3e9d8"
        c.m3error = root.danger
        c.m3onError = "#4a0000"
        c.m3errorContainer = "#8a0000"
        c.m3onErrorContainer = "#ffdad6"
        c.m3success = root.success
        c.m3onSuccess = "#0f3d0b"
        c.m3successContainer = "#1f5c18"
        c.m3onSuccessContainer = "#c8f2bd"
        c.m3primaryFixed = "#c9e9ff"
        c.m3primaryFixedDim = root.accent
        c.m3onPrimaryFixed = "#0a3145"
        c.m3onPrimaryFixedVariant = "#1d5a7d"
        c.m3secondaryFixed = "#d6e3ec"
        c.m3secondaryFixedDim = "#b5c2cc"
        c.m3onSecondaryFixed = "#1c2a33"
        c.m3onSecondaryFixedVariant = "#3a4952"
        c.m3tertiaryFixed = "#c3e8c8"
        c.m3tertiaryFixedDim = "#a3cba9"
        c.m3onTertiaryFixed = "#182a1b"
        c.m3onTertiaryFixedVariant = "#354c39"
    }
}
