import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Rectangle {
    id: optionContainer
    property string optionId: ""
    property string label: ""
    property bool isHorizontal: true
    property string position: ""
    property bool isSelected: false

    radius: ScalerService.s(10)
    color: isSelected ? Qt.alpha(theme.button.text, 0.6) : (mouseArea.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6))

    border.color: isSelected ? Qt.alpha(theme.button.text, 0.6) : (mouseArea.containsPress ? Qt.alpha(theme.button.border_select, 0.6) : Qt.alpha(theme.button.border, 0.6))
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

    // Layout chính
    RowLayout {
        anchors.centerIn: parent
        spacing: ScalerService.s(10)

        // Thanh bar indicator
        Rectangle {
            id: barIndicator
            Layout.preferredWidth: isHorizontal ? ScalerService.s(60) : ScalerService.s(10)
            Layout.preferredHeight: isHorizontal ? ScalerService.s(10) : ScalerService.s(40)
            radius: ScalerService.s(3)
            color: isSelected ? theme.button.text : theme.primary.dim_foreground

            // Layout order cho left/right
            Layout.alignment: {
                if (position === "left")
                    return Qt.AlignVCenter | Qt.AlignRight;
                if (position === "right")
                    return Qt.AlignVCenter | Qt.AlignLeft;
                return Qt.AlignHCenter;
            }
        }

        // Label
        Text {
            text: label
            color: isSelected ? theme.button.text : theme.primary.foreground
            font {
                family: "ComicShannsMono Nerd Font"
                pixelSize: ScalerService.s(14)
            }

            Layout.alignment: {
                if (position === "left")
                    return Qt.AlignVCenter | Qt.AlignLeft;
                if (position === "right")
                    return Qt.AlignVCenter | Qt.AlignRight;
                return Qt.AlignHCenter;
            }
        }
    }

    // Interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: {
            optionContainer.clicked();
        }
        onEntered: parent.opacity = 0.9
        onExited: parent.opacity = 1.0
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 100
        }
    }

    signal clicked
}
