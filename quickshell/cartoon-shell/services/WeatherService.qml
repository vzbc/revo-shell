pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
  id: root

  // Properties
  property string apiKey: Settings.weather.keyApi
  property string location: Settings.weather.location
  property string lang: Settings.general.lang || "vi"
  property string errorMessage: ""
  property var dataModel: null

  // Process lấy weather forecast
  Process {
    id: weatherProcess
    running: false

    stdout: StdioCollector {
      onTextChanged: {
        try {
          root.dataModel = JSON.parse(text)
        } catch (e) {
          console.log("JSON parse error:", e)
        }
      }
    }
  }

  function getWeatherIcon(code, isDay) {
    code = Number(code)

    const basePath = "weather/icon_weather_status"

    if (code === 1000)
    return isDay ? `${basePath}/sun.png` : `${basePath}/night.png`

    if (code === 1003)
    return isDay ? `${basePath}/cloudy_sunny.png` : `${basePath}/cloudy_night.png`

    if ([1006, 1009].includes(code))
    return `${basePath}/cloudy.png`

    if ([1030].includes(code))
    return `${basePath}/mist.png`

    if ([1135, 1147].includes(code))
    return `${basePath}/fog.png`

    if ((code >= 1063 && code <= 1195) || (code >= 1198 && code <= 1201))
    return `${basePath}/rain.png`

    if (code >= 1204 && code <= 1264)
    return `${basePath}/snowy.png`

    if (code >= 1273 && code <= 1282)
    return `${basePath}/thunder.png`

    return `${basePath}/rainbow.png`
  }

  function refresh() {
    root.updateWeather()
  }
  function updateWeather() {
    if (root.apiKey === "" || root.apiKey === undefined) {
      root.errorMessage = "Vui lòng nhập API key"
      root.temperature = "No API"
      root.condition = "Chưa có key"
      return
    }

    if (!root.location || root.location === "") {
      root.errorMessage = "Vui lòng nhập địa điểm"
      return
    }

    root.errorMessage = ""

    const url = `https://api.weatherapi.com/v1/forecast.json?key=${root.apiKey}&q=${encodeURIComponent(root.location)}&days=3&lang=${root.lang}`
    weatherProcess.command = ["curl", "-s", url]
    weatherProcess.running = true
  }

  Timer {
    interval: 1800000 // 30 minutes
    running: true
    repeat: true
    onTriggered: {
      if (root.apiKey !== "" && root.location !== "") {
        root.updateWeather()
      }
    }
  }

  // Listen for settings changes

  Component.onCompleted: {
    root.updateWeather()
  }
}
