import QtQuick

Rectangle {
    id: header

    property string iconFile: ""
    property string title: ""
    property string subtitle: ""

    x: 12
    width: parent ? parent.width - 24 : 400
    radius: 10
    color: Theme.cardBg

    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 0

        Item {
            width: 1
            height: 23
        }

        Item {
            width: 1
            height: 5
        }

        Image {
            visible: header.iconFile.length > 0
            source: Theme.icon(header.iconFile, 64)
            width: 64
            height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            mipmap: true
        }

        Item {
            width: 1
            height: 5
        }

        Text {
            text: header.title
            font.family: Theme.fontDisplay
            font.pixelSize: 28
            font.weight: Font.Bold
            color: Theme.textDetail
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width: 1
            height: header.subtitle.length > 0 ? 4 : 0
        }

        Text {
            text: header.subtitle
            visible: header.subtitle.length > 0
            font.family: Theme.fontText
            font.pixelSize: 13
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: Math.min(460, parent.width - 40)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width: 1
            height: header.subtitle.length > 0 ? 20 : 23
        }
    }
}
