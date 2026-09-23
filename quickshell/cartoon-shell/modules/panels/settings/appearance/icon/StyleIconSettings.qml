import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.commons
import qs.components

RowLayout {
    id: root
    spacing: ScalerService.s(12)

    CustomText {
        name: "Style"
    }

    Item {
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.preferredHeight: ScalerService.s(40)
        Layout.preferredWidth: ScalerService.s(40)
        anchors.margins: ScalerService.s(2)
        radius: ScalerService.s(12)
        color: Settings.appearance.styleIcons === "image" ? Qt.alpha(theme.button.text, 0.6) : (mouseImage.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6))
        border.color: Settings.appearance.styleIcons === "image" ? Qt.alpha(theme.button.text, 0.6) : (mouseImage.containsPress ? Qt.alpha(theme.button.border_select, 0.6) : Qt.alpha(theme.button.border, 0.6))
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        IconImage {
            path: "workspace/pacman/active.png"
            size: "large"
            anchors.centerIn: parent
        }
        MouseArea {
            id: mouseImage
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                SoundService.playSound("pick");
                Settings.appearance.styleIcons = "image";
            }
            onEntered: {
                SoundService.playSound("hover");
            }
        }
    }
    Rectangle {
        Layout.preferredHeight: ScalerService.s(40)
        Layout.preferredWidth: ScalerService.s(40)
        anchors.margins: ScalerService.s(2)
        radius: ScalerService.s(12)
        color: Settings.appearance.styleIcons === "icon" ? Qt.alpha(theme.button.text, 0.6) : (mouseIcon.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6))
        border.color: Settings.appearance.styleIcons === "icon" ? Qt.alpha(theme.button.text, 0.6) : (mouseIcon.containsPress ? Qt.alpha(theme.button.border_select, 0.6) : Qt.alpha(theme.button.border, 0.6))
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        IconText {
            name: "󰮯"
            fontFamily: "Symbols Nerd Font"
            size: "large"
            anchors.centerIn: parent
        }
        MouseArea {
            id: mouseIcon
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                SoundService.playSound("pick");
                Settings.appearance.styleIcons = "icon";
            }
            onEntered: {
                SoundService.playSound("hover");
            }
        }
    }
}
