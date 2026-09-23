// Stage5Done.qml — thank-you marquee + 100% circle + shimmer reboot + closing chat
import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    signal reboot()
    signal restart()

    // Closing chat — "best dots on Linux"
    readonly property string otherAvatar: "../../resources/avatars/chat-other.jpg"
    readonly property string selfAvatar: "../../resources/avatars/chat-self.jpg"

    readonly property var closingMessages: [
        { text: "Bro… you have to see my new setup.", alignEnd: true, footer: "Delivered", avatarImage: selfAvatar, delay: 700 },
        { text: "Wait, what distro is that?", alignEnd: false, muted: true, initials: "J", sender: "Jordan", avatarImage: otherAvatar, delay: 900 },
        { text: "Arch + Hyprland. The dots are insane.", alignEnd: true, footer: "Delivered", avatarImage: selfAvatar, delay: 900 },
        { text: "Which dots?", alignEnd: false, muted: true, initials: "J", sender: "Jordan", avatarImage: otherAvatar, reactions: ["👀"], delay: 900 },
        { text: "Revo Shell. Legit the best dots on Linux right now.", alignEnd: true, footer: "Delivered", avatarImage: selfAvatar, reactions: ["🔥", "👍"], delay: 1200 },
        { text: "Facts. Sending me the repo.", alignEnd: false, muted: true, initials: "J", sender: "Jordan", avatarImage: otherAvatar, delay: 900 }
    ]

    Flickable {
        anchors.fill: parent
        contentHeight: body.implicitHeight + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: root.width
            spacing: 32
            topPadding: 12
            bottomPadding: 24

            // ScrollVelocity thank-you
            ScrollVelocityText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(root.width - 32, 900)
                height: 170
                text: "Thank You"
                pixelSize: 72
                color: "#FFFFFF"
                baseVelocity: 50
                running: root.visible
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 48

                // 100% circle
                CircularProgress {
                    anchors.verticalCenter: parent.verticalCenter
                    value: 100
                    gaugePrimaryColor: "#4F46E5"
                    labelColor: "#FFFFFF"
                    trackColor: Qt.rgba(1, 1, 1, 0.08)
                    size: 200
                    stroke: 14
                    centerText: "100%"
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14
                    width: 360

                    Label {
                        text: "Installation complete"
                        size: 32
                        weight: Font.Bold
                        tone: "#FFFFFF"
                    }

                    Label {
                        width: parent.width
                        text: "Your dotfiles and Hyprland config are in place. Reboot to enjoy the new shell."
                        size: 15
                        tone: "#A1A1A1"
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                    }

                    Row {
                        spacing: 12

                        ShimmerButton {
                            text: "Reboot System"
                            buttonColor: "#FFFFFF"
                            buttonTextColor: "#000000"
                            onClicked: root.reboot()
                        }

                        RippleButton {
                            text: "Start Over"
                            anchors.verticalCenter: parent.verticalCenter
                            buttonColor: "#0A0A0A"
                            buttonTextColor: "#FFFFFF"
                            buttonBorderColor: "#2C2C2E"
                            rippleColor: "#ADD8E6"
                            onClicked: root.restart()
                        }
                    }
                }
            }

            // Closing chat
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(root.width - 48, 420)
                height: Math.max(chat.implicitHeight, 200) + 40
                radius: 20
                color: "#050505"
                border.width: 1
                border.color: "#1C1C1E"

                ChatThread {
                    id: chat
                    anchors.fill: parent
                    anchors.margins: 20
                    messages: root.closingMessages
                    autoplay: true
                    showTyping: true
                    typingName: "Jordan"
                    typingAvatarImage: root.otherAvatar
                }
            }
        }
    }

    // One-shot progress animation to 100 when shown
    Item {
        id: hidden
        visible: false
    }

    onVisibleChanged: {
        if (visible) {
            // restart marquee + chat
        }
    }
}
