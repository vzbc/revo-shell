pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../clock"
import "../weather"
import "../sysmon"
import "../globe2d"
import "../power"
import "../../"

Singleton {
    id: root

    readonly property var entries: [
        {
            key: "desktop-clock",
            label: I18n.t("desktop.desktopClockLabel"),
            description: I18n.t("desktop.desktopClockDescription"),
            component: _desktopClockComp
        },
        {
            key: "bar-clock",
            label: I18n.t("desktop.barClockLabel"),
            description: I18n.t("desktop.barClockDescription"),
            component: _barClockComp
        },
        {
            key: "weather",
            label: I18n.t("desktop.weatherLabel"),
            description: I18n.t("desktop.weatherDescription"),
            component: _weatherComp
        },
        {
            key: "sysmon",
            label: I18n.t("desktop.sysmonLabel"),
            description: I18n.t("desktop.sysmonDescription"),
            component: _sysmonComp
        },
        {
            key: "globe2d",
            label: I18n.t("desktop.globe2dLabel"),
            description: I18n.t("desktop.globe2dDescription"),
            component: _globe2dComp
        },
        {
            key: "vending",
            label: I18n.t("desktop.vendingLabel"),
            description: I18n.t("desktop.vendingDescription"),
            component: _vendingComp
        }
    ]

    function componentFor(key) {
        for (var i = 0; i < entries.length; i++)
            if (entries[i].key === key)
                return entries[i].component;
        return null;
    }

    Component {
        id: _desktopClockComp
        DesktopClock {}
    }
    Component {
        id: _barClockComp
        Clock {}
    }
    Component {
        id: _weatherComp
        WeatherDisplay {}
    }

    Component {
        id: _sysmonComp
        SysMonDesktopWidget {}
    }
    Component {
        id: _globe2dComp
        Globe2DDesktopWidget {}
    }
    Component {
        id: _vendingComp
        VendingMachine {}
    }
}
