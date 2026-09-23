import QtQuick
import QtQuick.Layouts
import "../../"

// Grouped container for related settings controls
Rectangle {
    id: root

    default property alias content: inner.data

    Layout.fillWidth: true
    radius: UIScale.radiusMd
    color: Colors.withAlpha(Colors.text, 0.03)
    border.color: Colors.withAlpha(Colors.text, 0.06)
    border.width: 1
    implicitHeight: inner.implicitHeight + UIScale.spacingMd * 2

    ColumnLayout {
        id: inner
        anchors.fill: parent
        anchors.margins: UIScale.spacingMd
        spacing: UIScale.spacingSm
    }
}
