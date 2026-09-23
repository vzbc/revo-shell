// Theme.qml - Design tokens (English only, SF Pro)
pragma Singleton
import QtQuick

QtObject {
    id: theme

    readonly property color bg: "#000000"
    readonly property color bgElevated: "#0A0A0A"
    readonly property color bgSurface: "#111111"
    readonly property color bgSurfaceHover: "#1A1A1A"
    readonly property color border: "#222222"
    readonly property color borderStrong: "#333333"

    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#A1A1A1"
    readonly property color textMuted: "#666666"

    readonly property color accent: "#FFFFFF"
    readonly property color accentInverse: "#000000"
    readonly property color blue: "#3B82F6"
    readonly property color green: "#22C55E"
    readonly property color indigo: "#4F46E5"
    readonly property color ripple: "#ADD8E6"

    readonly property string font: "SF Pro Display"
    readonly property string fontMono: "SF Mono"

    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusXl: 24
    readonly property int radiusFull: 999

    readonly property int sidebarWidth: 260
    readonly property int sidebarWidthCollapsed: 64
}
