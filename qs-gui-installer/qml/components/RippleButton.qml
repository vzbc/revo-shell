// RippleButton.qml - Button with expanding ripple on click (Magic UI RippleButton → QML)
import QtQuick

Rectangle {
    id: root

    property alias text: labelText.text
    property color rippleColor: "#ADD8E6"
    property color buttonColor: "#FFFFFF"
    property color buttonTextColor: "#000000"
    property color buttonBorderColor: "#2C2C2E"
    property int pixelSize: 14

    signal clicked()

    width: Math.max(140, labelText.implicitWidth + 48)
    height: 44
    radius: 10
    color: buttonColor
    border.width: 1
    border.color: buttonBorderColor
    clip: true
    opacity: enabled ? 1 : 0.4

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: "Continue"
        font.family: "SF Pro Display"
        font.pixelSize: root.pixelSize
        font.weight: Font.Medium
        color: root.buttonTextColor
    }

    // Single reusable ripple from click point
    Rectangle {
        id: ripple
        property real cx: width / 2
        property real cy: height / 2
        x: cx - width / 2
        y: cy - height / 2
        width: root.height * 3
        height: width
        radius: width / 2
        color: root.rippleColor
        opacity: 0

        transform: Scale {
            id: rippleScale
            origin.x: ripple.width / 2
            origin.y: ripple.height / 2
            xScale: 0
            yScale: 0
        }

        function spawn(mx, my) {
            ripple.cx = mx
            ripple.cy = my
            rippleAnim.restart()
        }

        ParallelAnimation {
            id: rippleAnim
            NumberAnimation {
                target: rippleScale
                property: "xScale"
                from: 0
                to: 1
                duration: 600
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: rippleScale
                property: "yScale"
                from: 0
                to: 1
                duration: 600
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: ripple
                property: "opacity"
                from: 0.55
                to: 0
                duration: 600
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: root.scale = 0.97
        onReleased: root.scale = 1.0
        onCanceled: root.scale = 1.0
        onClicked: (mouse) => {
            ripple.spawn(mouse.x, mouse.y)
            root.clicked()
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutCubic
        }
    }
}
