import "../widgets" as Widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject notificationService
    readonly property string screenKey: screen !== null ? screen.name : ""
    readonly property var screenToasts: notificationService.toastsForScreen(screenKey)

    implicitWidth: theme.notificationToastWidth
    implicitHeight: toastColumn.implicitHeight
    color: "transparent"
    focusable: false
    visible: screenToasts.length > 0
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lotus-notification-toasts"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: theme.topReservedHeight + theme.space2
        right: theme.islandMargin
    }

    ColumnLayout {
        id: toastColumn

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: win.theme.notificationToastGap

        Repeater {

            model: ScriptModel {
                values: win.screenToasts
            }

            delegate: Widgets.NotificationToast {
                required property var modelData

                Layout.fillWidth: true
                theme: win.theme
                notificationService: win.notificationService
                entry: modelData
            }

        }

    }

}
