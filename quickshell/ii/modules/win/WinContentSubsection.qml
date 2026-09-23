import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style subsection inside a section card: an optional caption
 * label followed by rows separated by thin divider lines.
 */
Item {
    id: root
    property string title: ""
    property string tooltip: ""
    default property alias contentData: rowsColumn.data

    Layout.fillWidth: true
    Layout.topMargin: 4
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 4

        RowLayout {
            id: labelRow
            Layout.fillWidth: true
            spacing: 6
            visible: root.title && root.title.length > 0

            WinSubsectionLabel {
                text: root.title
            }
            MaterialSymbol {
                visible: root.tooltip && root.tooltip.length > 0
                text: "info"
                iconSize: Appearance.font.pixelSize.large
                color: WinTheme.textTertiary
                MouseArea {
                    id: infoMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.WhatsThisCursor
                    WinToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: infoMouseArea.containsMouse
                        text: root.tooltip
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        ColumnLayout {
            id: rowsColumn
            Layout.fillWidth: true
            spacing: 0

            property int dividerCount: rowsColumn.children.length
            onChildrenChanged: rowsColumn.dividerCount = rowsColumn.children.length
        }
    }

    // Divider lines between rows (overlay on the root Item, not in any layout).
    Repeater {
        model: rowsColumn.dividerCount
        delegate: Rectangle {
            required property int index
            property var row: rowsColumn.children[index]
            visible: index > 0 && row !== undefined
            height: 1
            color: WinTheme.border
            opacity: 0.75
            x: 12
            width: root.width - 24
            y: row ? row.y + rowsColumn.y + content.y : 0
        }
    }
}
