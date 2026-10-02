import QtQuick

Item {
    id: header

    property string text: ""
    property string suffix: ""
    property string buttonLabel: ""
    signal buttonClicked

    width: parent ? parent.width : 400
    height: 20

    Text {
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        text: header.text + header.suffix
        font.family: Theme.fontText
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: Theme.textPrimary
    }

    MacButton {
        visible: header.buttonLabel.length > 0
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: header.buttonLabel
        onClicked: header.buttonClicked()
    }
}
