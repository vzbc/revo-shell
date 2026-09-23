import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "." as Components
import qs.services
import qs.commons
import qs.components

PanelWindow {
    id: root

    implicitWidth: ScalerService.s(930)
    implicitHeight: ScalerService.s(960)

    anchors {
        top: Settings.bar.position === "top"
        bottom: Settings.bar.position === "bottom"
        left: Settings.bar.position === "top" || Settings.bar.position === "bottom" || Settings.bar.position === "left"
        right: Settings.bar.position === "right"
    }

    margins {
        top: Settings.bar.position === "top" ? ScalerService.s(10) : 0

        bottom: Settings.bar.position === "bottom" ? ScalerService.s(10) : 0

        left: (Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(495) : ScalerService.s(10)

        right: Settings.bar.position === "right" ? ScalerService.s(10) : 0
    }

    exclusiveZone: 0
    color: "transparent"

    property real animationProgress: 0
    property bool openPanel: false

    SequentialAnimation {
        id: contentAnimation

        NumberAnimation {
            target: root
            property: "animationProgress"
            from: 0
            to: 2
            duration: 500
            easing.type: Easing.Linear
        }
    }

    Component.onCompleted: {
        openPanel = true;
    }

    function tryStartContentAnimation() {
        if (!widthAnim.running && !heightAnim.running && animationProgress === 0) {
            contentAnimation.start();
        }
    }

    Rectangle {
        id: contentRect

        anchors.centerIn: parent

        implicitWidth: openPanel ? parent.width : 0
        implicitHeight: openPanel ? parent.height : 0

        clip: true

        layer.enabled: true
        layer.smooth: true

        color: theme.primary.background
        border.color: theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

        Behavior on implicitHeight {
            NumberAnimation {
                id: heightAnim
                duration: 500
                easing.type: Easing.OutCubic

                onRunningChanged: root.tryStartContentAnimation()
            }
        }

        Behavior on implicitWidth {
            NumberAnimation {
                id: widthAnim
                duration: 500
                easing.type: Easing.OutCubic

                onRunningChanged: root.tryStartContentAnimation()
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
            spacing: ScalerService.s(30)

            Components.RamDetailHeader {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(40)
                animationProgress: root.animationProgress
            }

            Components.RamDisplay {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(330)
                animationProgress: root.animationProgress
            }

            Components.RamTaskManager {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(500)
                animationProgress: root.animationProgress
            }
        }

        Loader {
            anchors.fill: parent

            active: !heightAnim.running && !widthAnim.running

            sourceComponent: StarField {
                starCount: 10
                shootingStarCount: 3
            }
        }
    }
}
