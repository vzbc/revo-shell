import QtQuick
import QtQuick.Layouts
import qs.config

// Title row for a popup. Extra children (buttons) go to the right of the title.
RowLayout {
    id: root

    property string text

    Layout.fillWidth: true
    spacing: 4

    BarText {
        Layout.fillWidth: true
        text: root.text
        font.bold: true
    }
}
