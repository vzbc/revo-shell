//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "services" as Services
import "windows" as Windows

ShellRoot {
    Theme {
        id: lotusTheme
    }

    UserConfig {
        id: configuration
    }

    Services.ClockService {
        id: sharedClock
    }

    Services.AudioService {
        id: sharedAudio
    }

    Services.NetworkService {
        id: sharedNetwork
    }

    Services.BluetoothService {
        id: sharedBluetooth
    }

    Services.SystemTrayService {
        id: sharedTray
    }

    Services.NotificationService {
        id: sharedNotifications

        theme: lotusTheme
        userConfig: configuration
    }

    Services.PanelController {
        id: quickPanelState
    }

    Services.OverlayController {
        id: dashboardState
    }

    Services.OverlayController {
        id: clipboardState
    }

    Services.OverlayController {
        id: notificationCenterState
    }

    Services.OverlayController {
        id: trayState
    }

    Services.OverlayController {
        id: sessionMenuState
    }

    Services.ClipboardService {
        id: sharedClipboard

        userConfig: configuration
        active: clipboardState.anyOpen
    }

    Services.BrightnessService {
        id: sharedBrightness

        userConfig: configuration
        active: quickPanelState.anyOpen
    }

    Services.AttentionService {
        id: sharedAttention
    }

    Services.SystemStats {
        id: sharedSystemStats

        active: quickPanelState.anyOpen || dashboardState.anyOpen
    }

    Services.SystemHealth {
        id: sharedSystemHealth

        active: dashboardState.anyOpen
    }

    Services.CalendarService {
        id: sharedCalendar

        clockService: sharedClock
    }

    Services.SessionService {
        id: sharedSession
    }

    Services.LauncherService {
        id: sharedLauncher

        userConfig: configuration
    }

    Services.LauncherController {
        id: launcherState
    }

    Services.WorkspaceService {
        id: sharedWorkspaces
    }

    Services.MediaService {
        id: sharedMedia
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: variant

            property var modelData

            Windows.TopReserveWindow {
                screen: variant.modelData
                theme: lotusTheme
            }

            Windows.TopLeftIsland {
                screen: variant.modelData
                theme: lotusTheme
                launcherService: sharedLauncher
                launcherController: launcherState
                workspaceService: sharedWorkspaces
                dashboardController: dashboardState
                clipboardController: clipboardState
                clipboardService: sharedClipboard
                notificationController: notificationCenterState
                panelController: quickPanelState
                trayService: sharedTray
                trayController: trayState
            }

            Windows.DashboardWindow {
                screen: variant.modelData
                theme: lotusTheme
                dashboardController: dashboardState
                systemStats: sharedSystemStats
                systemHealth: sharedSystemHealth
            }

            Windows.ClipboardWindow {
                screen: variant.modelData
                theme: lotusTheme
                clipboardController: clipboardState
                clipboardService: sharedClipboard
            }

            GlobalShortcut {
                name: "clipboardToggle"
                description: "Toggle the Lotus clipboard"
                onPressed: {
                    launcherState.close();
                    dashboardState.close();
                    notificationCenterState.close();
                    trayState.close();
                    sessionMenuState.close();
                    quickPanelState.closeAll();
                    clipboardState.toggle(variant.modelData.name);
                }
            }

            GlobalShortcut {
                name: "dashboardToggle"
                description: "Toggle the Lotus control desk"
                onPressed: {
                    launcherState.close();
                    clipboardState.close();
                    notificationCenterState.close();
                    trayState.close();
                    sessionMenuState.close();
                    quickPanelState.closeAll();
                    dashboardState.toggle(variant.modelData.name);
                }
            }

            GlobalShortcut {
                name: "launcherToggle"
                description: "Toggle the Lotus application launcher"
                onPressed: {
                    dashboardState.close();
                    clipboardState.close();
                    notificationCenterState.close();
                    trayState.close();
                    sessionMenuState.close();
                    quickPanelState.closeAll();
                    launcherState.toggle(variant.modelData.name);
                }
            }

            GlobalShortcut {
                name: "notificationToggle"
                description: "Toggle the Lotus notification center"
                onPressed: {
                    launcherState.close();
                    dashboardState.close();
                    clipboardState.close();
                    trayState.close();
                    sessionMenuState.close();
                    quickPanelState.closeAll();
                    notificationCenterState.toggle(variant.modelData.name);
                }
            }

            GlobalShortcut {
                name: "sessionMenuToggle"
                description: "Toggle the Lotus session menu"
                onPressed: {
                    launcherState.close();
                    dashboardState.close();
                    clipboardState.close();
                    notificationCenterState.close();
                    trayState.close();
                    quickPanelState.closeAll();
                    sessionMenuState.toggle(variant.modelData.name);
                }
            }

            Windows.ApplicationLauncherWindow {
                screen: variant.modelData
                theme: lotusTheme
                launcherService: sharedLauncher
                launcherController: launcherState
            }

            Windows.NotificationCenterWindow {
                screen: variant.modelData
                theme: lotusTheme
                notificationService: sharedNotifications
                notificationController: notificationCenterState
            }

            Windows.NotificationToastWindow {
                screen: variant.modelData
                theme: lotusTheme
                notificationService: sharedNotifications
            }

            Windows.TrayOverflowWindow {
                screen: variant.modelData
                theme: lotusTheme
                trayService: sharedTray
                trayController: trayState
            }

            Windows.SessionMenuWindow {
                screen: variant.modelData
                theme: lotusTheme
                sessionMenuController: sessionMenuState
                sessionService: sharedSession
            }

            Windows.TopCenterIsland {
                screen: variant.modelData
                theme: lotusTheme
                mediaService: sharedMedia
            }

            Windows.TopRightIsland {
                screen: variant.modelData
                theme: lotusTheme
                clockService: sharedClock
                audioService: sharedAudio
                networkService: sharedNetwork
                bluetoothService: sharedBluetooth
                notificationService: sharedNotifications
                notificationController: notificationCenterState
                trayController: trayState
                brightnessService: sharedBrightness
                systemStats: sharedSystemStats
                calendarService: sharedCalendar
                sessionService: sharedSession
                panelController: quickPanelState
                attentionService: sharedAttention
            }

        }

    }

}
