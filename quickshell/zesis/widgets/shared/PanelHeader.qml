import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root
    property string breadcrumb: ""
    property string title: ""
    property Component rightActions: null

    TextMetrics {
        id: titleMetrics
        font.pixelSize: UIScale.fontHero
        font.weight: Font.ExtraBold
        text: root.title
    }
    TextMetrics {
        id: titleCompactMetrics
        font.pixelSize: UIScale.fontTitle
        font.weight: Font.ExtraBold
        text: root.title
    }
    TextMetrics {
        id: breadcrumbMetrics
        font.pixelSize: UIScale.fontCaption
        font.weight: Font.Bold
        font.letterSpacing: 2
        font.family: "monospace"
        text: root.breadcrumb
    }

    // Container-query breakpoint: react to our own laid-out width, not the screen. Compares
    // against the actual space available to the title (width minus the RowLayout's own
    // left/right margins), not root.width directly.
    readonly property bool compact: width > 0 && (width - UIScale.panelPad * 2) < titleMetrics.width

    // Must match the Column's own spacing below and the RowLayout's top/bottom margins
    readonly property real _colSpacing: Math.round(5 * UIScale.value)
    implicitHeight: breadcrumbMetrics.height + _colSpacing + (root.compact ? titleCompactMetrics.height : titleMetrics.height) + UIScale.spacingMd * 2

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: UIScale.panelPad
        anchors.rightMargin: UIScale.panelPad
        anchors.topMargin: UIScale.spacingMd
        anchors.bottomMargin: UIScale.spacingMd

        Column {
            spacing: Math.round(5 * UIScale.value)
            Layout.fillWidth: true

            Text {
                width: parent.width
                text: root.breadcrumb
                color: Colors.accent
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Bold
                font.letterSpacing: 2
                font.family: "monospace"
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.title
                color: Colors.text
                font.pixelSize: root.compact ? UIScale.fontTitle : UIScale.fontHero
                font.weight: Font.ExtraBold
                elide: Text.ElideRight
            }
        }

        Loader {
            sourceComponent: root.rightActions
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.withAlpha(Colors.text, 0.05)
    }
}
