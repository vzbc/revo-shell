import QtQuick

// macOS 27 push button: capsule, glass fill, accent fill when primary.
Rectangle {
    id: btn

    property string text: ""
    property bool primary: false
    property bool destructive: false
    property bool btnEnabled: true
    signal clicked

    implicitWidth: Math.max(label.implicitWidth + 28, 64)
    implicitHeight: Theme.controlHeight
    radius: height / 2
    scale: btnArea.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    color: !btnEnabled ? Theme.btnBgDisabled
         : primary ? (btnArea.pressed ? Theme.accentPressed : Theme.accent)
         : (btnArea.pressed ? Theme.pressedBg : (btnArea.containsMouse ? Theme.btnBgHover : Theme.btnBg))

    border.width: primary ? 0 : 1
    border.color: Theme.btnBorder

    // top specular line
    Rectangle {
        visible: btn.btnEnabled
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: btn.radius * 0.6
        anchors.rightMargin: btn.radius * 0.6
        anchors.topMargin: 1
        height: 1
        color: btn.primary ? Qt.rgba(1, 1, 1, 0.28) : (Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.9))
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        font.family: Theme.fontText
        font.pixelSize: 13
        font.weight: btn.primary ? Font.DemiBold : Font.Normal
        color: !btn.btnEnabled ? Theme.btnTextDisabled
             : btn.primary ? "white"
             : btn.destructive ? Theme.red : Theme.btnText
    }

    MouseArea {
        id: btnArea
        anchors.fill: parent
        enabled: btn.btnEnabled
        hoverEnabled: true
        onClicked: btn.clicked()
    }
}
