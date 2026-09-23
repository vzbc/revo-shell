import QtQuick
import "../../"

Item {
    id: root

    // Measure the fully-expanded font sizes unconditionally, implicitWidth/Height below
    // must have zero dependency on compact/narrow, even indirectly. See docs/qml-patterns.md #2.
    TextMetrics {
        id: fullIconMetrics
        font.pixelSize: Math.round(44 * UIScale.value)
        text: WeatherService.weatherIcon(WeatherService.weatherCode, WeatherService.isDay)
    }
    TextMetrics {
        id: fullTempMetrics
        font.pixelSize: Math.round(28 * UIScale.value)
        font.weight: Font.Light
        text: WeatherService.temperature + "°C"
    }

    // Width needed to show icon+temp+condition, without humidity/wind
    readonly property real _midWidth: fullIconMetrics.width + UIScale.spacingMd + Math.max(fullTempMetrics.width, conditionText.implicitWidth)
    // Width needed to show everything, including humidity/wind, this becomes implicitWidth
    readonly property real _infoWidth: Math.max(fullTempMetrics.width, conditionText.implicitWidth, humidityRow.implicitWidth)
    implicitWidth: fullIconMetrics.width + UIScale.spacingMd + _infoWidth

    // Appears twice below, the temp-condition gap and the condition-humidity gap
    readonly property real _colSpacing: Math.round(2 * UIScale.value)
    // Height needed for icon+temp+condition, without humidity/wind.
    readonly property real _midHeight: Math.max(fullIconMetrics.height, fullTempMetrics.height + _colSpacing + conditionText.implicitHeight)
    // Height needed for everything, including humidity/wind, this becomes implicitHeight
    readonly property real _infoHeight: fullTempMetrics.height + _colSpacing + conditionText.implicitHeight + _colSpacing + humidityRow.implicitHeight
    implicitHeight: Math.max(fullIconMetrics.height, _infoHeight)

    // Below full size, humidity/wind doesn't fit (compact), below mid size, not even the
    // condition text fits (narrow). Width and height checked independently - either axis
    // running out of room should trigger the same collapse.
    readonly property bool compact: (width > 0 && width < root.implicitWidth - 1) || (height > 0 && height < root.implicitHeight - 1)
    readonly property bool narrow: (width > 0 && width < root._midWidth - 1) || (height > 0 && height < root._midHeight - 1)

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.narrow ? UIScale.spacingSm : UIScale.spacingMd

        Text {
            id: iconText
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.weatherIcon(WeatherService.weatherCode, WeatherService.isDay)
            font.pixelSize: Math.round((root.compact ? 30 : 44) * UIScale.value)
            color: Colors.text
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(2 * UIScale.value)

            Text {
                id: tempText
                text: WeatherService.temperature + "°C"
                font.pixelSize: Math.round((root.compact ? 20 : 28) * UIScale.value)
                font.weight: Font.Light
                color: Colors.text
            }

            Text {
                id: conditionText
                visible: !root.narrow
                text: WeatherService.conditionText(WeatherService.weatherCode)
                font.pixelSize: UIScale.fontCaption
                color: Colors.textDim
            }

            Row {
                id: humidityRow
                visible: !root.compact
                spacing: Math.round(10 * UIScale.value)

                Text {
                    text: "󰖌 " + WeatherService.humidity + "%"
                    font.pixelSize: UIScale.fontCaption
                    color: Colors.textDim
                }

                Text {
                    text: "󰖝 " + WeatherService.windspeed + " km/h"
                    font.pixelSize: UIScale.fontCaption
                    color: Colors.textDim
                }
            }
        }
    }
}
