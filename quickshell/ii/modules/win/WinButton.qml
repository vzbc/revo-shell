import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style button. Accent by default, secondary optional.
 */
Rectangle {
    id: root

    property string text: ""
    property string iconText: ""
    property bool accent: true
    property bool enabled: true
    property bool busy: false
    signal clicked()

    implicitHeight: 32
    implicitWidth: Math.max(84, contentRow.implicitWidth + 24)

    color: {
        if (!root.enabled) return "#2a2a2a"
        if (mouse.containsMouse) {
            return root.accent ? WinTheme.accentHover : "#3a3a3a"
        }
        return root.accent ? WinTheme.accent : "#333333"
    }
    radius: 4

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            visible: root.iconText.length > 0 && !root.busy
            text: root.iconText
            iconSize: 16
            color: root.enabled ? (root.accent ? WinTheme.onAccentColor : WinTheme.text) : WinTheme.textTertiary
        }

        BusyIndicator {
            visible: root.busy
            width: 14
            height: 14
            running: true
        }

        StyledText {
            visible: root.text.length > 0
            text: root.text
            color: root.enabled ? (root.accent ? WinTheme.onAccentColor : WinTheme.text) : WinTheme.textTertiary
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled && !root.busy
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
