import QtQuick
import Qt.labs.settings
import ".."

Column {
    id: page

    property string pageId: "acc.motion"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    width: parent ? parent.width : 500
    spacing: 12

    Settings {
        id: mo
        category: "accessibility"
        property bool reduceMotion: false
        property bool dimFlashing: false
        property bool vehicleCues: false
    }

    GroupCard {
        DetailRow {
            title: "Reduce motion"
            subtitle: "Reduce the motion of the user interface."
            showSwitch: true
            switchOn: mo.reduceMotion
            onToggled: mo.reduceMotion = checked
        }
        DetailRow {
            separator: true
            title: "Dim flashing lights"
            subtitle: "Automatically dim the display of content that depicts flashing or strobing lights."
            showSwitch: true
            switchOn: mo.dimFlashing
            onToggled: mo.dimFlashing = checked
        }
        DetailRow {
            separator: true
            title: "Vehicle Motion Cues"
            subtitle: "Animated dots appear on the screen when you're in a moving vehicle, which may help reduce motion sickness."
            showSwitch: true
            switchOn: mo.vehicleCues
            onToggled: mo.vehicleCues = checked
            showInfo: true
            onInfoClicked: console.log("Vehicle Motion Cues info — TODO")
        }
    }

    Text {
        x: 16
        width: parent.width - 32
        wrapMode: Text.WordWrap
        text: "Dim flashing lights is available only for compatible media and on Mac computers with Apple silicon. Content is processed on device in real time."
        font { family: Theme.fontText; pixelSize: 11 }
        color: Theme.textSecondary
    }
}
