import QtQuick
import Quickshell

Item {
    id: root
    implicitWidth: 48
    implicitHeight: 40

    // Trigger button
    Rectangle {
        id: btn
        anchors.centerIn: parent
        width: 40
        height: 32
        radius: 8
        color: animPopup.visible ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }

        Text {
            anchors.centerIn: parent
            text: "✦"
            color: "white"
            font.pixelSize: 16
        }

        TapHandler {
            onTapped: {
                if (!animPopup.visible)
                    animPopup.open();
                else
                    animPopup.close();
            }
        }
    }

    // Todo popup
    PopupWindow {
        id: animPopup
        anchor.item: btn
        anchor.rect.x: btn.width / 2 - animPopup.implicitWidth / 2
        anchor.rect.y: btn.height + 6
        grabFocus: true
        visible: false
        color: "transparent"
        implicitWidth: 300
        implicitHeight: targetH

        readonly property real vPad: 14
        property real targetH: vPad * 2 + layout.implicitHeight
        property real visibleHeight: targetH

        onTargetHChanged: {
            if (targetH > implicitHeight)
                implicitHeight = targetH; // surface only grows, mask covers dead zone on shrink
            visibleHeight = targetH; // Behavior animates the rect both ways
        }

        Behavior on visibleHeight {
            NumberAnimation {
                duration: Anim.medium
                easing.type: Easing.OutCubic
            }
        }

        mask: Region {
            width: animPopup.implicitWidth
            height: animPopup.visibleHeight
        }

        function open() {
            if (!visible) {
                content.scale = 0;
                content.opacity = 0;
                visible = true;
                Qt.callLater(() => todoInput.forceActiveFocus());
            }
            hideAnim.stop();
            showAnim.start();
        }

        function close() {
            showAnim.stop();
            hideAnim.start();
        }

        onVisibleChanged: {
            if (!visible) {
                content.scale = 0;
                content.opacity = 0;
                implicitHeight = targetH; // reset surface to current content size
                visibleHeight = targetH;
            }
        }

        function addItem() {
            var t = todoInput.text.trim();
            if (t === "")
                return;
            todoModel.append({
                text: t
            });
            todoInput.text = "";
            todoInput.forceActiveFocus();
        }

        ListModel {
            id: todoModel
        }

        // Show animation
        ParallelAnimation {
            id: showAnim
            NumberAnimation {
                target: content
                property: "scale"
                to: 1
                duration: Anim.slow
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            NumberAnimation {
                target: content
                property: "opacity"
                to: 1
                duration: Anim.medium
                easing.type: Easing.OutCubic
            }
        }

        // Hide animation
        ParallelAnimation {
            id: hideAnim
            NumberAnimation {
                target: content
                property: "scale"
                to: 0
                duration: Anim.medium
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: content
                property: "opacity"
                to: 0
                duration: Anim.fast
                easing.type: Easing.InCubic
            }
            onStopped: animPopup.visible = false
        }

        // Content
        Item {
            id: content
            width: parent.width
            height: parent.height
            scale: 0
            opacity: 0
            transformOrigin: Item.Top

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: animPopup.visibleHeight
                radius: 16
                color: "#1e1e2e"
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                clip: true

                Column {
                    id: layout
                    width: parent.width - 24
                    anchors.top: parent.top
                    anchors.topMargin: animPopup.vPad
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    // Header
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "To-Do"
                        color: "white"
                        font.pixelSize: 15
                        font.weight: Font.Medium
                    }

                    // Input row
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        Rectangle {
                            width: 196
                            height: 34
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.07)

                            TextInput {
                                id: todoInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: "white"
                                font.pixelSize: 13
                                clip: true
                                Keys.onReturnPressed: animPopup.addItem()
                            }

                            // Placeholder
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                verticalAlignment: Text.AlignVCenter
                                text: "Add a task..."
                                color: Qt.rgba(1, 1, 1, 0.25)
                                font.pixelSize: 13
                                visible: todoInput.text.length === 0 && !todoInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 50
                            height: 34
                            radius: 8
                            color: addHover.hovered ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.1)
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.micro
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "Add"
                                color: "white"
                                font.pixelSize: 13
                            }

                            HoverHandler {
                                id: addHover
                            }
                            TapHandler {
                                onTapped: animPopup.addItem()
                            }
                        }
                    }

                    // Todo items
                    Repeater {
                        model: todoModel
                        delegate: Rectangle {
                            id: delegateItem
                            required property int index
                            required property string text

                            width: parent.width
                            height: 40
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.05)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: deleteBtn.left
                                anchors.rightMargin: 6
                                text: delegateItem.text
                                color: "white"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: deleteBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24
                                height: 24
                                radius: 12
                                color: delHover.hovered ? Qt.rgba(1, 0.3, 0.3, 0.35) : "transparent"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.micro
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "x"
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    font.pixelSize: 16
                                }

                                HoverHandler {
                                    id: delHover
                                }
                                TapHandler {
                                    onTapped: todoModel.remove(delegateItem.index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
