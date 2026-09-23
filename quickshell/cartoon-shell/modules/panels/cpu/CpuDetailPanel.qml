import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Io
import "./" as Com
import qs.services
import qs.commons
import qs.components

PanelWindow {
    id: root

    implicitWidth: ScalerService.s(1000)
    implicitHeight: ScalerService.s(850)

    anchors {
        top: Settings.bar.position === "top"
        bottom: Settings.bar.position === "bottom"
        left: Settings.bar.position === "top" || Settings.bar.position === "bottom" || Settings.bar.position === "left"
        right: Settings.bar.position === "right"
    }

    margins {
        top: Settings.bar.position === "top" ? ScalerService.s(10) : 0
        bottom: Settings.bar.position === "bottom" ? ScalerService.s(10) : 0
        left: (Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(460) : ScalerService.s(10)
        right: Settings.bar.position === "right" ? ScalerService.s(10) : 0
    }
    exclusiveZone: 0

    property real animationProgress: 0
    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 2
            duration: 1000
            easing.type: Easing.Linear
        }
    }

    color: "transparent"

    signal closeRequested

    Rectangle {
        color: theme.primary.background
        border.color: theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0 ? parent.width : 0
        implicitHeight: root.animationProgress > 0 ? parent.height : 0
        Behavior on implicitHeight {
            NumberAnimation {
                id: heightAnim
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                id: widthAnim
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Loader {
            anchors.fill: parent

            active: !heightAnim.running && !widthAnim.running

            sourceComponent: FloatingCircles {
                circleColor: theme.button.text
                anchors.fill: parent
                circleCount: 4
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(16)
            spacing: ScalerService.s(16)

            // Header với nút đóng
            Com.CpuDetailHeader {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(40)
            }
            // Thông tin CPU
            Com.CpuInfoSection {
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.2
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                RowLayout {
                    anchors.fill: parent

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Com.CpuUsageChart {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }

                    Com.CpuTaskManager {
                        Layout.preferredWidth: parent.width * 0.5
                        Layout.fillHeight: true
                    }
                }
            }
        }
        Loader {
            anchors.fill: parent

            active: !heightAnim.running && !widthAnim.running

            sourceComponent: StarField {
                starCount: 10
                shootingStarCount: 2
            }
        }
    }
}
