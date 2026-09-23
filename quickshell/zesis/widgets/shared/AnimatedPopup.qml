import QtQuick
import Quickshell
import "../../"
import "../bar"

PopupWindow {
    id: root

    required property Item anchorItem
    property Component content
    property bool hasBackground: true
    signal opened

    anchor.item: anchorItem
    anchor.rect.x: {
        if (BarConfig.side === "left")
            return anchorItem.width;
        if (BarConfig.side === "right")
            return -root.implicitWidth;
        return anchorItem.width / 2 - root.implicitWidth / 2;
    }
    anchor.rect.y: {
        if (BarConfig.side === "bottom")
            return -root.implicitHeight;
        if (BarConfig.isVertical)
            return anchorItem.height / 2 - root.implicitHeight / 2;
        return anchorItem.height;
    }
    grabFocus: true
    visible: false
    color: "transparent"

    function open() {
        if (!visible) {
            frame.scale = 0;
            frame.opacity = 0;
            visible = true;
        }
        showAnim.start();
        root.opened();
    }

    function close() {
        if (!visible)
            return;
        showAnim.stop();
        visible = false;
    }

    onVisibleChanged: {
        if (!visible) {
            frame.scale = 0;
            frame.opacity = 0;
        }
    }

    property string _barSide: BarConfig.side
    on_BarSideChanged: root.close()

    ParallelAnimation {
        id: showAnim
        NumberAnimation {
            target: frame
            property: "scale"
            to: 1
            duration: Anim.slow
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }
        NumberAnimation {
            target: frame
            property: "opacity"
            to: 1
            duration: Anim.medium
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: frame
        anchors.fill: parent
        scale: 0
        opacity: 0
        transformOrigin: {
            if (BarConfig.side === "bottom")
                return Item.Bottom;
            if (BarConfig.side === "left")
                return Item.Left;
            if (BarConfig.side === "right")
                return Item.Right;
            return Item.Top;
        }

        Rectangle {
            anchors.fill: parent
            radius: UIScale.radiusLg
            topLeftRadius: (BarConfig.side === "top" || BarConfig.side === "left") ? 0 : UIScale.radiusLg
            topRightRadius: (BarConfig.side === "top" || BarConfig.side === "right") ? 0 : UIScale.radiusLg
            bottomLeftRadius: (BarConfig.side === "bottom" || BarConfig.side === "left") ? 0 : UIScale.radiusLg
            bottomRightRadius: (BarConfig.side === "bottom" || BarConfig.side === "right") ? 0 : UIScale.radiusLg
            color: Colors.bg
            border.color: Colors.outline
            border.width: 1
            visible: root.hasBackground
        }

        Loader {
            anchors.fill: parent
            active: root.visible
            sourceComponent: root.content
        }
    }
}
