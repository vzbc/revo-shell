// Stage2Repo.qml — optional Quickshell repo URL + skip + praise chat background
import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    signal next(string repoUrl)
    signal skipped()

    property string repoUrl: ""

    // Background chat — two people praising Revo Shell
    readonly property string otherAvatar: "../../resources/avatars/chat-other.jpg"
    readonly property string selfAvatar: "../../resources/avatars/chat-self.jpg"

    readonly property var praiseMessages: [
        { text: "Yo, have you tried Revo Shell yet?", alignEnd: false, muted: true, initials: "A", sender: "Alex", avatarImage: otherAvatar, delay: 800 },
        { text: "Not yet — is it another Quickshell setup?", alignEnd: true, footer: "Delivered", avatarImage: selfAvatar, delay: 900 },
        { text: "Way better. The dots are buttery smooth on Hyprland.", alignEnd: false, muted: true, initials: "A", sender: "Alex", avatarImage: otherAvatar, reactions: ["👍"], delay: 1100 },
        { text: "Fr? The animations look insane.", alignEnd: true, footer: "Delivered", avatarImage: selfAvatar, delay: 900 },
        { text: "One installer, zero config hell. Revo Shell just works.", alignEnd: false, muted: true, initials: "A", sender: "Alex", avatarImage: otherAvatar, reactions: ["🔥", "👀"], delay: 1200 },
        { text: "Say less — pulling it now.", alignEnd: true, footer: "Delivered", avatarImage: selfAvatar, delay: 900 }
    ]

    // Soft background chat (above black fill)
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        z: 0
    }

    ChatThread {
        id: bgChat
        z: 1
        anchors.right: parent.right
        anchors.rightMargin: 48
        anchors.verticalCenter: parent.verticalCenter
        width: 340
        height: Math.min(parent.height - 80, 460)
        messages: root.praiseMessages
        autoplay: true
        showTyping: true
        typingName: "Alex"
        typingAvatarImage: root.otherAvatar
        opacity: 0.92
    }

    // Foreground card
    Rectangle {
        id: card
        z: 2
        anchors.left: parent.left
        anchors.leftMargin: 64
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(parent.width - 460, 480)
        height: cardCol.implicitHeight + 64
        radius: 20
        color: "#0A0A0A"
        border.width: 1
        border.color: "#2C2C2E"

        Column {
            id: cardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 32
            spacing: 20

            Label {
                text: "Add your Quickshell repo"
                size: 28
                weight: Font.Bold
                tone: "#FFFFFF"
            }

            Label {
                width: parent.width
                text: "Paste a GitHub URL for your Quickshell dotfiles. This step is optional — you can skip and use the default shells."
                size: 15
                tone: "#A1A1A1"
                wrapMode: Text.WordWrap
                lineHeight: 1.4
            }

            UrlField {
                id: urlField
                width: parent.width
                placeholder: "https://github.com/you/quickshell-dotfiles"
                onAccepted: root.next(text)
            }

            Label {
                visible: urlField.text.length > 0
                text: urlField.text
                size: 12
                tone: "#6E6E73"
                elide: Text.ElideMiddle
                width: parent.width
            }

            Row {
                spacing: 12

                // Continue (primary)
                Rectangle {
                    id: continueBtn
                    height: 44
                    width: continueRow.implicitWidth + 44
                    radius: 10
                    color: continueMouse.containsMouse ? "#E5E5EA" : "#FFFFFF"

                    Behavior on color { ColorAnimation { duration: 160 } }

                    Row {
                        id: continueRow
                        anchors.centerIn: parent
                        spacing: 8

                        Label {
                            text: "Continue"
                            size: 15
                            weight: Font.Medium
                            tone: "#000000"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: "→"
                            size: 16
                            weight: Font.Medium
                            tone: "#000000"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: continueMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.next(urlField.text)
                    }
                }

                // Skip (ripple)
                RippleButton {
                    id: skipBtn
                    text: "Skip"
                    anchors.verticalCenter: continueBtn.verticalCenter
                    buttonColor: "#0A0A0A"
                    buttonTextColor: "#FFFFFF"
                    buttonBorderColor: "#2C2C2E"
                    rippleColor: "#ADD8E6"
                    onClicked: root.skipped()
                }
            }
        }
    }
}
