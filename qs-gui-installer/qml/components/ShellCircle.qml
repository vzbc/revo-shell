// ShellCircle.qml - Selectable circle icon (AnimatedBeam Circle style → QML)
import QtQuick

Item {
    id: root

    property string label: ""
    property string iconText: ""
    property color borderColor: "#333333"
    property color fill: "#0A0A0A"
    property color textColor: "#FFFFFF"
    property bool selected: false
    property int circleSize: 72

    signal clicked()

    width: circleSize
    height: circleSize + 28

    Rectangle {
        id: circle
        width: root.selected ? root.circleSize + 6 : root.circleSize
        height: width
        radius: width / 2
        anchors.horizontalCenter: parent.horizontalCenter
        color: root.selected ? "#FFFFFF" : root.fill
        border.width: 2
        border.color: root.selected ? "#FFFFFF" : root.borderColor

        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
        }
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }

        scale: 1.0

        Rectangle {
            visible: root.selected
            anchors.centerIn: parent
            width: circle.width + 14
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(1, 1, 1, 0.25)
            opacity: pulseAnim.running ? 1 : 0.4

            SequentialAnimation {
                id: pulseAnim
                running: root.selected
                loops: Animation.Infinite
                NumberAnimation {
                    target: parent
                    property: "scale"
                    from: 1
                    to: 1.35
                    duration: 900
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: parent
                    property: "opacity"
                    from: 0.7
                    to: 0
                    duration: 900
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.iconText
            font.family: "SF Pro Display"
            font.pixelSize: root.circleSize * 0.32
            color: root.selected ? "#000000" : root.textColor
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
                easing.overshoot: 1.6
            }
        }
    }

    Text {
        id: lbl
        width: parent.width
        anchors.top: circle.bottom
        anchors.topMargin: 8
        text: root.label
        font.family: "SF Pro Display"
        font.pixelSize: 11
        font.weight: root.selected ? Font.DemiBold : Font.Normal
        color: root.selected ? "#FFFFFF" : "#888888"
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        maximumLineCount: 2
        wrapMode: Text.WordWrap
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: if (!root.selected) circle.scale = 1.06
        onExited: circle.scale = 1.0
        onClicked: root.clicked()
    }
}
