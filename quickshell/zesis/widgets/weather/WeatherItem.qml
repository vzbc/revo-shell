import QtQuick
import "../shared"
import "../../"

Item {
    id: root

    implicitWidth: barRow.implicitWidth + Math.round(14 * UIScale.value)
    implicitHeight: Math.round(30 * UIScale.value)

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible ? popup.close() : popup.open()
    }

    Row {
        id: barRow
        anchors.centerIn: parent
        spacing: Math.round(5 * UIScale.value)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.loading && WeatherService.weatherCode === 0 ? "󰖙" : WeatherService.weatherIcon(WeatherService.weatherCode, WeatherService.isDay)
            font.pixelSize: Math.round(15 * UIScale.value)
            color: (mouseArea.containsMouse || popup.visible) ? Colors.accent : Colors.text
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.loading && WeatherService.temperature === 0 ? "…" : WeatherService.temperature + "°"
            font.pixelSize: UIScale.fontSmall
            color: (mouseArea.containsMouse || popup.visible) ? Colors.accent : Colors.text
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }
    }

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(320 * UIScale.value)
        implicitHeight: Math.round(440 * UIScale.value)
        content: Component {
            WeatherReport {}
        }
    }
}
