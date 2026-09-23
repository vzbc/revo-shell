import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style keyboard key chip.
 */
Rectangle {
    id: root
    property string key

    property real horizontalPadding: 6
    property real verticalPadding: 1
    property real borderWidth: 1
    property real extraBottomBorderWidth: 2
    property color borderColor: "#4a4a4a"
    property real borderRadius: 4
    property real pixelSize: Appearance.font.pixelSize.smaller
    property color keyColor: "#3a3a3a"
    implicitWidth: keyFace.implicitWidth + borderWidth * 2
    implicitHeight: keyFace.implicitHeight + borderWidth * 2 + extraBottomBorderWidth
    radius: borderRadius
    color: borderColor

    Rectangle {
        id: keyFace
        anchors {
            fill: parent
            topMargin: borderWidth
            leftMargin: borderWidth
            rightMargin: borderWidth
            bottomMargin: extraBottomBorderWidth + borderWidth
        }
        implicitWidth: keyText.implicitWidth + horizontalPadding * 2
        implicitHeight: keyText.implicitHeight + verticalPadding * 2
        color: keyColor
        radius: borderRadius - borderWidth

        StyledText {
            id: keyText
            anchors.centerIn: parent
            font.family: Appearance.font.family.monospace
            font.pixelSize: root.pixelSize
            text: key
            color: WinTheme.text
        }
    }
}
