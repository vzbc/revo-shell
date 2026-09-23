// ShimmerButton.qml - Button with shimmer sweep (Magic UI ShimmerButton → QML)
import QtQuick

Rectangle {
    id: root

    property alias text: label.text
    property color buttonColor: "#FFFFFF"
    property color buttonTextColor: "#000000"
    property color shimmerColor: "#FFFFFF"
    property int pixelSize: 15

    signal clicked()

    width: Math.max(180, label.implicitWidth + 64)
    height: 52
    radius: 12
    color: buttonColor
    clip: true

    // Outer glow shadow (fake)
    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: parent.radius + 6
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)
        z: -1
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: "Reboot now"
        font.family: "SF Pro Display"
        font.pixelSize: root.pixelSize
        font.weight: Font.Medium
        color: root.buttonTextColor
        z: 2
    }

    // Shimmer sweep
    Rectangle {
        id: shimmer
        width: parent.width * 0.45
        height: parent.height * 2
        x: -width
        y: -height / 2
        rotation: 18
        opacity: 0.55
        z: 1

        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.75) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        SequentialAnimation on x {
            running: root.visible
            loops: Animation.Infinite
            NumberAnimation {
                to: root.width + shimmer.width
                duration: 1800
                easing.type: Easing.InOutQuad
            }
            PauseAnimation { duration: 600 }
            ScriptAction {
                script: shimmer.x = -shimmer.width
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: root.scale = 0.97
        onReleased: root.scale = 1.0
        onCanceled: root.scale = 1.0
        onClicked: root.clicked()
    }

    Behavior on scale {
        NumberAnimation { duration: 120 }
    }
}
