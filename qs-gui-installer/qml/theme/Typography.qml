// Typography.qml - SF Pro type scale (English UI)
pragma Singleton
import QtQuick

QtObject {
    id: type

    // Primary family — SF Pro everywhere; fall back gracefully on Linux
    readonly property string family: "SF Pro Display"
    readonly property string familyText: "SF Pro Text"
    readonly property string familyMono: "SF Mono"

    // Fallback chain resolved at runtime by FontLoader / Text font.family
    readonly property string fallback: "Helvetica Neue, Inter, Roboto, Noto Sans, sans-serif"

    readonly property int hero: 56
    readonly property int title: 40
    readonly property int headline: 32
    readonly property int subtitle: 24
    readonly property int bodyLg: 18
    readonly property int body: 16
    readonly property int caption: 14
    readonly property int footnote: 13
    readonly property int caption2: 12
    readonly property int micro: 11

    readonly property int weightRegular: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightSemibold: Font.DemiBold
    readonly property int weightBold: Font.Bold

    function fontWithFallback(size, weight) {
        return Qt.font({
            family: family,
            pixelSize: size,
            weight: weight === undefined ? weightRegular : weight
        })
    }

    function mono(size) {
        return Qt.font({
            family: familyMono,
            pixelSize: size,
            weight: weightRegular
        })
    }
}
