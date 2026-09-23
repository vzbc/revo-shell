import QtQuick
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property QtObject trayService
    required property var trayItem
    required property var parentWindow
    property int controlSize: theme.compactControlSize
    readonly property bool needsAttention: trayService.needsAttention(trayItem)

    signal activated()

    function displayMenu() {
        if (!trayItem.hasMenu)
            return ;

        const point = mapToItem(null, width / 2, height);
        trayItem.display(parentWindow, Math.round(point.x), Math.round(point.y));
    }

    function primaryAction() {
        if (trayItem.onlyMenu)
            displayMenu();
        else
            trayItem.activate();
        activated();
    }

    implicitWidth: controlSize
    implicitHeight: controlSize
    activeFocusOnTab: true
    scale: pointer.pressed ? theme.pressScale : 1
    Accessible.role: Accessible.Button
    Accessible.name: trayService.title(trayItem) + (needsAttention ? ". Needs attention" : "")
    Keys.onEnterPressed: primaryAction()
    Keys.onReturnPressed: primaryAction()
    Keys.onSpacePressed: primaryAction()
    Keys.onMenuPressed: displayMenu()

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusControl
        color: root.needsAttention ? root.theme.coral : (pointer.containsMouse ? root.theme.alpha(root.theme.green, 0.52) : "transparent")
        border.width: root.activeFocus || root.needsAttention ? root.theme.borderWidth : 0
        border.color: root.activeFocus ? root.theme.focus : root.theme.ink

        Image {
            anchors.centerIn: parent
            width: root.theme.iconSm
            height: root.theme.iconSm
            source: root.trayItem.icon.length > 0 ? root.trayItem.icon : Quickshell.shellDir + "/assets/icons/application.svg"
            sourceSize.width: root.theme.iconSm
            sourceSize.height: root.theme.iconSm
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }

    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.primaryAction();
            } else if (mouse.button === Qt.RightButton) {
                root.displayMenu();
            } else if (mouse.button === Qt.MiddleButton) {
                root.trayItem.secondaryActivate();
                root.activated();
            }
        }
        onWheel: (wheel) => {
            root.trayItem.scroll(wheel.angleDelta.y, false);
            wheel.accepted = true;
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.theme.motionFast
            easing.type: root.theme.easingStandard
        }

    }

}
