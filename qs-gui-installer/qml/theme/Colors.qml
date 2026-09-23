// Colors.qml - Pure black / white design tokens (English UI, SF Pro)
pragma Singleton
import QtQuick

QtObject {
    id: colors

    // Core palette — black background, white text
    readonly property color bg: "#000000"
    readonly property color bgElevated: "#0A0A0A"
    readonly property color bgSurface: "#111111"
    readonly property color bgSurfaceHover: "#1A1A1A"
    readonly property color bgMuted: "#161616"

    readonly property color text: "#FFFFFF"
    readonly property color textSecondary: "#A1A1A1"
    readonly property color textMuted: "#6E6E73"
    readonly property color textDim: "#48484A"

    readonly property color border: "#2C2C2E"
    readonly property color borderSubtle: "#1C1C1E"

    readonly property color accent: "#FFFFFF"
    readonly property color accentInverse: "#000000"
    readonly property color accentSoft: "#E5E5EA"

    readonly property color success: "#30D158"
    readonly property color warning: "#FFD60A"
    readonly property color danger: "#FF453A"
    readonly property color info: "#0A84FF"

    readonly property color bubbleSelf: "#FFFFFF"
    readonly property color bubbleSelfText: "#000000"
    readonly property color bubbleOther: "#1C1C1E"
    readonly property color bubbleOtherText: "#FFFFFF"

    readonly property color terminalGreen: "#30D158"
    readonly property color terminalBlue: "#0A84FF"
    readonly property color terminalText: "#E5E5EA"
    readonly property color terminalBg: "#0C0C0C"
    readonly property color terminalBorder: "#2C2C2E"

    readonly property color shimmerHighlight: "#FFFFFF"
    readonly property color particle: "#FFFFFF"

    readonly property color sidebarBg: "#050505"
    readonly property color sidebarActive: "#1C1C1E"
    readonly property color sidebarText: "#A1A1A1"
    readonly property color sidebarTextActive: "#FFFFFF"

    readonly property color ripple: "#ADD8E6"
    readonly property color progressTrack: "rgba(255, 255, 255, 0.1)"
    readonly property color progressFill: "#FFFFFF"
}
