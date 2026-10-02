import QtQuick
import Qt.labs.settings
import ".."

Column {
    id: page

    property string pageId: "acc.hoverText"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    width: parent ? parent.width : 500
    spacing: 12

    Settings {
        id: ht
        category: "accessibility"
        property bool hoverText: false
        property bool hoverColor: false
        property bool hoverTyping: false
    }

    GroupCard {
        DetailRow {
            title: "Hover Text"
            subtitle: "View a large, high-resolution version of text you're reading, as well as other onscreen items like app icons."
            showSwitch: true
            switchOn: ht.hoverText
            showInfo: true
            onToggled: ht.hoverText = checked
            onInfoClicked: console.log("Hover Text info — TODO")
        }
        DetailRow {
            separator: true
            title: "Hover Color"
            subtitle: "View a large, high-resolution version of colors in text you're reading, as well as other onscreen items like app icons."
            showSwitch: true
            switchOn: ht.hoverColor
            showInfo: true
            onToggled: ht.hoverColor = checked
            onInfoClicked: console.log("Hover Color info — TODO")
        }
        DetailRow {
            separator: true
            title: "Hover Typing"
            subtitle: "Display a larger, editable version of text as you type it."
            showSwitch: true
            switchOn: ht.hoverTyping
            showInfo: true
            onToggled: ht.hoverTyping = checked
            onInfoClicked: console.log("Hover Typing info — TODO")
        }
    }
}
