import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style segmented selection array.
 */
Flow {
    id: root
    Layout.fillWidth: true
    spacing: 4
    property list<var> options: [
        {
            "displayName": "Option 1",
            "icon": "check",
            "value": 1
        },
        {
            "displayName": "Option 2",
            "icon": "close",
            "value": 2
        },
    ]
    property var currentValue: null

    signal selected(var newValue)

    Repeater {
        model: root.options
        delegate: Rectangle {
            id: button
            required property var modelData
            required property int index
            property bool toggled: root.currentValue == modelData.value
            property bool hovered: buttonArea.containsMouse

            implicitHeight: 32
            implicitWidth: contentRow.implicitWidth + 20
            radius: 4
            color: {
                if (button.toggled) return button.hovered ? "#4fc0ff" : WinTheme.accent
                return button.hovered ? WinTheme.cardHover : WinTheme.card
            }
            border.width: button.toggled ? 1 : 0
            border.color: WinTheme.accent
            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            RowLayout {
                id: contentRow
                anchors.centerIn: parent
                spacing: 5

                MaterialSymbol {
                    visible: button.modelData.icon && button.modelData.icon.length > 0
                    text: button.modelData.icon
                    iconSize: Appearance.font.pixelSize.small
                    color: button.toggled ? WinTheme.onAccentColor : WinTheme.text
                }
                StyledText {
                    text: button.modelData.displayName
                    color: button.toggled ? WinTheme.onAccentColor : WinTheme.text
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }

            MouseArea {
                id: buttonArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(button.modelData.value)
            }
        }
    }
}
