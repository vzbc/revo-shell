import QtQuick
import QtQuick.Controls

Item {
    id: pick

    property string value: ""
    property var options: []
    property bool pill: false
    property real maxWidth: 100000
    signal accepted(string value)

    implicitWidth: Math.min(maxWidth, valueLabel.implicitWidth + 14 + (pill ? 26 : 16))
    width: implicitWidth
    height: pill ? Theme.controlHeight : 20

    // capsule glass pop-up button (Tahoe)
    Rectangle {
        visible: pick.pill
        anchors.fill: parent
        radius: height / 2
        color: pickArea.pressed ? Theme.pressedBg : (pickArea.containsMouse ? Theme.glassControlHover : Theme.controlBg)
        border.width: 1
        border.color: Theme.controlBorder
    }
    Rectangle {
        visible: !pick.pill && pickArea.containsMouse
        anchors.fill: parent
        anchors.margins: -3
        radius: height / 2
        color: Theme.hoverBg
    }

    Row {
        id: labelRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            id: valueLabel
            text: pick.value
            width: Math.min(implicitWidth, pick.maxWidth - 14 - (pick.pill ? 26 : 16))
            elide: Text.ElideRight
            font.family: Theme.fontText
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
                ctx.strokeStyle = Theme.stroke
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
        id: pickArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: menu.open()
    }

    Popup {
        id: menu
        padding: 6
        readonly property int selIdx: Math.max(0, pick.options.indexOf(pick.value))
        y: pick.pill ? -padding - selIdx * 25 + (pick.height - 24) / 2 : pick.height + 4
        x: pick.pill ? -18 : 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        width: Math.max(pick.width + 20, menuCol.implicitWidth + 16)
        implicitHeight: menuCol.implicitHeight + padding * 2

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 110 }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 140; easing.type: Easing.OutCubic }
        }
        exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 90 } }

        background: Rectangle {
            radius: 13
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
                    height: 24
                    radius: 7
                    color: rowArea.containsMouse ? Theme.accent : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            width: 12
                            opacity: opt.selected ? 1 : 0
                            text: "\u2713"
                            font.pixelSize: 12
                            font.bold: true
                            color: rowArea.containsMouse ? "white" : Theme.btnText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: opt.modelData
                            font.family: Theme.fontText
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
