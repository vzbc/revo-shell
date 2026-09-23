import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    required property QtObject theme
    required property QtObject calendarService

    implicitHeight: calendarLayout.implicitHeight

    ColumnLayout {
        id: calendarLayout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: root.theme.space2

        RowLayout {
            Layout.fillWidth: true
            spacing: root.theme.space2

            Text {
                Layout.fillWidth: true
                text: root.calendarService.monthTitle
                color: root.theme.ink
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textMd
                font.weight: Font.Bold

                TapHandler {
                    onTapped: root.calendarService.goToToday()
                }

            }

            Ui.IconButton {
                theme: root.theme
                controlSize: 28
                iconSource: Quickshell.shellDir + "/assets/icons/chevron-left.svg"
                accessibleName: "Previous month"
                fill: root.theme.pink
                onClicked: root.calendarService.previousMonth()
            }

            Ui.IconButton {
                theme: root.theme
                controlSize: 28
                iconSource: Quickshell.shellDir + "/assets/icons/chevron-right.svg"
                accessibleName: "Next month"
                fill: root.theme.green
                onClicked: root.calendarService.nextMonth()
            }

        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: root.theme.space1
            columnSpacing: root.theme.space1

            Repeater {
                model: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

                Text {
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: root.theme.inkMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

            }

            Repeater {
                model: root.calendarService.cells

                Item {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 30

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: root.theme.radiusPill
                        color: modelData.today ? root.theme.green : "transparent"
                        border.width: modelData.today ? root.theme.borderWidth : 0
                        border.color: root.theme.ink
                    }

                    Text {
                        anchors.centerIn: parent
                        text: String(modelData.day)
                        color: modelData.currentMonth ? root.theme.ink : root.theme.outlineSoft
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                        font.weight: modelData.today ? Font.Bold : Font.Normal
                    }

                }

            }

        }

    }

}
