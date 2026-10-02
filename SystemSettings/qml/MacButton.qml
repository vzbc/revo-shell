import QtQuick

Rectangle {
    id: btn

    property string text: ""
    property bool primary: false
    property bool btnEnabled: true
    signal clicked

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 22
    radius: 6

    color: !btnEnabled ? Theme.btnBgDisabled : primary ? (btnArea.containsMouse ? Theme.accentPressed : Theme.accent) : (btnArea.containsMouse ? Theme.btnBgHover : Theme.btnBg)

    border.width: !primary && btnEnabled ? 1 : 0
    border.color: Theme.btnBorder

    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        font.family: Theme.fontText
        font.pixelSize: 13
        font.weight: btn.primary ? 600 : 400
        color: !btn.btnEnabled ? Theme.btnTextDisabled : btn.primary ? "white" : Theme.btnText
    }

    MouseArea {
        id: btnArea
        anchors.fill: parent
        enabled: btn.btnEnabled
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: btn.clicked()
    }
}
