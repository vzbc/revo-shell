pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../../"
import "../shared"

Item {
    id: root

    anchors.fill: parent
    clip: true

    ColumnLayout {
        anchors {
            fill: parent
            margins: UIScale.spacingLg
        }
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: I18n.t("notifications.title")
                color: Colors.text
                font.bold: true
                font.pixelSize: UIScale.fontBody
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: I18n.t("notifications.mute")
                color: muteMouseArea.containsMouse ? Colors.accent : (NotifServer.muted ? Colors.accent : Colors.muted)
                font.pixelSize: UIScale.fontBody
                opacity: muteMouseArea.containsMouse || NotifServer.muted ? 1.0 : 0.5
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: Anim.fast
                    }
                }

                MouseArea {
                    id: muteMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: NotifServer.muted = !NotifServer.muted
                }
            }

            Text {
                visible: NotifServer.history.count > 0
                text: I18n.t("notifications.clearAll")
                color: clearMouseArea.containsMouse ? Colors.accent : Colors.muted
                font.pixelSize: UIScale.fontCaption
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }

                MouseArea {
                    id: clearMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: NotifServer.clearHistory()
                }
            }
        }

        Divider {
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            color: Colors.withAlpha(Colors.accent, 0.1)
        }

        // Empty state
        Item {
            visible: NotifServer.history.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: I18n.t("notifications.noNotifications")
                color: Colors.muted
                font.pixelSize: UIScale.fontSmall
            }
        }

        // History list
        ListView {
            id: listView
            visible: NotifServer.history.count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: NotifServer.history
            spacing: 6
            clip: true

            delegate: Rectangle {
                id: histItem
                required property string appName
                required property string summary
                required property string body
                required property string time
                required property int index
                required property string image
                required property string appIcon

                readonly property bool hasImage: histItem.image !== ""

                width: listView.width
                radius: UIScale.radiusMd
                color: Colors.surface
                implicitHeight: itemRow.implicitHeight + UIScale.spacingMd + 2
                clip: true

                transform: Translate {
                    id: histSwipeTrans
                    x: 0
                }

                DragHandler {
                    id: histSwipeDrag
                    target: null
                    xAxis.enabled: true
                    yAxis.enabled: false
                    acceptedButtons: Qt.LeftButton
                    onTranslationChanged: if (active)
                        histSwipeTrans.x = translation.x
                    onActiveChanged: {
                        if (!active) {
                            if (Math.abs(histSwipeTrans.x) > 100) {
                                histSwipeOut.targetX = histSwipeTrans.x > 0 ? 420 : -420;
                                histSwipeOut.start();
                            } else {
                                histSnapBack.start();
                            }
                        }
                    }
                }

                NumberAnimation {
                    id: histSnapBack
                    target: histSwipeTrans
                    property: "x"
                    to: 0
                    duration: Anim.medium
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }

                SequentialAnimation {
                    id: histSwipeOut
                    property real targetX: 420
                    ParallelAnimation {
                        NumberAnimation {
                            target: histSwipeTrans
                            property: "x"
                            to: histSwipeOut.targetX
                            duration: Anim.medium
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: histItem
                            property: "opacity"
                            to: 0
                            duration: Anim.medium
                            easing.type: Easing.InCubic
                        }
                    }
                    NumberAnimation {
                        target: histItem
                        property: "implicitHeight"
                        to: 0
                        duration: Anim.medium
                        easing.type: Easing.InCubic
                    }
                    onFinished: NotifServer.history.remove(histItem.index)
                }

                RowLayout {
                    id: itemRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: UIScale.spacingSm
                    }
                    spacing: UIScale.spacingSm

                    Item {
                        id: histAvatar
                        Layout.alignment: Qt.AlignTop
                        visible: histItem.hasImage
                        implicitWidth: 28
                        implicitHeight: 28

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Colors.surfaceHigh
                        }

                        Rectangle {
                            id: histAvatarMask
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }

                        Image {
                            anchors.fill: parent
                            source: histItem.image
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(histAvatar.width * 2, histAvatar.height * 2)
                            cache: false
                            asynchronous: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: histAvatarMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                            }
                        }

                        Image {
                            visible: histItem.appIcon !== ""
                            width: 12
                            height: 12
                            anchors {
                                right: parent.right
                                bottom: parent.bottom
                            }
                            source: histItem.appIcon !== "" ? Quickshell.iconPath(histItem.appIcon) : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        id: itemLayout
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: histItem.appName
                                color: Colors.muted
                                font.pixelSize: UIScale.fontCaption
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: histItem.time
                                color: Colors.muted
                                font.pixelSize: UIScale.fontCaption
                                opacity: 0.7
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: histItem.summary
                            color: Colors.text
                            font.bold: true
                            font.pixelSize: UIScale.fontSmall
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: histItem.body !== ""
                            text: histItem.body
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            textFormat: Text.MarkdownText
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
