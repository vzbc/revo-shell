import QtQuick

Item {
    id: header

    property string text: ""
    property string suffix: ""
    property string buttonLabel: ""
    signal buttonClicked

    width: parent ? parent.width : 400
    height: 28

    Text {
        x: Theme.cardMargin + 4
        anchors.verticalCenter: parent.verticalCenter
        text: header.text + header.suffix
        font.family: Theme.fontText
        font.pixelSize: 13
        font.weight: Font.Bold
        color: Theme.textPrimary
    }

    MacButton {
        visible: header.buttonLabel.length > 0
        anchors.right: parent.right
        anchors.rightMargin: Theme.cardMargin
        anchors.verticalCenter: parent.verticalCenter
        text: header.buttonLabel
        onClicked: header.buttonClicked()
    }
}
