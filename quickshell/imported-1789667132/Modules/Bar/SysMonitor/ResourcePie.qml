import QtQuick
import QtQuick.Shapes
import qs.Common
import qs.Components

Item {
    id: root

    property real value: 0
    property string icon: "monitoring"
    property color fillColor: Appearance.colors.colPrimary
    property color trackColor: Appearance.colors.colPrimaryContainer
    property color iconColor: Appearance.colors.colOnPrimaryContainer
    property real indicatorSize: 28
    property real iconSize: 15
    property bool showText: false
    property string displayText: ""
    property real labelSpacing: Appearance.spacing.xSmall
    property bool animationEnabled: true
    property int animationDuration: Appearance.animation.standardSmall.duration
    readonly property real normalizedValue: {
        const numeric = Number(root.value);
        if (!isFinite(numeric))
            return 0;

        return Math.max(0, Math.min(1, numeric));
    }
    property real degree: root.normalizedValue * 360
    readonly property real centerX: root.indicatorSize / 2
    readonly property real centerY: root.indicatorSize / 2
    readonly property real radius: root.indicatorSize / 2
    readonly property real displayTextWidth: displayTextMetrics.width

    implicitWidth: root.indicatorSize + (root.showText ? root.labelSpacing + root.displayTextWidth : 0)
    implicitHeight: root.showText ? Math.max(root.indicatorSize, displayTextMetrics.height) : root.indicatorSize

    Item {
        id: circleCanvas

        width: root.indicatorSize
        height: root.indicatorSize
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.trackColor
        }

        Shape {
            anchors.fill: parent
            visible: root.degree > 0.01
            preferredRendererType: Shape.CurveRenderer
            antialiasing: true

            ShapePath {
                id: sectorPath

                fillColor: root.fillColor
                strokeColor: root.fillColor
                strokeWidth: 0
                pathHints: ShapePath.PathSolid
                startX: root.centerX
                startY: root.centerY

                PathAngleArc {
                    moveToStart: false
                    centerX: root.centerX
                    centerY: root.centerY
                    radiusX: root.radius
                    radiusY: root.radius
                    startAngle: -90
                    sweepAngle: root.degree
                }

                PathLine {
                    x: sectorPath.startX
                    y: sectorPath.startY
                }

            }

        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.icon
            iconSize: root.iconSize
            color: root.iconColor
            fill: 1
        }

    }

    TextMetrics {
        id: displayTextMetrics

        text: root.displayText
        font.family: Fonts.numeric
        font.pixelSize: Typography.labelLarge.pixelSize
        font.weight: Typography.labelLarge.weight
    }

    Text {
        text: root.displayText
        visible: root.showText
        color: Appearance.colors.colOnSurface
        font.family: Fonts.numeric
        font.pixelSize: Typography.labelLarge.pixelSize
        font.weight: Typography.labelLarge.weight

        anchors {
            left: circleCanvas.right
            leftMargin: root.labelSpacing
            verticalCenter: parent.verticalCenter
        }

    }

    Behavior on degree {
        enabled: root.animationEnabled

        NumberAnimation {
            duration: root.animationDuration
            easing.type: Appearance.animation.standardSmall.type
            easing.bezierCurve: Appearance.animation.standardSmall.bezierCurve
        }

    }

}
