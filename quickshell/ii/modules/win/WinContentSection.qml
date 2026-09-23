import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style settings section: a small caption label sits above a
 * rounded card that groups the rows, with thin divider lines between rows.
 */
ColumnLayout {
    id: root
    property string title
    property string icon: ""
    default property alias contentData: contentColumn.data

    Layout.fillWidth: true
    spacing: 6

    StyledText {
        visible: root.title && root.title.length > 0
        text: root.title
        color: WinTheme.textSecondary
        font.pixelSize: 13
        Layout.leftMargin: 2
    }

    WinCard {
        id: card
        Layout.fillWidth: true
        clip: true
        implicitHeight: contentColumn.implicitHeight

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            spacing: 0

            property int dividerCount: contentColumn.children.length
            onChildrenChanged: contentColumn.dividerCount = contentColumn.children.length
        }

        // Divider lines drawn between the card's rows (overlay, not part of the layout).
        Repeater {
            model: contentColumn.dividerCount
            delegate: Rectangle {
                required property int index
                property var row: contentColumn.children[index]
                visible: index > 0 && row !== undefined
                height: 1
                color: WinTheme.border
                opacity: 0.75
                x: 12
                width: card.width - 24
                y: row ? row.y : 0
            }
        }
    }
}
