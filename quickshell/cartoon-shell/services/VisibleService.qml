// components/PanelManager.qml
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick 2.15
import Quickshell
import qs.commons

Singleton {
    id: panelManager
    property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

    // Properties cho từng panel
    property bool launcher: false
    property bool setting: false
    property bool fullsetting: false
    property bool tray: false
    property bool listLauncher: false
    property bool keyboard: false

    property bool filedialog: false

    property bool cpu: false

    property bool lockscreen: false
    property bool packagePanel: false
    property bool keybind: false

    property bool ram: false

    property bool calendar: false

    property bool music: false

    property bool weather: false

    property bool shortcutMenu: false

    property bool flag: false

    property bool bluetooth: false

    property bool wifi: false

    property bool mixer: false

    property bool battery: false

    property bool dashboard: false

    property bool hasPanel: tray || packagePanel || wifi || flag || mixer || music || launcher || dashboard || battery || ram || cpu || calendar || weather || bluetooth

    property bool clock: Settings.clock.enableWidget // Giữ nguyên từ config

    // Signal khi có panel thay đổi trạng thái
    signal panelChanged(string panelName, bool visible)

    // Hàm mở một panel duy nhất (đóng tất cả panel khác)
    function openPanel(panelName) {
        closeAllPanels();

        switch (panelName) {
        case "launcher":
            launcher = true;
            break;
        case "cpu":
            cpu = true;
            break;
        case "ram":
            ram = true;
            break;
        case "calendar":
            calendar = true;
            break;
        case "music":
            music = true;
            break;
        case "weather":
            weather = true;
            break;
        case "flag":
            flag = true;
            break;
        case "bluetooth":
            bluetooth = true;
            break;
        case "wifi":
            wifi = true;
            break;
        case "mixer":
            mixer = true;
            break;
        case "battery":
            battery = true;
            break;
        case "dashboard":
            dashboard = true;
            break;
        case "clock":
            clock = true;
        case "tray":
            tray = true;
            break;
        }

        panelChanged(panelName, true);
    }

    // Hàm toggle panel
    function togglePanel(panelName) {
        switch (panelName) {
        case "shortcutMenu":
            {
                shortcutMenu = !shortcutMenu;
                break;
            }
        case "keyboard":
            {
                keyboard = !keyboard;
                break;
            }
        case "launcher":
            {
                if (launcher === false) {
                    cpu = false;
                    ram = false;
                    shortcutMenu = false;
                    weather = false;
                    if (isVertical) {
                        flag = false;
                        calendar = false;
                        mixer = false;
                        wifi = false;
                        bluetooth = false;
                    }
                    launcher = true;
                    listLauncher = true;
                    music = false;
                    dashboard = false;
                    keybind = false;
                } else {
                    launcher = false;
                    setting = false;
                    listLauncher = false;
                    fullsetting = false;
                }
                break;
            }
        case "cpu":
            {
                if (!cpu) {
                    ram = false;
                    cpu = true;
                    calendar = false;
                    flag = false;
                    music = false;
                    shortcutMenu = false;
                    weather = false;
                    launcher = false;
                    dashboard = false;
                    setting = false;
                    keybind = false;
                    fullsetting = false;
                } else {
                    cpu = false;
                }
                break;
            }
        case "ram":
            {
                if (!ram) {
                    ram = true;
                    cpu = false;
                    calendar = false;
                    flag = false;
                    music = false;
                    shortcutMenu = false;
                    weather = false;
                    launcher = false;
                    dashboard = false;
                    keybind = false;
                    setting = false;
                    fullsetting = false;
                } else {
                    ram = false;
                }
                break;
            }
        case "calendar":
            {
                if (!calendar) {
                    ram = false;
                    cpu = false;
                    shortcutMenu = false;
                    weather = false;
                    keybind = false;
                    flag = false;
                    music = false;
                    if (isVertical) {
                        launcher = false;
                        mixer = false;
                        wifi = false;
                        battery = false;
                        bluetooth = false;
                    }
                    calendar = true;
                    dashboard = false;
                    if (setting) {
                        launcher = false;
                    }
                    setting = false;
                    fullsetting = false;
                } else {
                    calendar = false;
                }
                break;
            }
        case "music":
            {
                if (music === false) {
                    calendar = false;
                    weather = false;
                    flag = false;
                    launcher = false;
                    shortcutMenu = false;
                    cpu = false;
                    if (isVertical) {
                        battery = false;
                        mixer = false;
                        wifi = false;
                        bluetooth = false;
                    }
                    keybind = false;
                    ram = false;
                    music = true;
                    setting = false;
                    fullsetting = false;
                    dashboard = false;
                } else {
                    music = false;
                }
                break;
            }
        case "weather":
            {
                if (!weather) {
                    flag = false;
                    calendar = false;
                    launcher = false;
                    weather = true;
                    mixer = false;
                    keybind = false;
                    wifi = false;
                    shortcutMenu = false;
                    bluetooth = false;
                    battery = false;
                    cpu = false;
                    music = false;
                    dashboard = false;
                    ram = false;
                    setting = false;
                    tray = false;
                    fullsetting = false;
                } else {
                    weather = false;
                }
                break;
            }
        case "flag":
            {
                if (!flag) {
                    calendar = false;
                    weather = false;
                    music = false;
                    flag = true;
                    shortcutMenu = false;
                    dashboard = false;
                    if (isVertical) {
                        launcher = false;
                        wifi = false;
                        mixer = false;
                        bluetooth = false;
                    }
                    ram = false;
                    cpu = false;
                    keybind = false;
                    setting = false;
                    fullsetting = false;
                } else {
                    flag = false;
                }
                break;
            }
        case "bluetooth":
            {
                if (!bluetooth) {
                    wifi = false;
                    mixer = false;
                    shortcutMenu = false;
                    battery = false;
                    tray = false;
                    bluetooth = true;
                    if (isVertical) {
                        launcher = false;
                        music = false;
                        flag = false;
                        calendar = false;
                    }
                    weather = false;
                    dashboard = false;
                    keybind = false;
                    setting = false;
                    fullsetting = false;
                } else {
                    bluetooth = false;
                }
                break;
            }
        case "wifi":
            {
                if (!wifi) {
                    wifi = true;
                    mixer = false;
                    bluetooth = false;
                    shortcutMenu = false;
                    battery = false;
                    keybind = false;
                    if (isVertical) {
                        music = false;
                        calendar = false;
                        launcher = false;
                        flag = false;
                    }
                    dashboard = false;
                    setting = false;
                    weather = false;
                    tray = false;
                    fullsetting = false;
                } else {
                    wifi = false;
                }
                break;
            }
        case "mixer":
            {
                if (!mixer) {
                    mixer = true;
                    shortcutMenu = false;
                    wifi = false;
                    bluetooth = false;
                    if (isVertical) {
                        launcher = false;
                        music = false;
                        calendar = false;
                        flag = false;
                    }
                    battery = false;
                    dashboard = false;
                    setting = false;
                    keybind = false;
                    tray = false;
                    weather = false;
                    fullsetting = false;
                } else {
                    mixer = false;
                }
                break;
            }
        case "battery":
            {
                if (!battery) {
                    mixer = false;
                    bluetooth = false;
                    shortcutMenu = false;
                    wifi = false;
                    battery = true;
                    dashboard = false;
                    tray = false;
                    keybind = false;
                    weather = false;
                    if (isVertical) {
                        launcher = false;
                        music = false;
                        calendar = false;
                    }
                    setting = false;
                    fullsetting = false;
                } else {
                    battery = false;
                }
                break;
            }
        case "packagePanel":
            {
                if (!packagePanel) {
                    launcher = false;
                    battery = false;
                    shortcutMenu = false;
                    wifi = false;
                    bluetooth = false;
                    mixer = false;
                    calendar = false;
                    cpu = false;
                    ram = false;
                    flag = false;
                    keybind = false;
                    music = false;
                    weather = false;
                    packagePanel = true;
                    setting = false;
                    dashboard = false;
                    fullsetting = false;
                } else {
                    packagePanel = false;
                }
                break;
            }
        case "dashboard":
            {
                if (!dashboard) {
                    launcher = false;
                    battery = false;
                    shortcutMenu = false;
                    wifi = false;
                    bluetooth = false;
                    mixer = false;
                    calendar = false;
                    cpu = false;
                    packagePanel = false;
                    ram = false;
                    flag = false;
                    music = false;
                    weather = false;
                    dashboard = true;
                    keybind = false;
                    setting = false;
                    fullsetting = false;
                } else {
                    dashboard = false;
                }
                break;
            }
        case "keybind":
            {
                if (!keybind) {
                    launcher = false;
                    battery = false;
                    wifi = false;
                    shortcutMenu = false;
                    bluetooth = false;
                    mixer = false;
                    calendar = false;
                    cpu = false;
                    packagePanel = false;
                    ram = false;
                    flag = false;
                    music = false;
                    weather = false;
                    dashboard = false;
                    setting = false;
                    fullsetting = false;
                    keybind = true;
                } else {
                    keybind = false;
                }
                break;
            }
        case "tray":
            {
                if (!tray) {
                    tray = true;
                    wifi = false;
                    mixer = false;
                    bluetooth = false;
                    shortcutMenu = false;
                    battery = false;
                    weather = false;
                    dashboard = false;
                } else {
                    tray = false;
                }
            }
        case "setting":
            {
                calendar = false;
                flag = false;
                setting = true;
                shortcutMenu = false;
                keybind = false;
                break;
            }
        case "fullsetting":
            {
                fullsetting = !fullsetting;
                shortcutMenu = false;
                break;
            }
        case "filedialog":
            {
                filedialog = !filedialog;
                shortcutMenu = false;
                break;
            }
        case "listLauncher":
            {
                setting = false;
                shortcutMenu = false;
                break;
            }
        }

        panelChanged(panelName, getPanelVisible(panelName));
    }

    // Hàm đóng tất cả panel
    function closeAllPanels() {
        launcher = false;
        shortcutMenu = false;
        cpu = false;
        ram = false;
        calendar = false;
        music = false;
        weather = false;
        flag = false;
        tray = false;
        bluetooth = false;
        wifi = false;
        mixer = false;
        battery = false;
        dashboard = false;
        setting = false;
        fullsetting = false;
        packagePanel = false;
        filedialog = false;
        // Không đóng clock panel vì nó được điều khiển bởi config
    }

    // Hàm lấy trạng thái panel
    function getPanelVisible(panelName) {
        switch (panelName) {
        case "hasPanel":
            return hasPanel;
        case "launcher":
            return launcher;
        case "shortcutMenu":
            return shortcutMenu;
        case "cpu":
            return cpu;
        case "ram":
            return ram;
        case "calendar":
            return calendar;
        case "music":
            return music;
        case "weather":
            return weather;
        case "flag":
            return flag;
        case "bluetooth":
            return bluetooth;
        case "wifi":
            return wifi;
        case "mixer":
            return mixer;
        case "battery":
            return battery;
        case "dashboard":
            return dashboard;
        case "clock":
            return clock;
        case "filedialog":
            return filedialog;
        default:
            return false;
        }
    }
}
