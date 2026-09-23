import QtQuick
import "../../"

Row {
    property string lbl: ""
    property string val: ""
    property string dim: ""

    spacing: Math.round(10 * UIScale.value)

    Text {
        width: Math.round(32 * UIScale.value)
        text: lbl
        color: Colors.accent
        font.pixelSize: UIScale.fontTiny
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.5
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: val
        color: Colors.text
        font.pixelSize: UIScale.fontSmall
        font.weight: Font.Medium
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        visible: dim.length > 0
        text: dim
        color: Colors.textDim
        font.pixelSize: UIScale.fontTiny
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(1 * UIScale.value)
    }
}
