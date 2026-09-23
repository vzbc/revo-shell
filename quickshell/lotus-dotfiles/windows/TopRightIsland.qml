import "../widgets" as Widgets
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject clockService
    required property QtObject audioService
    required property QtObject networkService
    required property QtObject bluetoothService
    required property QtObject notificationService
    required property QtObject notificationController
    required property QtObject trayController
    required property QtObject brightnessService
    required property QtObject systemStats
    required property QtObject calendarService
    required property QtObject sessionService
    required property QtObject panelController
    required property QtObject attentionService
    readonly property string screenKey: screen !== null ? screen.name : "default"
    readonly property bool panelOpen: quickPanelWindow.visible
    readonly property bool audioStudioOpen: audioStudioWindow.visible

    implicitWidth: status.implicitWidth
    implicitHeight: status.implicitHeight
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lotus-top-right"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Component.onDestruction: panelController.setOpen(screenKey, false)

    anchors {
        top: true
        right: true
    }

    margins {
        top: theme.islandMargin
        right: theme.islandMargin
    }

    Widgets.TopRightStatus {
        id: status

        anchors.fill: parent
        theme: win.theme
        clockService: win.clockService
        audioService: win.audioService
        networkService: win.networkService
        bluetoothService: win.bluetoothService
        notificationService: win.notificationService
        panelOpen: win.panelOpen
        audioStudioOpen: win.audioStudioOpen
        notificationCenterOpen: win.notificationController.isOpen(win.screenKey)
        onPanelToggleRequested: {
            audioStudioWindow.visible = false;
            win.notificationController.close();
            win.trayController.close();
            quickPanelWindow.visible = !quickPanelWindow.visible;
        }
        onAudioStudioToggleRequested: {
            quickPanelWindow.visible = false;
            win.notificationController.close();
            win.trayController.close();
            audioStudioWindow.visible = !audioStudioWindow.visible;
        }
        onNotificationToggleRequested: {
            quickPanelWindow.visible = false;
            audioStudioWindow.visible = false;
            win.trayController.close();
            win.notificationController.toggle(win.screenKey);
        }
    }

    PanelWindow {
        id: audioStudioWindow

        screen: win.screen
        implicitWidth: audioStudio.implicitWidth
        implicitHeight: audioStudio.implicitHeight
        color: "transparent"
        focusable: true
        visible: false
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "lotus-audio-studio"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => {
                return audioStudio.open();
            });

        }

        anchors {
            top: true
            right: true
        }

        margins {
            top: win.theme.islandMargin + win.implicitHeight + win.theme.space2
            right: win.theme.islandMargin
        }

        Widgets.AudioStudio {
            id: audioStudio

            anchors.fill: parent
            theme: win.theme
            audioService: win.audioService
            onCloseRequested: audioStudioWindow.visible = false
        }

    }

    PanelWindow {
        id: quickPanelWindow

        screen: win.screen
        implicitWidth: quickPanel.implicitWidth
        implicitHeight: quickPanel.implicitHeight
        color: "transparent"
        focusable: true
        visible: false
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "lotus-quick-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        onVisibleChanged: {
            win.panelController.setOpen(win.screenKey, visible);
            if (visible) {
                win.calendarService.goToToday();
                Qt.callLater(() => {
                    return quickPanel.forceActiveFocus();
                });
            } else {
                quickPanel.resetTransientState();
            }
        }

        anchors {
            top: true
            right: true
        }

        margins {
            top: win.theme.islandMargin + win.implicitHeight + win.theme.space2
            right: win.theme.islandMargin
        }

        Widgets.QuickPanel {
            id: quickPanel

            anchors.fill: parent
            theme: win.theme
            clockService: win.clockService
            audioService: win.audioService
            networkService: win.networkService
            bluetoothService: win.bluetoothService
            notificationService: win.notificationService
            brightnessService: win.brightnessService
            systemStats: win.systemStats
            calendarService: win.calendarService
            sessionService: win.sessionService
            attentionService: win.attentionService
            onCloseRequested: quickPanelWindow.visible = false
            onNotificationsRequested: {
                quickPanelWindow.visible = false;
                win.notificationController.open(win.screenKey);
            }
        }

    }

    HyprlandFocusGrab {
        active: quickPanelWindow.visible
        windows: [quickPanelWindow]
        onCleared: quickPanelWindow.visible = false
    }

    HyprlandFocusGrab {
        active: audioStudioWindow.visible
        windows: [audioStudioWindow]
        onCleared: audioStudioWindow.visible = false
    }

    IdleInhibitor {
        window: win
        enabled: win.attentionService.caffeineEnabled
    }

    Connections {
        function onCloseRevisionChanged() {
            quickPanelWindow.visible = false;
            audioStudioWindow.visible = false;
        }

        target: win.panelController
    }

}
