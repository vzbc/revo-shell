import QtQuick
import Quickshell
import qs.config

// Small hint box shown above `target`. Ignores the mouse so it can't steal
// hover from the thing it describes.
PopupWindow {
    id: root

    required property Item target
    property string text

    anchor.item: target
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    visible: true
    color: "transparent"
    mask: Region {}

    implicitWidth: label.implicitWidth + 20
    // 4px transparent gap between the tip and the bar.
    implicitHeight: label.implicitHeight + 10 + 4

    Bevel {
        anchors.fill: parent
        anchors.bottomMargin: 4
        radius: height / 2
        faceColor: Theme.window
    }

    Item {
        anchors.fill: parent
        anchors.bottomMargin: 4

        BarText {
            id: label
            anchors.centerIn: parent
            text: root.text
            elide: Text.ElideNone
        }
    }
}
