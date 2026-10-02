import QtQuick
import QtQuick.Controls

Item {
    id: pick

    property string value: ""
    property var options: []
    property bool pill: false
    signal accepted(string value)

    implicitWidth: labelRow.implicitWidth + (pill ? 22 : 16)
    height: pill ? 24 : 20

    Rectangle {
        visible: pick.pill
        anchors.fill: parent
        radius: 7
        color: Theme.controlBg
        border.width: 1
        border.color: Theme.controlBorder
    }

    Row {
        id: labelRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: pick.value
            font.family: "SF Pro Text"
            font.pixelSize: 13
            color: Theme.btnText
            anchors.verticalCenter: parent.verticalCenter
        }

        Canvas {
            id: chevs
            width: 9
            height: 15
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = "#6E6E73"
                ctx.lineWidth = 1.4
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                // up chevron
                ctx.beginPath()
                ctx.moveTo(1.2, 6)
                ctx.lineTo(4.5, 2.6)
                ctx.lineTo(7.8, 6)
                ctx.stroke()
                // down chevron
                ctx.beginPath()
                ctx.moveTo(1.2, 9)
                ctx.lineTo(4.5, 12.4)
                ctx.lineTo(7.8, 9)
                ctx.stroke()
            }

            Component.onCompleted: requestPaint()
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: menu.open()
    }

    Popup {
        id: menu
        padding: 5
        y: pick.height + 4
        x: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        width: Math.max(120, menuCol.implicitWidth + 14)
        implicitHeight: menuCol.implicitHeight + padding * 2

        background: Rectangle {
            radius: 9
            color: Theme.menuBg
            border.width: 1
            border.color: Theme.menuBorder
        }

        contentItem: Column {
            id: menuCol
            spacing: 1

            Repeater {
                model: pick.options

                delegate: Rectangle {
                    id: opt
                    required property string modelData
                    property bool selected: modelData === pick.value

                    width: menuCol.width
                    height: 22
                    radius: 5
                    color: rowArea.containsMouse ? Theme.accent : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            visible: parent.parent.selected && !rowArea.containsMouse
                            text: "✓"
                            font.pixelSize: 12
                            color: Theme.btnText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: opt.modelData
                            font.family: "SF Pro Text"
                            font.pixelSize: 13
                            color: rowArea.containsMouse ? "white" : Theme.btnText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pick.accepted(opt.modelData)
                            menu.close()
                        }
                    }
                }
            }
        }
    }
}
