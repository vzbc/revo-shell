pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Item {
    id: root

    property int selectedIndex: 0

    readonly property var mount: {
        var mounts = StorageService.mounts;
        if (mounts.length === 0)
            return null;
        if (root.selectedIndex >= mounts.length)
            return mounts[0];
        return mounts[root.selectedIndex];
    }

    function fmtBytes(n) {
        if (n >= 1099511627776)
            return (n / 1099511627776).toFixed(1) + " TB";
        if (n >= 1073741824)
            return (n / 1073741824).toFixed(1) + " GB";
        if (n >= 1048576)
            return (n / 1048576).toFixed(0) + " MB";
        if (n >= 1024)
            return (n / 1024).toFixed(0) + " KB";
        return n + " B";
    }

    Rectangle {
        anchors.fill: parent
        radius: UIScale.radiusLg
        topLeftRadius: 0
        topRightRadius: 0
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("storage.breadcrumb")
            title: I18n.t("storage.title")
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: col.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: col
                width: flick.width
                spacing: 0

                Item {
                    implicitHeight: UIScale.spacingMd
                }

                DonutChart {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.round(160 * UIScale.value)
                    Layout.preferredHeight: Math.round(160 * UIScale.value)
                    segments: root.mount ? [
                        {
                            color: Colors.accent,
                            value: root.mount.used
                        }
                    ] : []
                    total: root.mount ? root.mount.total : 1
                    centerText: root.mount ? root.fmtBytes(root.mount.used) : "-"
                    subText: root.mount ? root.fmtBytes(root.mount.total) : ""
                }

                Item {
                    implicitHeight: UIScale.spacingSm
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.mount ? root.mount.mountpoint : ""
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                    font.weight: Font.Medium
                }

                Item {
                    implicitHeight: UIScale.spacingMd
                }

                SectionLabel {
                    text: I18n.t("storage.mountsSection")
                    color: Colors.accent
                    font.weight: Font.Medium
                    Layout.leftMargin: UIScale.spacingMd
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                Repeater {
                    model: StorageService.mounts

                    delegate: Item {
                        id: mountRow
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.spacingSm
                        Layout.rightMargin: UIScale.spacingSm
                        implicitHeight: mountInner.implicitHeight + UIScale.spacingXs * 2

                        readonly property real pct: mountRow.modelData.total > 0 ? mountRow.modelData.used / mountRow.modelData.total : 0
                        readonly property bool isSelected: root.selectedIndex === mountRow.index

                        Rectangle {
                            anchors.fill: parent
                            radius: UIScale.radiusSm
                            color: mountRow.isSelected ? Colors.withAlpha(Colors.accent, 0.12) : (mountHover.hovered ? Colors.withAlpha(Colors.surface, 0.8) : "transparent")
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        ColumnLayout {
                            id: mountInner
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                topMargin: UIScale.spacingXs
                                leftMargin: UIScale.spacingSm
                                rightMargin: UIScale.spacingSm
                            }
                            spacing: Math.round(5 * UIScale.value)

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: mountRow.modelData.mountpoint
                                    color: mountRow.isSelected ? Colors.text : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                    font.weight: mountRow.isSelected ? Font.DemiBold : Font.Normal
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                }

                                Text {
                                    text: root.fmtBytes(mountRow.modelData.used) + " / " + root.fmtBytes(mountRow.modelData.total)
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.family: "monospace"
                                }
                            }

                            UsageBar {
                                value: mountRow.pct
                            }
                        }

                        HoverHandler {
                            id: mountHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedIndex = mountRow.index
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingMd
                }
            }
        }
    }
}
