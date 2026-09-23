// components/Settings/ThemeCard.qml
import QtQuick
import qs.services
import qs.commons
import qs.components

Rectangle {
    id: themeCard

    property string type: "light"
    property bool isSelected: false
    property string label: ""
    property bool isEnabled: Settings.appearance.theme === "matugen"

    signal clicked

    width: ScalerService.s(100)
    height: ScalerService.s(80)
    radius: ScalerService.s(12)

    color: type === "light" ? "#f5eee6" : "#24273a"
    border.color: isSelected ? theme.button.text : theme.button.border
    border.width: isSelected ? ScalerService.s(3) : ScalerService.s(2)

    opacity: isEnabled ? 1.0 : 0.45

    Column {
        anchors.centerIn: parent
        spacing: ScalerService.s(6)

        Rectangle {
            width: ScalerService.s(60)
            height: ScalerService.s(24)
            radius: ScalerService.s(8)
            color: type === "light" ? "#2b2530" : "#cad3f5"
        }

        Rectangle {
            width: ScalerService.s(60)
            height: ScalerService.s(10)
            radius: ScalerService.s(3)
            color: type === "light" ? "#b0a89e" : "#494d64"
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: isEnabled
        cursorShape: isEnabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor

        onClicked: themeCard.clicked()
    }

    Text {
        text: label
        color: type === "light" ? "#2b2530" : "#cad3f5"
        opacity: isEnabled ? 1 : 0.6
        font {
            family: "ComicShannsMono Nerd Font"
            pixelSize: ScalerService.s(12)
            bold: true
        }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ScalerService.s(8)
    }

    Rectangle {
        visible: isSelected && isEnabled
        width: ScalerService.s(20)
        height: ScalerService.s(20)
        radius: ScalerService.s(10)
        color: theme.button.text
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: ScalerService.s(5)

        IconText {
            name: "check"
            size: "xs"
            anchors.centerIn: parent
            textColor: theme.button.background
        }
    }
}
