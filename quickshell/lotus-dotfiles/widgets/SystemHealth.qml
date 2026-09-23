import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    required property QtObject theme
    required property QtObject systemStats
    required property QtObject systemHealth

    implicitWidth: 510
    implicitHeight: healthColumn.implicitHeight + theme.space4 * 2
    radius: theme.radiusPanel
    color: theme.surfaceMuted
    border.width: theme.borderWidth
    border.color: theme.ink

    ColumnLayout {
        id: healthColumn

        anchors.fill: parent
        anchors.margins: root.theme.space4
        spacing: root.theme.space3

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: "System health"
                    color: root.theme.ink
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textLg
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    text: "Local readings, sampled only while this desk is open"
                    color: root.theme.inkMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textXs
                }

            }

            Ui.IconButton {
                theme: root.theme
                controlSize: 32
                iconSource: Quickshell.shellDir + "/assets/icons/refresh.svg"
                accessibleName: "Refresh system health"
                fill: root.theme.blue
                onClicked: root.systemHealth.refreshAll()
            }

        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: root.theme.space2
            rowSpacing: root.theme.space2

            Ui.MetricCard {
                Layout.fillWidth: true
                theme: root.theme
                iconSource: Quickshell.shellDir + "/assets/icons/cpu.svg"
                label: "Processor"
                value: root.systemStats.cpuLoading ? "..." : (root.systemStats.cpuError ? "N/A" : root.systemStats.cpuUsage + "%")
                detail: "Current load"
                accent: root.theme.peach
            }

            Ui.MetricCard {
                Layout.fillWidth: true
                theme: root.theme
                iconSource: Quickshell.shellDir + "/assets/icons/memory.svg"
                label: "Memory"
                value: root.systemStats.memoryLoading ? "..." : (root.systemStats.memoryError ? "N/A" : root.systemStats.memoryUsage + "%")
                detail: "In use"
                accent: root.theme.blue
            }

            Ui.MetricCard {
                Layout.fillWidth: true
                theme: root.theme
                iconSource: Quickshell.shellDir + "/assets/icons/disk.svg"
                label: "Storage"
                value: root.systemHealth.diskLoading ? "..." : (root.systemHealth.diskError ? "N/A" : root.systemHealth.diskUsage + "%")
                detail: root.systemHealth.diskError ? "Unavailable" : root.systemHealth.diskFreeText + " free"
                accent: root.theme.green
            }

            Ui.MetricCard {
                Layout.fillWidth: true
                theme: root.theme
                iconSource: Quickshell.shellDir + "/assets/icons/temperature.svg"
                label: "CPU temp"
                value: root.systemHealth.cpuTemperatureText
                detail: "Tctl sensor"
                accent: root.theme.coral
            }

            Ui.MetricCard {
                Layout.fillWidth: true
                theme: root.theme
                iconSource: Quickshell.shellDir + "/assets/icons/temperature.svg"
                label: "GPU temp"
                value: root.systemHealth.gpuTemperatureText
                detail: "Edge sensor"
                accent: root.theme.pink
            }

            Ui.MetricCard {
                Layout.fillWidth: true
                theme: root.theme
                iconSource: Quickshell.shellDir + "/assets/icons/temperature.svg"
                label: "NVMe temp"
                value: root.systemHealth.driveTemperatureText
                detail: "Composite"
                accent: root.theme.gold
            }

            Ui.MetricCard {
                Layout.fillWidth: true
                theme: root.theme
                iconSource: Quickshell.shellDir + "/assets/icons/download.svg"
                label: "Download"
                value: root.systemHealth.downloadText
                detail: "All active links"
                accent: root.theme.blue
            }

            Ui.MetricCard {
                Layout.fillWidth: true
                theme: root.theme
                iconSource: Quickshell.shellDir + "/assets/icons/upload.svg"
                label: "Upload"
                value: root.systemHealth.uploadText
                detail: "All active links"
                accent: root.theme.lilac
            }

            Ui.MetricCard {
                Layout.fillWidth: true
                theme: root.theme
                iconSource: Quickshell.shellDir + "/assets/icons/updates.svg"
                label: "Updates"
                value: root.systemHealth.updatesText
                detail: root.systemHealth.updatesError ? "Check failed" : (root.systemHealth.updatesCount === 1 ? "Package ready" : "Packages ready")
                accent: root.theme.gold
            }

        }

    }

}
