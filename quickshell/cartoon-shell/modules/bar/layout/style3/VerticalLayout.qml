import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import QtQuick.Effects
import qs.commons
import qs.services
import qs.components
import "../../widget/" as Com

ColumnLayout {
    id: root
    property real animationProgress: 0

    SequentialAnimation on animationProgress {
        running: true
        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        CustomRectangle {
            color: theme.primary.background
            anchors.centerIn: parent
            implicitWidth: root.animationProgress > 0.1 ? parent.width : 0
            implicitHeight: root.animationProgress > 0.1 ? parent.height : 0
            ColumnLayout {
                spacing: ScalerService.s(12)
                anchors.margins: ScalerService.s(5)
                anchors.fill: parent
            }
        }
    }
}
