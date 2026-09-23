pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/weather.json"

    property string locationMode: config.locationMode   // "auto" | "manual"
    property string manualCity: config.manualCity

    property bool loading: false
    property string error: ""

    property string locationName: ""
    property real latitude: 0
    property real longitude: 0

    property real temperature: 0
    property int weatherCode: 0
    property bool isDay: true
    property real windspeed: 0
    property int humidity: 0

    property var hourly: []    // [{timeLabel, hour, temperature, weatherCode, precipProb}]
    property var daily: []     // [{label, weatherCode, tempMax, tempMin, precipProb}]

    readonly property int currentPrecipProb: hourly.length > 0 ? (hourly[0].precipProb || 0) : 0
    readonly property bool isRaining: {
        var rainCodes = [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82];
        return rainCodes.indexOf(weatherCode) >= 0 || currentPrecipProb >= 60;
    }

    Component.onCompleted: refresh()

    function refresh() {
        if (locationMode === "manual" && manualCity.trim().length > 0)
            _geocodeCity(manualCity.trim());
        else
            _fetchIpLocation();
    }

    function saveLocationMode(mode) {
        _writeConfig(mode, root.manualCity);
        root.locationMode = mode;
    }

    function saveManualCity(city) {
        _writeConfig(root.locationMode, city);
        root.manualCity = city;
    }

    function weatherIcon(code, day) {
        if (code === 0)
            return day ? "󰖙" : "󰖔";       // sunny / clear night
        if (code <= 2)
            return day ? "󰖕" : "󰖔";       // partly cloudy / clear night
        if (code === 3)
            return "󰖐";                    // overcast
        if (code <= 48)
            return "󰖑";                    // fog
        if (code <= 57)
            return "󰖗";                    // drizzle (rainy, light)
        if (code <= 67)
            return "󰖖";                    // rain (pouring)
        if (code <= 77)
            return "󰖘";                    // snow
        if (code <= 82)
            return "󰖗";                    // rain showers
        if (code <= 86)
            return "󰖘";                    // snow showers
        if (code === 95)
            return "󰖓";                    // thunderstorm
        return "󰖒";                        // thunderstorm with hail
    }

    function conditionText(code) {
        if (code === 0)
            return I18n.t("weather.clearSky");
        if (code === 1)
            return I18n.t("weather.mainlyClear");
        if (code === 2)
            return I18n.t("weather.partlyCloudy");
        if (code === 3)
            return I18n.t("weather.overcast");
        if (code <= 48)
            return I18n.t("weather.foggy");
        if (code <= 55)
            return I18n.t("weather.drizzle");
        if (code <= 57)
            return I18n.t("weather.freezingDrizzle");
        if (code <= 63)
            return I18n.t("weather.rain");
        if (code === 65)
            return I18n.t("weather.heavyRain");
        if (code <= 67)
            return I18n.t("weather.freezingRain");
        if (code <= 75)
            return I18n.t("weather.snow");
        if (code === 77)
            return I18n.t("weather.snowGrains");
        if (code <= 82)
            return I18n.t("weather.rainShowers");
        if (code <= 86)
            return I18n.t("weather.snowShowers");
        if (code === 95)
            return I18n.t("weather.thunderstorm");
        return I18n.t("weather.hailStorm");
    }

    function _fetchIpLocation() {
        root.loading = true;
        root.error = "";
        ipProc._buf = "";
        ipProc.running = false;
        ipProc.running = true;
    }

    function _geocodeCity(city) {
        root.loading = true;
        root.error = "";
        var encoded = city.replace(/'/g, "").replace(/ /g, "+");
        geocodeProc._buf = "";
        geocodeProc.command = ["sh", "-c", "curl -sf --max-time 8 'https://geocoding-api.open-meteo.com/v1/search?name=" + encoded + "&count=1&language=en&format=json'"];
        geocodeProc.running = false;
        geocodeProc.running = true;
    }

    function _fetchWeather(lat, lon, name) {
        root.locationName = name;
        root.latitude = lat;
        root.longitude = lon;
        var url = "https://api.open-meteo.com/v1/forecast" + "?latitude=" + lat.toFixed(4) + "&longitude=" + lon.toFixed(4) + "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,is_day" + "&hourly=temperature_2m,precipitation_probability,weathercode" + "&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_max" + "&forecast_days=7&timezone=auto";
        weatherProc._buf = "";
        weatherProc.command = ["sh", "-c", "curl -sf --max-time 10 '" + url + "'"];
        weatherProc.running = false;
        weatherProc.running = true;
    }

    function _parseWeather(data) {
        var cw = data.current;
        root.temperature = Math.round(cw.temperature_2m);
        root.weatherCode = cw.weather_code;
        root.isDay = cw.is_day === 1;
        root.windspeed = Math.round(cw.wind_speed_10m);
        root.humidity = Math.round(cw.relative_humidity_2m);

        // Find the index of the current hour in the hourly array.
        // cw.time is "YYYY-MM-DDTHH:MM"; hourly times share the same format.
        // Fall back to matching by date+hour prefix if exact string differs.
        var cwTime = cw.time;
        var times = data.hourly.time;
        var idx = 0;
        var cwPrefix = cwTime.substring(0, 13); // "YYYY-MM-DDTHH"
        for (var i = 0; i < times.length; i++) {
            if (times[i] === cwTime || times[i].substring(0, 13) === cwPrefix) {
                idx = i;
                break;
            }
        }

        // Next 24 hours
        var hourlyArr = [];
        var end = Math.min(idx + 24, times.length);
        for (var j = idx; j < end; j++) {
            var hour = parseInt(times[j].substring(11, 13));
            var label;
            if (hour === 0)
                label = "12am";
            else if (hour < 12)
                label = hour + "am";
            else if (hour === 12)
                label = "12pm";
            else
                label = (hour - 12) + "pm";
            hourlyArr.push({
                timeLabel: label,
                hour: hour,
                isCurrent: j === idx,
                temperature: Math.round(data.hourly.temperature_2m[j]),
                weatherCode: data.hourly.weathercode[j],
                precipProb: data.hourly.precipitation_probability[j] || 0
            });
        }
        root.hourly = hourlyArr;

        // 7-day daily
        var dayNames = I18n.t("weather.shortDayNames").split("|");
        var dailyArr = [];
        for (var k = 0; k < data.daily.time.length; k++) {
            var parts = data.daily.time[k].split("-");
            var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
            var dlabel;
            if (k === 0)
                dlabel = I18n.t("weather.today");
            else if (k === 1)
                dlabel = I18n.t("weather.tomorrow");
            else
                dlabel = dayNames[d.getDay()];
            dailyArr.push({
                label: dlabel,
                weatherCode: data.daily.weathercode[k],
                tempMax: Math.round(data.daily.temperature_2m_max[k]),
                tempMin: Math.round(data.daily.temperature_2m_min[k]),
                precipProb: data.daily.precipitation_probability_max[k] || 0
            });
        }
        root.daily = dailyArr;
    }

    function _writeConfig(mode, city) {
        var safe = s => s.replace(/'/g, "");
        var json = '{"locationMode":"' + safe(mode) + '","manualCity":"' + safe(city) + '"}';
        configWriteProc.command = ["sh", "-c", "mkdir -p '" + safe(root._configDir) + "' && printf '%s' '" + json + "' > '" + safe(root._configPath) + "'"];
        configWriteProc.running = false;
        configWriteProc.running = true;
    }

    // Processes

    Process {
        id: ipProc
        command: ["sh", "-c", "curl -sf --max-time 5 'https://ipinfo.io/json'"]
        property string _buf: ""
        stdout: SplitParser {
            onRead: data => ipProc._buf += data
        }
        onExited: code => {
            if (code !== 0) {
                root.loading = false;
                root.error = I18n.t("weather.locationDetectionFailed");
                return;
            }
            try {
                var data = JSON.parse(ipProc._buf);
                var loc = (data.loc || "0,0").split(",");
                root._fetchWeather(parseFloat(loc[0]), parseFloat(loc[1]), data.city || data.region || I18n.t("weather.unknownCity"));
            } catch (e) {
                root.loading = false;
                root.error = I18n.t("weather.couldNotParseLocation");
            }
        }
    }

    Process {
        id: geocodeProc
        property string _buf: ""
        stdout: SplitParser {
            onRead: data => geocodeProc._buf += data
        }
        onExited: code => {
            if (code !== 0) {
                root.loading = false;
                root.error = I18n.t("weather.geocodingFailed");
                return;
            }
            try {
                var data = JSON.parse(geocodeProc._buf);
                if (!data.results || data.results.length === 0) {
                    root.loading = false;
                    root.error = I18n.t("weather.cityNotFound");
                    return;
                }
                var r = data.results[0];
                root._fetchWeather(r.latitude, r.longitude, r.name + (r.country_code ? ", " + r.country_code : ""));
            } catch (e) {
                root.loading = false;
                root.error = I18n.t("weather.geocodeParseFailed");
            }
        }
    }

    Process {
        id: weatherProc
        property string _buf: ""
        stdout: SplitParser {
            onRead: data => weatherProc._buf += data
        }
        onExited: code => {
            if (code !== 0) {
                root.loading = false;
                root.error = I18n.t("weather.weatherFetchFailed");
                return;
            }
            try {
                var data = JSON.parse(weatherProc._buf);
                root._parseWeather(data);
                root.error = "";
                root.loading = false;
            } catch (e) {
                root.loading = false;
                root.error = I18n.t("weather.parseError");
                console.log("[WeatherService] parse error:", e);
            }
        }
    }

    Process {
        id: configWriteProc
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    JsonAdapter {
        id: config
        property string locationMode: "auto"
        property string manualCity: ""
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: config
        onFileChanged: reload()
    }
}
