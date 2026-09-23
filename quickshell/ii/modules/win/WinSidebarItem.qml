import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 settings/store sidebar navigation item.
 * The selected item gets an accent-tinted background with an
 * accent-colored icon and white text (like the real Settings app).
 */
Rectangle {
    id: root

    property string iconText: ""
    property string label: ""
    property bool selected: false
    property bool showIcon: true
    signal clicked()

    implicitHeight: 36
    implicitWidth: parent?.width ?? 220

    color: selected ? WinTheme.accentSoft : (hoverArea.containsMouse ? "#2b2b2b" : "transparent")
    radius: 6

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 10

        MaterialSymbol {
            visible: root.showIcon
            Layout.preferredWidth: 22
            text: root.iconText
            iconSize: 19
            color: root.selected ? WinTheme.accent : Appearance.colors.colOnSurface
        }

        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.label
            color: root.selected ? WinTheme.text : Appearance.colors.colOnSurface
            font.pixelSize: 13
            font.weight: root.selected ? Font.DemiBold : Font.Normal
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
