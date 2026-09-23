import QtQuick
import "../../"

Item {
    id: root

    property real size: Math.round(40 * UIScale.value)

    width: size
    height: size

    // Monogram fallback shown when no avatar is set or image fails to load
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Colors.withAlpha(Colors.accent, 0.18)
        visible: UserService.avatarPath === "" || avatar.status !== Image.Ready

        Text {
            anchors.centerIn: parent
            text: UserService.name !== "" ? UserService.name.charAt(0).toUpperCase() : "?"
            color: Colors.accent
            font.pixelSize: Math.round(root.size * 0.4)
            font.weight: Font.Bold
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        clip: true
        color: "transparent"
        visible: UserService.avatarPath !== "" && avatar.status === Image.Ready

        Image {
            id: avatar
            anchors.fill: parent
            source: UserService.avatarPath !== "" ? "file://" + UserService.avatarPath : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
            asynchronous: true
        }
    }
}
