// MessageBubble.qml — single chat bubble (self / other)
import QtQuick

Item {
    id: root

    property string text: ""
    property bool alignEnd: false
    property bool muted: false
    property string sender: ""
    property string footer: ""
    property var reactions: []
    property int avatarSize: 36
    property string initials: ""
    property string avatarImage: ""
    property color avatarColor: "#2C2C2E"
    property string fontFamily: "SF Pro Display"

    readonly property color bubbleBg: alignEnd ? "#FFFFFF" : (muted ? "#1C1C1E" : "#2C2C2E")
    readonly property color bubbleFg: alignEnd ? "#000000" : "#FFFFFF"

    // Available width for this bubble inside the chat column
    readonly property int availWidth: Math.max(160, width - (avatarVisible ? avatarSize + 10 : 0))
    readonly property int maxTextWidth: Math.max(120, Math.min(240, availWidth - 32))
    readonly property bool hasAvatarImage: avatarImage.length > 0
    readonly property bool avatarVisible: hasAvatarImage || (!alignEnd && initials.length > 0)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Safety: never leave bubbles invisible if animation fails
    Component.onCompleted: {
        if (opacity < 0.05)
            opacity = 1
        if (width <= 0 && parent)
            width = parent.width
    }

    // Invisible sizer: fixed max width → no binding loop with bubble
    Text {
        id: sizer
        visible: false
        width: root.maxTextWidth
        text: root.text
        wrapMode: Text.WordWrap
        font.family: root.fontFamily
        font.pixelSize: 15
        lineHeight: 1.35
    }

    // Shared avatar visual (image falls back to initials)
    component ChatAvatar: Rectangle {
        visible: root.avatarVisible
        width: root.avatarSize
        height: root.avatarSize
        radius: width / 2
        color: root.avatarColor
        anchors.verticalCenter: parent.verticalCenter

        CircularImage {
            anchors.fill: parent
            anchors.margins: 1
            source: root.hasAvatarImage ? root.avatarImage : ""
            initials: root.initials
            fontFamily: root.fontFamily
            fallbackColor: "transparent"
            textColor: "#FFFFFF"
            fontPixelSize: Math.max(10, Math.round(root.avatarSize * 0.34))
        }
    }

    Row {
        id: row
        anchors.right: root.alignEnd ? parent.right : undefined
        anchors.left: root.alignEnd ? undefined : parent.left
        spacing: 10

        // Other person: avatar left of bubble
        ChatAvatar {
            visible: root.avatarVisible && !root.alignEnd
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            width: bubble.width

            Text {
                visible: root.sender.length > 0 && !root.alignEnd
                text: root.sender
                font.family: root.fontFamily
                font.pixelSize: 12
                color: "#6E6E73"
                leftPadding: 4
            }

            Rectangle {
                id: bubble
                width: Math.min(sizer.implicitWidth, root.maxTextWidth) + 32
                height: bubbleCol.height + 20
                radius: 18
                color: root.bubbleBg

                Column {
                    id: bubbleCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 10
                    spacing: 6

                    Text {
                        width: parent.width
                        text: root.text
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        color: root.bubbleFg
                        wrapMode: Text.WordWrap
                        lineHeight: 1.35
                    }

                    Flow {
                        visible: root.reactions && root.reactions.length > 0
                        spacing: 6
                        width: parent.width

                        Repeater {
                            model: root.reactions || []

                            Rectangle {
                                id: rxItem
                                required property var modelData
                                width: rxLabel.implicitWidth + 14
                                height: 24
                                radius: 12
                                color: root.alignEnd ? "#F2F2F7" : "#2C2C2E"

                                Text {
                                    id: rxLabel
                                    anchors.centerIn: parent
                                    text: rxItem.modelData
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.footer.length > 0
                text: root.footer
                font.family: root.fontFamily
                font.pixelSize: 11
                color: "#6E6E73"
                horizontalAlignment: root.alignEnd ? Text.AlignRight : Text.AlignLeft
                width: bubble.width
            }
        }

        // Self: avatar right of bubble
        ChatAvatar {
            visible: root.avatarVisible && root.alignEnd
        }
    }
}
