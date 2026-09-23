import QtQuick
import "."

Item {
    id: wmRoot

    property string icon: "settings"
    property real iconSize: 160
    property real baseOpacity: 0.12
    property real baseRotation: 15
    property color color: Config.accent
    property bool activeVisible: true

    // Seed to de-synchronize multiple watermarks across different cards
    property int seed: 0

    // Static placement offsets (when bouncing is disabled)
    property real staticRightMargin: -20
    property real staticBottomMargin: -20

    // Bounding edge padding (allows subtle overhang while keeping glyph mainly in view)
    property real bouncePadding: 24

    // Base durations in ms (slow ambient drifting)
    property int baseDurationX: 18000
    property int baseDurationY: 25000
    property int baseDurationR: 14000

    readonly property int effectiveDurationX: Math.max(6000, baseDurationX + ((seed * 3141) % 7000))
    readonly property int effectiveDurationY: Math.max(8000, baseDurationY + ((seed * 4723) % 9000))
    readonly property int effectiveDurationR: Math.max(5000, baseDurationR + ((seed * 2113) % 5000))

    visible: Config.showWatermarks && activeVisible
    implicitWidth: iconSize
    implicitHeight: iconSize
    width: iconSize
    height: iconSize
    z: 0

    // Randomized initial spawn coordinates (0.0 to 1.0) and initial drift directions
    readonly property real startX: Math.random()
    readonly property real startY: Math.random()
    readonly property real startR: Math.random()
    readonly property bool startDirX: Math.random() > 0.5
    readonly property bool startDirY: Math.random() > 0.5
    readonly property bool startDirR: Math.random() > 0.5

    // Normalized progress floats (0.0 to 1.0) initialized to randomized start position
    property real progressX: startX
    property real progressY: startY
    property real progressR: startR

    // Bounds relative to parent card
    readonly property real minX: -bouncePadding
    readonly property real maxX: (parent && parent.width > 0) ? Math.max(minX, parent.width - width + bouncePadding) : minX
    readonly property real minY: -bouncePadding
    readonly property real maxY: (parent && parent.height > 0) ? Math.max(minY, parent.height - height + bouncePadding) : minY

    readonly property bool isBouncing: (Config.bounceWatermarks !== undefined ? Config.bounceWatermarks : true) && visible

    // Direct dynamic mapping from progress to card coordinates
    x: isBouncing ? (minX + ((maxX - minX) * progressX)) : (parent ? (parent.width - width - staticRightMargin) : 0)
    y: isBouncing ? (minY + ((maxY - minY) * progressY)) : (parent ? (parent.height - height - staticBottomMargin) : 0)

    // Smooth continuous normalized loop animations with proportional initial launch legs
    SequentialAnimation {
        running: wmRoot.isBouncing
        loops: Animation.Infinite

        // Leg 1: Smooth launch from randomized startX towards initial boundary
        NumberAnimation {
            target: wmRoot
            property: "progressX"
            from: wmRoot.startX
            to: wmRoot.startDirX ? 1.0 : 0.0
            duration: Math.max(200, Math.round((wmRoot.startDirX ? (1.0 - wmRoot.startX) : wmRoot.startX) * wmRoot.effectiveDurationX))
            easing.type: Easing.InOutSine
        }

        // Main continuous ping-pong cycle
        NumberAnimation {
            target: wmRoot
            property: "progressX"
            from: wmRoot.startDirX ? 1.0 : 0.0
            to: wmRoot.startDirX ? 0.0 : 1.0
            duration: wmRoot.effectiveDurationX
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: wmRoot
            property: "progressX"
            from: wmRoot.startDirX ? 0.0 : 1.0
            to: wmRoot.startDirX ? 1.0 : 0.0
            duration: wmRoot.effectiveDurationX
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: wmRoot.isBouncing
        loops: Animation.Infinite

        // Leg 1: Smooth launch from randomized startY towards initial boundary
        NumberAnimation {
            target: wmRoot
            property: "progressY"
            from: wmRoot.startY
            to: wmRoot.startDirY ? 1.0 : 0.0
            duration: Math.max(200, Math.round((wmRoot.startDirY ? (1.0 - wmRoot.startY) : wmRoot.startY) * wmRoot.effectiveDurationY))
            easing.type: Easing.InOutSine
        }

        // Main continuous ping-pong cycle
        NumberAnimation {
            target: wmRoot
            property: "progressY"
            from: wmRoot.startDirY ? 1.0 : 0.0
            to: wmRoot.startDirY ? 0.0 : 1.0
            duration: wmRoot.effectiveDurationY
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: wmRoot
            property: "progressY"
            from: wmRoot.startDirY ? 0.0 : 1.0
            to: wmRoot.startDirY ? 1.0 : 0.0
            duration: wmRoot.effectiveDurationY
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: wmRoot.isBouncing
        loops: Animation.Infinite

        // Leg 1: Smooth launch from randomized startR towards initial tilt angle
        NumberAnimation {
            target: wmRoot
            property: "progressR"
            from: wmRoot.startR
            to: wmRoot.startDirR ? 1.0 : 0.0
            duration: Math.max(200, Math.round((wmRoot.startDirR ? (1.0 - wmRoot.startR) : wmRoot.startR) * wmRoot.effectiveDurationR))
            easing.type: Easing.InOutSine
        }

        // Main continuous ping-pong cycle
        NumberAnimation {
            target: wmRoot
            property: "progressR"
            from: wmRoot.startDirR ? 1.0 : 0.0
            to: wmRoot.startDirR ? 0.0 : 1.0
            duration: wmRoot.effectiveDurationR
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: wmRoot
            property: "progressR"
            from: wmRoot.startDirR ? 0.0 : 1.0
            to: wmRoot.startDirR ? 1.0 : 0.0
            duration: wmRoot.effectiveDurationR
            easing.type: Easing.InOutSine
        }
    }

    Text {
        anchors.centerIn: parent
        text: wmRoot.icon
        font.family: "Material Symbols Outlined"
        font.pixelSize: wmRoot.iconSize
        color: wmRoot.color
        opacity: wmRoot.baseOpacity
        rotation: wmRoot.isBouncing ? (wmRoot.baseRotation - 14 + (wmRoot.progressR * 28)) : wmRoot.baseRotation
    }
}
