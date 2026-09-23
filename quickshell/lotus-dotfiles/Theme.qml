import QtQuick

QtObject {
    id: theme

    readonly property string name: "Lotus Paper"
    readonly property int version: 1
    // Typography
    readonly property string fontFamily: "Maple Mono"
    readonly property string iconFontFamily: "Material Design Icons"
    readonly property int textXs: 10
    readonly property int textSm: 12
    readonly property int textMd: 14
    readonly property int textLg: 18
    readonly property int textXl: 28
    readonly property int textDisplay: 42
    // Neutral palette
    readonly property color canvas: "#F4E9E2"
    readonly property color canvasCool: "#DFE7ED"
    readonly property color canvasWarm: "#F4C7AE"
    readonly property color surface: "#F3E4DB"
    readonly property color surfaceRaised: "#FAEEE7"
    readonly property color surfaceMuted: "#E6D8D0"
    readonly property color ink: "#241B17"
    readonly property color inkMuted: "#776860"
    readonly property color outlineSoft: "#A28E84"
    // Pastels are semantic accents. Use one dominant accent per control.
    readonly property color peach: "#F7A184"
    readonly property color coral: "#EF7F7B"
    readonly property color pink: "#EFB2C1"
    readonly property color green: "#B8D995"
    readonly property color lilac: "#C8B6E3"
    readonly property color blue: "#8DBDD0"
    readonly property color gold: "#DDBB35"
    // State colors
    readonly property color success: green
    readonly property color warning: gold
    readonly property color danger: coral
    readonly property color focus: lilac
    readonly property color disabledFill: surfaceMuted
    readonly property color disabledInk: outlineSoft
    // Geometry
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 20
    readonly property int space6: 24
    readonly property int space8: 32
    readonly property int radiusControl: 10
    readonly property int radiusCard: 15
    readonly property int radiusPanel: 20
    readonly property int radiusPill: 999
    readonly property int borderWidth: 2
    readonly property int shadowOffset: 6
    readonly property color shadow: "#2A201C"
    readonly property int controlHeight: 38
    readonly property int compactControlSize: 32
    readonly property int islandMargin: 16
    readonly property int sideIslandHeight: compactControlSize + space4 + shadowOffset
    readonly property int mediaIslandHeight: 66
    readonly property int topReservedHeight: islandMargin + mediaIslandHeight
    readonly property int quickPanelWidth: 372
    readonly property int mediaIslandActiveWidth: 340
    readonly property int mediaIslandIdleWidth: 190
    readonly property int mediaArtworkSize: 42
    readonly property int launcherWidth: 620
    readonly property int launcherTopMargin: 92
    readonly property int launcherRowHeight: 54
    readonly property int launcherVisibleRows: 7
    readonly property int dashboardWidth: 560
    readonly property int dashboardTopMargin: 112
    readonly property int clipboardWidth: 620
    readonly property int clipboardTopMargin: 112
    readonly property int clipboardRowHeight: 54
    readonly property int notificationCenterWidth: 420
    readonly property int notificationCenterHeight: 680
    readonly property int notificationToastWidth: 380
    readonly property int notificationToastGap: 10
    readonly property int notificationToastLimit: 3
    readonly property int notificationHistoryLimit: 100
    readonly property int sessionMenuWidth: 560
    readonly property int iconSm: 16
    readonly property int iconMd: 20
    readonly property int iconLg: 24
    // Motion
    readonly property int motionFast: 110
    readonly property int motionNormal: 180
    readonly property int motionSlow: 260
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingExpressive: Easing.OutBack
    readonly property real pressScale: 0.97

    function alpha(colorValue, opacityValue) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacityValue);
    }

}
