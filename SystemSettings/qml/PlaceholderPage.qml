import QtQuick
import "Pages.js" as Pages

Column {
    id: page

    property string pageId: "wifi"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var meta: Pages.info[pageId] || {}

    width: parent ? parent.width : 700
    spacing: 12

    Placard {
        visible: meta.root === true
        iconFile: meta.root === true ? meta.icon : ""
        title: meta.root === true ? meta.title : ""
        subtitle: ""
    }

    Item {
        width: 1
        height: meta.root === true ? 2 : 0
    }
}
