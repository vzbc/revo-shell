import QtQuick

Rectangle {
    id: card

    default property alias rows: rowCol.data

    x: Theme.cardMargin
    width: parent ? parent.width - 2 * Theme.cardMargin : 400
    radius: Theme.cardRadius
    border.width: 1
    border.color: Theme.cardStroke
    color: Theme.cardBg

    implicitHeight: rowCol.implicitHeight

    Column {
        id: rowCol
        width: parent.width
    }
}
