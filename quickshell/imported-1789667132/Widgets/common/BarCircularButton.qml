import QtQuick
import qs.Common
import qs.Components

Item {
    id: root

    property string iconName: ""
    property string tooltipText: ""
    // Selection is application state only. Bar controls retain the same visual
    // surface in every state; the opened surface already communicates selection.
    property bool selected: false
    property real baseSize: Sizes.barControlCircleSize
    property real hoverSize: 34
    property real iconSize: root.pointerHovered ? 20 : 18
    property real iconFill: 0
    property color containerColor: Appearance.colors.colPrimaryContainer
    property color rippleColor: Appearance.colors.colOnPrimaryContainer
    property color iconColor: Appearance.colors.colOnPrimaryContainer
    property var downAction
    property var doubleClickAction
    property var altAction
    property var middleClickAction
    readonly property bool pointerHovered: button.pointerHovered
    readonly property bool pressed: button.down

    signal clicked(var event)
    signal doubleClicked(var event)
    signal altClicked(var event)
    signal middleClicked(var event)

    implicitWidth: root.baseSize
    implicitHeight: root.baseSize
    Accessible.name: root.tooltipText
    Accessible.role: Accessible.Button

    RippleButton {
        id: button

        anchors.centerIn: parent
        width: root.pointerHovered ? root.hoverSize : root.baseSize
        height: width
        enabled: root.enabled
        buttonRadius: width / 2
        containerColor: root.containerColor
        rippleColor: root.rippleColor
        stateLayerEnabled: false
        downAction: (event) => {
            if (root.downAction)
                root.downAction(event);

        }
        releaseAction: () => {
            return root.clicked(null);
        }
        doubleClickAction: (event) => {
            if (root.doubleClickAction)
                root.doubleClickAction(event);

            root.doubleClicked(event);
        }
        altAction: (event) => {
            if (root.altAction)
                root.altAction(event);

            root.altClicked(event);
        }
        middleClickAction: (event) => {
            if (root.middleClickAction)
                root.middleClickAction(event);

            root.middleClicked(event);
        }

        Behavior on width {
            NumberAnimation {
                duration: Appearance.animation.expressiveFastEffects.duration
                easing.type: Appearance.animation.expressiveFastEffects.type
                easing.bezierCurve: Appearance.animation.expressiveFastEffects.bezierCurve
            }

        }

        contentItem: MaterialSymbol {
            text: root.iconName
            iconSize: root.iconSize
            fill: root.iconFill
            color: root.iconColor

            Behavior on iconSize {
                NumberAnimation {
                    duration: Appearance.animation.expressiveFastEffects.duration
                    easing.type: Appearance.animation.expressiveFastEffects.type
                    easing.bezierCurve: Appearance.animation.expressiveFastEffects.bezierCurve
                }

            }

        }

    }

    StyledToolTip {
        text: root.tooltipText
        extraVisibleCondition: root.tooltipText.length > 0 && root.pointerHovered
    }

}
