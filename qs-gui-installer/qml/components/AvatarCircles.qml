// AvatarCircles.qml - Overlapping avatars + "N+" badge (Magic UI AvatarCircles → QML)
import QtQuick

Item {
    id: root

    property var avatars: []
    property int numPeople: 0
    property int avatarSize: 40
    property int overlap: -16

    signal avatarClicked(int index)

    readonly property int itemCount: avatars.length + (numPeople > 0 ? 1 : 0)
    readonly property int rowWidth: itemCount * (avatarSize + overlap) - overlap

    implicitWidth: Math.max(rowWidth, avatarSize)
    implicitHeight: avatarSize

    Row {
        id: row
        spacing: root.overlap
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.avatars

            delegate: Rectangle {
                id: circle
                required property var modelData
                required property int index

                readonly property string imageSrc: (circle.modelData && circle.modelData.image !== undefined)
                        ? circle.modelData.image : ""
                readonly property string labelInitials: (circle.modelData && circle.modelData.initials !== undefined)
                        ? circle.modelData.initials : "?"

                width: root.avatarSize
                height: root.avatarSize
                radius: width / 2
                color: "#1A1A1A"
                border.width: 2
                border.color: "#000000"
                z: 100 - circle.index

                CircularImage {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: circle.imageSrc
                    initials: circle.labelInitials
                    fontFamily: "SF Pro Display"
                    fallbackColor: "transparent"
                    fontPixelSize: Math.max(10, Math.round(root.avatarSize * 0.32))
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.avatarClicked(circle.index)
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Rectangle {
            visible: root.numPeople > 0
            width: root.avatarSize
            height: root.avatarSize
            radius: width / 2
            color: "#000000"
            border.width: 2
            border.color: "#333333"
            z: 0

            Text {
                anchors.centerIn: parent
                text: "+" + root.numPeople
                font.family: "SF Pro Display"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: "#FFFFFF"
            }
        }
    }
}
