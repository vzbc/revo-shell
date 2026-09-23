import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

Ui.RaisedSurface {
    id: root

    required property var screen
    required property QtObject launcherService
    required property QtObject launcherController
    required property QtObject workspaceService
    required property QtObject dashboardController
    required property QtObject clipboardController
    required property QtObject clipboardService
    required property QtObject notificationController
    required property QtObject panelController
    required property QtObject trayService
    required property QtObject trayController
    required property var trayParentWindow

    implicitWidth: contentRow.implicitWidth + padding * 2 + theme.shadowOffset
    implicitHeight: theme.sideIslandHeight
    padding: theme.space2
    fill: theme.surface
    surfaceRadius: theme.radiusCard

    RowLayout {
        id: contentRow

        anchors.fill: parent
        spacing: root.theme.space2

        Ui.IconButton {
            theme: root.theme
            controlSize: root.theme.compactControlSize
            iconSource: Quickshell.shellDir + "/assets/icons/lotus.svg"
            accessibleName: root.launcherService.statusText
            fill: root.theme.peach
            raised: true
            badgeText: root.launcherService.fallbackError && !root.launcherService.nativeAvailable ? "!" : ""
            enabled: root.launcherService.loading || root.launcherService.nativeAvailable || root.launcherService.fallbackAvailable
            onClicked: {
                root.dashboardController.close();
                root.clipboardController.close();
                root.notificationController.close();
                root.panelController.closeAll();
                root.trayController.close();
                root.launcherController.toggle(root.screen.name);
            }
        }

        Rectangle {
            Layout.preferredWidth: workspacesRow.implicitWidth + root.theme.space2
            Layout.preferredHeight: root.theme.compactControlSize
            radius: root.theme.radiusControl
            color: root.theme.surfaceRaised
            border.width: root.theme.borderWidth
            border.color: root.theme.ink

            RowLayout {
                id: workspacesRow

                anchors.centerIn: parent
                spacing: 0

                Repeater {
                    model: root.workspaceService.lastWorkspace

                    WorkspaceButton {
                        required property int index
                        readonly property int workspaceNumber: index + 1
                        readonly property var state: root.workspaceService.workspaceInfo(workspaceNumber, root.screen)

                        theme: root.theme
                        workspaceId: workspaceNumber
                        active: state.active
                        occupied: state.occupied
                        urgent: state.urgent
                        windowCount: state.windowCount
                        onClicked: root.workspaceService.activate(workspaceNumber)
                    }

                }

            }

            WheelHandler {
                onWheel: (event) => {
                    if (event.angleDelta.y === 0)
                        return ;

                    root.workspaceService.cycle(event.angleDelta.y > 0 ? -1 : 1, root.screen);
                    event.accepted = true;
                }
            }

        }

        TrayCluster {
            theme: root.theme
            trayService: root.trayService
            trayController: root.trayController
            screen: root.screen
            parentWindow: root.trayParentWindow
            onOpeningRequested: {
                root.launcherController.close();
                root.dashboardController.close();
                root.clipboardController.close();
                root.notificationController.close();
                root.panelController.closeAll();
            }
        }

        Ui.IconButton {
            theme: root.theme
            controlSize: root.theme.compactControlSize
            iconSource: Quickshell.shellDir + "/assets/icons/dashboard.svg"
            accessibleName: root.dashboardController.isOpen(root.screen.name) ? "Close Info dashboard" : "Open Info dashboard"
            fill: root.dashboardController.isOpen(root.screen.name) ? root.theme.lilac : root.theme.green
            onClicked: {
                root.launcherController.close();
                root.clipboardController.close();
                root.notificationController.close();
                root.panelController.closeAll();
                root.trayController.close();
                root.dashboardController.toggle(root.screen.name);
            }
        }

        Ui.IconButton {
            theme: root.theme
            controlSize: root.theme.compactControlSize
            iconSource: Quickshell.shellDir + "/assets/icons/clipboard.svg"
            accessibleName: "Open local clipboard history"
            fill: root.clipboardController.isOpen(root.screen.name) ? root.theme.lilac : root.theme.pink
            badgeText: root.clipboardService.items.length > 0 ? (root.clipboardService.items.length > 9 ? "9+" : String(root.clipboardService.items.length)) : ""
            onClicked: {
                root.launcherController.close();
                root.dashboardController.close();
                root.notificationController.close();
                root.panelController.closeAll();
                root.trayController.close();
                root.clipboardController.toggle(root.screen.name);
            }
        }

    }

}
