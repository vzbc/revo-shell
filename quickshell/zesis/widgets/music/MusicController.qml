pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import "../../"

Item {
    id: root
    anchors.fill: parent

    property bool popupVisible: false

    SwipeView {
        id: swiper
        anchors.fill: parent
        orientation: Qt.Vertical
        clip: true

        Repeater {
            model: ScriptModel {
                values: [...Mpris.players.values]
            }

            MprisItem {
                required property MprisPlayer modelData
                player: modelData
                popupVisible: root.popupVisible
                discScale: 0.7
                width: swiper.width
                height: swiper.height
            }
        }
    }

    // Vertical page dots on the right edge, only shown with multiple players
    PageIndicator {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: count > 1
        count: swiper.count
        currentIndex: swiper.currentIndex
        interactive: false
        rotation: 90

        delegate: Rectangle {
            required property int index
            width: 6
            height: 6
            radius: 3
            color: index === swiper.currentIndex ? "white" : Qt.rgba(1, 1, 1, 0.35)
            Behavior on color {
                ColorAnimation {
                    duration: Anim.slow
                }
            }
        }
    }
}
