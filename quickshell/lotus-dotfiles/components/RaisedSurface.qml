import QtQuick

Item {
    id: root

    required property QtObject theme
    default property alias contentData: contentLayer.data
    property color fill: theme.surface
    property color outline: theme.ink
    property int surfaceRadius: theme.radiusCard
    property int padding: theme.space4

    implicitWidth: 240
    implicitHeight: 160

    Rectangle {
        x: root.theme.shadowOffset
        y: root.theme.shadowOffset
        width: root.width - root.theme.shadowOffset
        height: root.height - root.theme.shadowOffset
        radius: root.surfaceRadius
        color: root.theme.shadow
    }

    Rectangle {
        id: face

        width: root.width - root.theme.shadowOffset
        height: root.height - root.theme.shadowOffset
        radius: root.surfaceRadius
        color: root.fill
        border.width: root.theme.borderWidth
        border.color: root.outline
    }

    Item {
        id: contentLayer

        anchors.fill: face
        anchors.margins: root.padding
    }

}
