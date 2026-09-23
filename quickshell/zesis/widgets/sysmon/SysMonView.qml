pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(16 * UIScale.value)
        spacing: Math.round(10 * UIScale.value)

        SysMonTabBar {
            compact: true
            Layout.alignment: Qt.AlignHCenter
        }

        // CPU
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * UIScale.value)
            visible: SysMonService.activeTab === 0

            DonutChart {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.round(170 * UIScale.value)
                Layout.preferredHeight: Math.round(170 * UIScale.value)
                segments: SysMonService.cpuSegments
                total: 100
                centerText: SysMonService.cpu.percent ? SysMonService.cpu.percent.toFixed(0) + "%" : "0%"
                subText: "load " + (SysMonService.cpu.load ? SysMonService.cpu.load.toFixed(2) : "0")
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: I18n.t("sysmon.cpu")
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Medium
            }

            Item {
                Layout.preferredHeight: Math.round(4 * UIScale.value)
            }

            Repeater {
                model: (SysMonService.cpu.procs || []).length === 0 ? 8 : 0
                delegate: SysMonSkeletonRow {}
            }

            Repeater {
                model: SysMonService.cpu.procs || []
                delegate: Item {
                    id: procItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

                    Rectangle {
                        id: dot
                        width: Math.round(8 * UIScale.value)
                        height: Math.round(8 * UIScale.value)
                        radius: Math.round(2 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        color: SysMonService.procColor(procItem.modelData.name)
                    }
                    Text {
                        anchors.left: dot.right
                        anchors.leftMargin: Math.round(8 * UIScale.value)
                        anchors.right: val.left
                        anchors.rightMargin: Math.round(8 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: procItem.modelData.name
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                        elide: Text.ElideRight
                    }
                    Text {
                        id: val
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: procItem.modelData.cpu.toFixed(1) + "%"
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // Memory
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * UIScale.value)
            visible: SysMonService.activeTab === 1

            DonutChart {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.round(170 * UIScale.value)
                Layout.preferredHeight: Math.round(170 * UIScale.value)
                segments: SysMonService.memSegments
                total: SysMonService.memory.total_bytes
                centerText: SysMonService.fmtBytes(SysMonService.memory.used_bytes)
                subText: SysMonService.fmtBytes(SysMonService.memory.total_bytes)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: I18n.t("sysmon.memory")
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Medium
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

            Item {
                Layout.preferredHeight: Math.round(4 * UIScale.value)
            }

            Repeater {
                model: (SysMonService.memory.procs || []).length === 0 ? 8 : 0
                delegate: SysMonSkeletonRow {}
            }

            Repeater {
                model: SysMonService.memory.procs || []
                delegate: Item {
                    id: memProcItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

                    Rectangle {
                        id: memDot
                        width: Math.round(8 * UIScale.value)
                        height: Math.round(8 * UIScale.value)
                        radius: Math.round(2 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        color: SysMonService.procColor(memProcItem.modelData.name)
                    }
                    Text {
                        anchors.left: memDot.right
                        anchors.leftMargin: Math.round(8 * UIScale.value)
                        anchors.right: memVal.left
                        anchors.rightMargin: Math.round(8 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: memProcItem.modelData.name
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                        elide: Text.ElideRight
                    }
                    Text {
                        id: memVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: SysMonService.fmtBytes(memProcItem.modelData.rss)
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // GPU
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * UIScale.value)
            visible: SysMonService.activeTab === 2

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Math.round(6 * UIScale.value)
                visible: SysMonService.gpu.length > 1

                Repeater {
                    model: SysMonService.gpu
                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        required property int index

                        property bool active: SysMonService.selectedCard === chip.index

                        height: Math.round(24 * UIScale.value)
                        width: chipLabel.implicitWidth + Math.round(16 * UIScale.value)
                        radius: Math.round(6 * UIScale.value)
                        color: chip.active ? Colors.surface : chipArea.containsMouse ? Colors.withAlpha(Colors.surface, 0.6) : "transparent"
                        border.color: chip.active ? Colors.outline : "transparent"
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
                            color: chip.active ? Colors.text : Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                        }
                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SysMonService.selectedCard = chip.index
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: UIScale.spacingLg

                ColumnLayout {
                    spacing: Math.round(4 * UIScale.value)

                    DonutChart {
                        Layout.preferredWidth: Math.round(140 * UIScale.value)
                        Layout.preferredHeight: Math.round(140 * UIScale.value)
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
                    spacing: Math.round(4 * UIScale.value)

                    DonutChart {
                        Layout.preferredWidth: Math.round(140 * UIScale.value)
                        Layout.preferredHeight: Math.round(140 * UIScale.value)
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
            }

            Item {
                Layout.preferredHeight: Math.round(4 * UIScale.value)
            }

            Repeater {
                model: (SysMonService.gpuCard && (SysMonService.gpuCard.procs || []).length === 0) ? 8 : 0
                delegate: SysMonSkeletonRow {}
            }

            Repeater {
                model: SysMonService.gpuCard ? SysMonService.gpuCard.procs || [] : []
                delegate: Item {
                    id: gpuProcItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

                    Rectangle {
                        id: gpuDot
                        width: Math.round(8 * UIScale.value)
                        height: Math.round(8 * UIScale.value)
                        radius: Math.round(2 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        color: SysMonService.procColor(gpuProcItem.modelData.name)
                    }
                    Text {
                        anchors.left: gpuDot.right
                        anchors.leftMargin: Math.round(8 * UIScale.value)
                        anchors.right: gfxVal.left
                        anchors.rightMargin: Math.round(8 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: gpuProcItem.modelData.name
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                        elide: Text.ElideRight
                    }
                    Text {
                        id: gfxVal
                        anchors.right: vramVal.left
                        anchors.rightMargin: Math.round(10 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: gpuProcItem.modelData.gfx_pct.toFixed(1) + "%"
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                        visible: gpuProcItem.modelData.gfx_pct > 0
                    }
                    Text {
                        id: vramVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: SysMonService.fmtBytes(gpuProcItem.modelData.vram_kib * 1024)
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
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

            Item {
                Layout.fillHeight: true
            }
        }

        SysMonNetTab {
            compact: true
            visible: SysMonService.activeTab === 3
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        SysMonDiskTab {
            compact: true
            visible: SysMonService.activeTab === 4
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        SysMonSettingsTab {
            compact: true
            visible: SysMonService.activeTab === 5
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
