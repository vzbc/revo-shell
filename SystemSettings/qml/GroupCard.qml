import QtQuick

Rectangle {
    id: card

    default property alias rows: rowCol.data

    x: 12
    width: parent ? parent.width - 24 : 400
    radius: 10
    color: Theme.cardBg

    implicitHeight: rowCol.implicitHeight

    Column {
        id: rowCol
        width: parent.width
    }
}
