import QtQuick
import ".."

Column {
    id: page

    property string pageId: ""
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property string catKey: pageId.indexOf("gen.storage.") === 0 ? pageId.slice(12) : ""
    readonly property var rows: SysInfo.details(catKey)

    width: parent ? parent.width : 700
    spacing: 12

    Item { width: 1; height: 4 }

    GroupCard {
        visible: page.rows.length > 0

        Repeater {
            model: page.rows

            delegate: DetailRow {
                required property var modelData
                title: modelData.t
                value: SysInfo.fmt(modelData.v)
            }
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        visible: page.rows.length === 0
        wrapMode: Text.WordWrap
        text: SysInfo.scanning ? "Calculating…" : "No items found in this category."
        font { family: Theme.fontText; pixelSize: 13 }
        color: Theme.textSecondary
    }

    Text {
        x: 28
        width: parent.width - 56
        visible: page.rows.length > 0
        wrapMode: Text.WordWrap
        text: "Total: " + SysInfo.fmt(SysInfo.category(page.catKey))
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }

    Item { width: 1; height: 2 }
}
