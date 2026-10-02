import QtQuick
import ".."

Column {
    id: page

    property string pageId: "gen.storage"
    property bool emptyBins: false
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    width: parent ? parent.width : 700
    spacing: 12

    readonly property var cats: [
        { key: "applications", label: "Applications", color: Theme.textSecondary },
        { key: "documents", label: "Documents", color: "#0A84FF" },
        { key: "macos", label: "macOS", color: "#5E5CE6" },
        { key: "systemData", label: "System Data", color: "#FF9F0A" },
        { key: "bins", label: "Bins", color: "#30D158" }
    ]
    readonly property double total: SysInfo.totalBytes
    readonly property double used: SysInfo.usedBytes

    Item { width: 1; height: 4 }

    // Storage bar
    Rectangle {
        x: 12
        width: parent.width - 24
        height: 18
        radius: 9
        color: Theme.trackBg
        clip: true

        Row {
            anchors.fill: parent
            spacing: 2

            Repeater {
                model: page.cats

                delegate: Rectangle {
                    required property var modelData
                    width: {
                        if (page.total <= 0)
                            return 0
                        var v = SysInfo.category(modelData.key)
                        return Math.max(0, (v / page.total) * (page.width - 24) - 1)
                    }
                    height: parent ? parent.height : 18
                    color: modelData.color
                    radius: 0
                    visible: width > 0.5
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: page.total > 0
            text: SysInfo.fmt(page.used) + " of " + SysInfo.fmt(page.total) + " used"
            font { family: Theme.fontText; pixelSize: 11; weight: Font.DemiBold }
            color: "white"
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.35)
        }
    }

    Text {
        x: 24
        width: parent.width - 48
        visible: SysInfo.scanning
        text: "Calculating category sizes…"
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }

    // Categories
    GroupCard {
        Repeater {
            model: page.cats

            delegate: DetailRow {
                required property var modelData
                title: modelData.label
                value: SysInfo.scanning ? "" : SysInfo.fmt(SysInfo.category(modelData.key))
                chevron: true
                onClicked: page.navigate("gen.storage." + modelData.key)
            }
        }
    }

    // Recommendations
    GroupCard {
        DetailRow {
            title: "Store in iCloud Photos"
            chevron: true
            onClicked: {}
        }
        DetailRow {
            separator: true
            title: "Optimise Storage"
            chevron: true
            onClicked: {}
        }
        DetailRow {
            separator: true
            title: "Empty Bins Automatically"
            showSwitch: true
            switchOn: page.emptyBins
            onToggled: page.emptyBins = checked
        }
        DetailRow {
            separator: true
            title: "Review Large Files"
            chevron: true
            onClicked: {}
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "macOS stores files in categories. Optimise Storage removes films, TV programmes and attachments you already watched or downloaded."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }

    Item { width: 1; height: 2 }
}
