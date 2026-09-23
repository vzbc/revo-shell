pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style settings slider row.
 */
RowLayout {
    id: root
    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    property string text: ""
    property string buttonIcon: ""
    property alias value: slider.value
    property alias stopIndicatorValues: slider.stopIndicatorValues
    property bool usePercentTooltip: true
    property alias from: slider.from
    property alias to: slider.to
    property real textWidth: 120

    RowLayout {
        spacing: 10
        Layout.alignment: Qt.AlignVCenter

        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.preferredWidth: root.textWidth
            text: root.text
            color: WinTheme.text
            wrapMode: Text.WordWrap
        }
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        implicitHeight: 24
        leftPadding: 0
        rightPadding: 0
        from: 0
        to: 1
        property list<real> stopIndicatorValues: [1]
        property bool usePercentTooltip: true
        value: 0

        background: Rectangle {
            implicitHeight: 4
            anchors.verticalCenter: parent.verticalCenter
            radius: 2
            color: WinTheme.border

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: WinTheme.accent
            }

            Repeater {
                model: slider.stopIndicatorValues
                Rectangle {
                    required property real modelData
                    width: 3
                    height: 7
                    radius: 1.5
                    color: WinTheme.textTertiary
                    x: (modelData - slider.from) / (slider.to - slider.from) * parent.width - 1.5
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        handle: Rectangle {
            id: handle
            width: 16
            height: 16
            radius: 8
            color: {
                if (slider.pressed) return WinTheme.cardPressed
                if (slider.hovered) return WinTheme.cardHover
                return WinTheme.text
            }
            border.width: slider.pressed ? 2 : 1
            border.color: slider.pressed ? WinTheme.accent : "transparent"
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            WinToolTip {
                extraVisibleCondition: slider.pressed
                text: slider.usePercentTooltip
                    ? `${Math.round(((slider.value - slider.from) / (slider.to - slider.from)) * 100)}%`
                    : `${Math.round(slider.value)}`
            }
        }
    }
}
