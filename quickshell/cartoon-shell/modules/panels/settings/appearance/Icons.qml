import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons
import Quickshell.Io
import "./icon/" as Com

Item {
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
    ListView {
        id: scrollView
        anchors.fill: parent
        clip: true
        anchors.margins: ScalerService.s(20)
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        focus: true
        contentHeight: mainLayout.implicitHeight

        model: 1
        delegate: ColumnLayout {
            id: mainLayout
            width: scrollView.width
            spacing: ScalerService.s(25)

            HeaderSettings {
                name: "Icons Settings"
                Layout.fillWidth: true
            }
            Com.StyleIconSettings {}
            Com.IconWorkspace {
                Layout.fillWidth: true
                animationProgress: root.animationProgress
            }
            Com.PanelSystemStats {}
        }
    }
}
