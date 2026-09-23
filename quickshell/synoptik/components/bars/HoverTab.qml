import QtQuick
import QtQuick.Shapes
import ".."

Item {
    id: hoverTab

    property var rootRef
    property real targetX: 0
    property real targetY: 0
    property bool active: false

    readonly property real tabSpan: 44
    readonly property real tabDepth: 12
    readonly property real cornerRadius: 4
    readonly property real wingSpan: 6

    readonly property bool isHorizontal: rootRef ? rootRef.isHorizontal : true
    readonly property bool isBottom: rootRef ? rootRef.isBottom : false
    readonly property bool isRight: rootRef ? rootRef.isRight : false

    readonly property real borderWidth: (Config.borderThickness !== undefined && Config.borderThickness !== null) ? Number(Config.borderThickness) : 0.0

    // Overlap by borderWidth so the tab overlaps the bar stroke seamlessly
    x: isHorizontal 
        ? (targetX - (tabSpan / 2.0)) 
        : (isRight ? (parent.width - rootRef.barH - (active ? tabDepth : 0)) : (rootRef.barH - borderWidth))
    y: isHorizontal 
        ? (isBottom ? (parent.height - rootRef.barH - (active ? tabDepth : 0)) : (rootRef.barH - borderWidth)) 
        : (targetY - (tabSpan / 2.0))

    width: isHorizontal ? tabSpan : (tabDepth + borderWidth)
    height: isHorizontal ? (tabDepth + borderWidth) : tabSpan

    visible: opacity > 0.001
    opacity: active ? 1.0 : 0.0

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on targetX { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on targetY { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Mask patch to knock out the bar border directly behind the tab
    Rectangle {
        id: borderKnockoutMask
        color: Config.bgPanel
        
        x: isHorizontal ? borderWidth : 0
        y: isHorizontal ? 0 : borderWidth
        width: isHorizontal ? (parent.width - (borderWidth * 2)) : (borderWidth * 2)
        height: isHorizontal ? (borderWidth * 2) : (parent.height - (borderWidth * 2))
        z: 0
    }

    Shape {
        anchors.fill: parent
        z: 1

        ShapePath {
            fillColor: Config.bgPanel
            strokeWidth: hoverTab.borderWidth
            strokeColor: typeof shellRoot !== "undefined" ? shellRoot.currentBorderColor : "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            // Traces only the protruding outer perimeter (leaves seam unstroked)
            startX: 0
            startY: 0

            PathLine { x: 0; y: hoverTab.height - hoverTab.cornerRadius }
            PathArc {
                x: hoverTab.cornerRadius
                y: hoverTab.height
                radiusX: hoverTab.cornerRadius
                radiusY: hoverTab.cornerRadius
                direction: PathArc.Counterclockwise
            }
            PathLine { x: hoverTab.width - hoverTab.cornerRadius; y: hoverTab.height }
            PathArc {
                x: hoverTab.width
                y: hoverTab.height - hoverTab.cornerRadius
                radiusX: hoverTab.cornerRadius
                radiusY: hoverTab.cornerRadius
                direction: PathArc.Counterclockwise
            }
            PathLine { x: hoverTab.width; y: 0 }
        }
    }
}