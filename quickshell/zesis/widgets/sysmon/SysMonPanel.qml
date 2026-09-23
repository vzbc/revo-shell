pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../shared"
import "../../"

Item {
    id: root

    Component.onCompleted: SysMonService.panelOpen = true
    Component.onDestruction: SysMonService.panelOpen = false

    property int sortField: 2   // 0=pid  1=name  2=value
    property bool sortAsc: false

    function setSortField(f) {
        if (sortField === f)
            sortAsc = !sortAsc;
        else {
            sortField = f;
            sortAsc = f !== 2;
        }
    }

    function sortIndicator(f) {
        return sortField === f ? (sortAsc ? " ↑" : " ↓") : "";
    }

    readonly property var _sortedCpuProcs: {
        var arr = (SysMonService.cpu.procs || []).slice();
        arr.sort(function (a, b) {
            var v = root.sortField === 0 ? a.pid - b.pid : root.sortField === 1 ? (a.name < b.name ? -1 : a.name > b.name ? 1 : 0) : a.cpu - b.cpu;
            return root.sortAsc ? v : -v;
        });
        return arr;
    }

    readonly property var _sortedMemProcs: {
        var arr = (SysMonService.memory.procs || []).slice();
        arr.sort(function (a, b) {
            var v = root.sortField === 0 ? a.pid - b.pid : root.sortField === 1 ? (a.name < b.name ? -1 : a.name > b.name ? 1 : 0) : a.rss - b.rss;
            return root.sortAsc ? v : -v;
        });
        return arr;
    }

    readonly property var _sortedGpuProcs: {
        var arr = (SysMonService.gpuCard ? (SysMonService.gpuCard.procs || []) : []).slice();
        arr.sort(function (a, b) {
            var v = root.sortField === 0 ? a.pid - b.pid : root.sortField === 1 ? (a.name < b.name ? -1 : a.name > b.name ? 1 : 0) : a.vram_kib - b.vram_kib;
            return root.sortAsc ? v : -v;
        });
        return arr;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("sysmon.breadcrumb")
            title: I18n.t("sysmon.title")
        }

        SysMonTabBar {
            Layout.fillWidth: true
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: tabContent.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Item {
                id: tabContent
                width: flick.width
                implicitHeight: cpuTab.visible ? cpuTab.implicitHeight : memTab.visible ? memTab.implicitHeight : gpuTab.visible ? gpuTab.implicitHeight : netTab.visible ? netTab.implicitHeight : diskTab.visible ? diskTab.implicitHeight : settingsTab.implicitHeight

                // CPU
                ColumnLayout {
                    id: cpuTab
                    width: parent.width
                    visible: SysMonService.activeTab === 0
                    spacing: Math.round(6 * UIScale.value)

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingLg

                        DonutChart {
                            Layout.preferredWidth: Math.round(200 * UIScale.value)
                            Layout.preferredHeight: Math.round(200 * UIScale.value)
                            Layout.alignment: Qt.AlignTop
                            segments: SysMonService.cpuSegments
                            total: 100
                            centerText: SysMonService.cpu.percent ? SysMonService.cpu.percent.toFixed(0) + "%" : "0%"
                            subText: "load " + (SysMonService.cpu.load ? SysMonService.cpu.load.toFixed(2) : "0")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(6 * UIScale.value)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Item {
                                    implicitWidth: Math.round(16 * UIScale.value)
                                }

                                Text {
                                    Layout.preferredWidth: Math.round(50 * UIScale.value)
                                    text: I18n.t("sysmon.pid") + root.sortIndicator(0)
                                    color: root.sortField === 0 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(0)
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: I18n.t("sysmon.name") + root.sortIndicator(1)
                                    color: root.sortField === 1 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(1)
                                    }
                                }
                                Text {
                                    text: I18n.t("sysmon.cpuPercent") + root.sortIndicator(2)
                                    color: root.sortField === 2 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(2)
                                    }
                                }
                            }

                            Repeater {
                                model: root._sortedCpuProcs.length === 0 ? 8 : 0
                                delegate: SysMonSkeletonRow {
                                    rowHeight: Math.round(24 * UIScale.value)
                                }
                            }

                            Repeater {
                                model: root._sortedCpuProcs
                                delegate: Item {
                                    id: cpuProcItem
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(24 * UIScale.value)

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 0

                                        Rectangle {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                            implicitHeight: Math.round(8 * UIScale.value)
                                            radius: Math.round(2 * UIScale.value)
                                            color: SysMonService.procColor(cpuProcItem.modelData.name)
                                        }
                                        Item {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                        }
                                        Text {
                                            Layout.preferredWidth: Math.round(50 * UIScale.value)
                                            text: cpuProcItem.modelData.pid
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: cpuProcItem.modelData.name
                                            color: Colors.text
                                            font.pixelSize: UIScale.fontSmall
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: cpuProcItem.modelData.cpu.toFixed(1) + "%"
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }
                }

                // Memory
                ColumnLayout {
                    id: memTab
                    width: parent.width
                    visible: SysMonService.activeTab === 1
                    spacing: Math.round(6 * UIScale.value)

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingLg

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(8 * UIScale.value)

                            DonutChart {
                                Layout.preferredWidth: Math.round(200 * UIScale.value)
                                Layout.preferredHeight: Math.round(200 * UIScale.value)
                                segments: SysMonService.memSegments
                                total: SysMonService.memory.total_bytes
                                centerText: SysMonService.fmtBytes(SysMonService.memory.used_bytes)
                                subText: SysMonService.fmtBytes(SysMonService.memory.total_bytes)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: SysMonService.memory.swap_total_bytes > 0
                                spacing: Math.round(6 * UIScale.value)

                                Text {
                                    text: I18n.t("sysmon.swap")
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(4 * UIScale.value)
                                    radius: Math.round(2 * UIScale.value)
                                    color: Colors.surface

                                    Rectangle {
                                        width: parent.width * (SysMonService.memory.swap_total_bytes > 0 ? SysMonService.memory.swap_used_bytes / SysMonService.memory.swap_total_bytes : 0)
                                        height: parent.height
                                        radius: parent.radius
                                        color: Colors.accent
                                        opacity: 0.6
                                    }
                                }
                                Text {
                                    text: SysMonService.fmtBytes(SysMonService.memory.swap_used_bytes) + " / " + SysMonService.fmtBytes(SysMonService.memory.swap_total_bytes)
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.family: "monospace"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(6 * UIScale.value)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Item {
                                    implicitWidth: Math.round(16 * UIScale.value)
                                }

                                Text {
                                    Layout.preferredWidth: Math.round(50 * UIScale.value)
                                    text: I18n.t("sysmon.pid") + root.sortIndicator(0)
                                    color: root.sortField === 0 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(0)
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: I18n.t("sysmon.name") + root.sortIndicator(1)
                                    color: root.sortField === 1 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(1)
                                    }
                                }
                                Text {
                                    text: I18n.t("sysmon.memory") + root.sortIndicator(2)
                                    color: root.sortField === 2 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(2)
                                    }
                                }
                            }

                            Repeater {
                                model: root._sortedMemProcs.length === 0 ? 8 : 0
                                delegate: SysMonSkeletonRow {
                                    rowHeight: Math.round(24 * UIScale.value)
                                }
                            }

                            Repeater {
                                model: root._sortedMemProcs
                                delegate: Item {
                                    id: memProcItem
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(24 * UIScale.value)

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 0

                                        Rectangle {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                            implicitHeight: Math.round(8 * UIScale.value)
                                            radius: Math.round(2 * UIScale.value)
                                            color: SysMonService.procColor(memProcItem.modelData.name)
                                        }
                                        Item {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                        }
                                        Text {
                                            Layout.preferredWidth: Math.round(50 * UIScale.value)
                                            text: memProcItem.modelData.pid
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: memProcItem.modelData.name
                                            color: Colors.text
                                            font.pixelSize: UIScale.fontSmall
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: SysMonService.fmtBytes(memProcItem.modelData.rss)
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }
                }

                // GPU
                ColumnLayout {
                    id: gpuTab
                    width: parent.width
                    visible: SysMonService.activeTab === 2
                    spacing: Math.round(8 * UIScale.value)

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: Math.round(6 * UIScale.value)
                        visible: SysMonService.gpu.length > 1

                        Repeater {
                            model: SysMonService.gpu
                            delegate: Rectangle {
                                id: chip
                                required property var modelData
                                required property int index

                                property bool active: SysMonService.selectedCard === chip.index

                                height: Math.round(28 * UIScale.value)
                                width: chipLabel.implicitWidth + Math.round(16 * UIScale.value)
                                radius: UIScale.radiusSm
                                color: chip.active ? Colors.withAlpha(Colors.accent, 0.15) : chipHover.hovered ? Colors.withAlpha(Colors.text, 0.06) : "transparent"
                                border.color: chip.active ? Colors.withAlpha(Colors.accent, 0.4) : "transparent"
                                border.width: 1
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: chip.modelData.card
                                    color: chip.active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }
                                HoverHandler {
                                    id: chipHover
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SysMonService.selectedCard = chip.index
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingLg

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(4 * UIScale.value)

                            DonutChart {
                                Layout.preferredWidth: Math.round(180 * UIScale.value)
                                Layout.preferredHeight: Math.round(180 * UIScale.value)
                                segments: SysMonService.gpuComputeSegments
                                total: 100
                                centerText: SysMonService.gpuCard ? SysMonService.gpuCard.busy + "%" : "0%"
                                subText: SysMonService.gpuCard ? SysMonService.gpuCard.temp_c.toFixed(0) + "°C · " + SysMonService.gpuCard.power_w.toFixed(0) + "W" : ""
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: I18n.t("sysmon.compute")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                                font.weight: Font.Medium
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(4 * UIScale.value)

                            DonutChart {
                                Layout.preferredWidth: Math.round(180 * UIScale.value)
                                Layout.preferredHeight: Math.round(180 * UIScale.value)
                                segments: SysMonService.gpuVramSegments
                                total: SysMonService.gpuCard ? SysMonService.gpuCard.vram_total : 1
                                centerText: SysMonService.gpuCard ? SysMonService.fmtBytes(SysMonService.gpuCard.vram_used) : "0"
                                subText: SysMonService.gpuCard ? SysMonService.fmtBytes(SysMonService.gpuCard.vram_total) : ""
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: I18n.t("sysmon.vram")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                                font.weight: Font.Medium
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(6 * UIScale.value)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Item {
                                    implicitWidth: Math.round(16 * UIScale.value)
                                }

                                Text {
                                    Layout.preferredWidth: Math.round(50 * UIScale.value)
                                    text: I18n.t("sysmon.pid") + root.sortIndicator(0)
                                    color: root.sortField === 0 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(0)
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: I18n.t("sysmon.name") + root.sortIndicator(1)
                                    color: root.sortField === 1 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(1)
                                    }
                                }
                                Text {
                                    Layout.preferredWidth: Math.round(52 * UIScale.value)
                                    text: I18n.t("sysmon.gfxPercent")
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                }
                                Text {
                                    text: I18n.t("sysmon.vram") + root.sortIndicator(2)
                                    color: root.sortField === 2 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(2)
                                    }
                                }
                            }

                            Repeater {
                                model: root._sortedGpuProcs.length === 0 ? 8 : 0
                                delegate: SysMonSkeletonRow {
                                    rowHeight: Math.round(24 * UIScale.value)
                                }
                            }

                            Repeater {
                                model: root._sortedGpuProcs
                                delegate: Item {
                                    id: gpuProcItem
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(24 * UIScale.value)

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 0

                                        Rectangle {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                            implicitHeight: Math.round(8 * UIScale.value)
                                            radius: Math.round(2 * UIScale.value)
                                            color: SysMonService.procColor(gpuProcItem.modelData.name)
                                        }
                                        Item {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                        }
                                        Text {
                                            Layout.preferredWidth: Math.round(50 * UIScale.value)
                                            text: gpuProcItem.modelData.pid
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: gpuProcItem.modelData.name
                                            color: Colors.text
                                            font.pixelSize: UIScale.fontSmall
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.preferredWidth: Math.round(52 * UIScale.value)
                                            text: gpuProcItem.modelData.gfx_pct > 0 ? gpuProcItem.modelData.gfx_pct.toFixed(1) + "%" : ""
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                        Text {
                                            text: SysMonService.fmtBytes(gpuProcItem.modelData.vram_kib * 1024)
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                visible: SysMonService.gpu.length === 0
                                text: I18n.t("sysmon.noGpuDetected")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }
                        }
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }
                }

                SysMonNetTab {
                    id: netTab
                    compact: false
                    width: parent.width
                    visible: SysMonService.activeTab === 3
                }

                SysMonDiskTab {
                    id: diskTab
                    compact: false
                    width: parent.width
                    visible: SysMonService.activeTab === 4
                }

                SysMonSettingsTab {
                    id: settingsTab
                    compact: false
                    width: parent.width
                    visible: SysMonService.activeTab === 5
                }
            }
        }
    }
}
