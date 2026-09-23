pragma ComponentBehavior: Bound

import QtQuick
import "./"
import "../diaspora"
import "../weather"
import "../desktop"
import "../../"

// Decorative desktop-widget wrapper around the 2D shader globe.
Item {
    id: root

    readonly property real _size: Math.round(200 * UIScale.value)
    implicitWidth: root._size
    implicitHeight: root._size

    Globe2D {
        anchors.fill: parent
        interactive: Globe2DSettings.rotateMode === "manual" && !DesktopWidgetStore.configMode
        autoRotate: Globe2DSettings.rotateMode === "auto"
        autoRotateSpeedDegPerSec: 4
        points: LocationSharingService.locations
        initialLat: (LocationSharingService.optedIn && WeatherService.locationName !== "") ? WeatherService.latitude : 50.0
        initialLon: (LocationSharingService.optedIn && WeatherService.locationName !== "") ? WeatherService.longitude : 10.0
    }
}
