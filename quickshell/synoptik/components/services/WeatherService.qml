import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: weatherRoot

    // Zipcode or city query override from Config
    property string zipcode: ""

    // Output properties
    property string temp: "--"
    property string feelsLike: "--"
    property string desc: "Loading..."
    property string glyph: "cloud"
    property string areaName: ""
    property string humidity: "--"
    property string windSpeed: "--"
    property string uvIndex: "--"
    property bool isFetching: false
    property double lastFetchTime: 0

    function getTargetUrl() {
        let loc = "";
        if (zipcode && zipcode.toString().trim() !== "") {
            loc = zipcode.toString().trim();
        } else if (typeof Config !== "undefined" && Config.locationQuery) {
            loc = Config.locationQuery.toString().trim();
        }

        if (loc !== "") {
            let formattedLoc = loc.replace(/\s+/g, "+");
            return "https://wttr.in/" + formattedLoc + "?format=j1";
        }
        return "https://wttr.in/?format=j1";
    }

    function fetchWeather(force) {
        let urlStr = getTargetUrl();
        weatherRoot.isFetching = true;
        weatherFetcher.running = false;
        weatherFetcher.command = ["curl", "-s", "-L", "-H", "User-Agent: curl/7.68.0", urlStr];
        weatherFetcher.running = true;
    }

    onZipcodeChanged: {
        if (typeof Config !== "undefined" && Config.isLoaded) {
            lastFetchTime = 0;
            fetchWeather(true);
        }
    }

    property Process fetcherProcess: Process {
        id: weatherFetcher
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                weatherRoot.isFetching = false;
                let trimmed = this.text ? this.text.trim() : "";
                
                if (!trimmed.startsWith("{") && !trimmed.startsWith("[")) {
                    return;
                }

                try {
                    let data = JSON.parse(trimmed);
                    if (data.current_condition && data.current_condition.length > 0) {
                        let current = data.current_condition[0];
                        weatherRoot.temp = current.temp_F + "°F";
                        weatherRoot.feelsLike = current.FeelsLikeF + "°F";
                        weatherRoot.humidity = (current.humidity || "--") + "%";
                        weatherRoot.windSpeed = (current.windspeedMiles || "--") + " mph";
                        weatherRoot.uvIndex = current.uvIndex ? current.uvIndex.toString() : "--";
                        
                        // Parse Area / Location name
                        if (data.nearest_area && data.nearest_area.length > 0) {
                            let area = data.nearest_area[0];
                            let cityName = (area.areaName && area.areaName[0]) ? area.areaName[0].value : "";
                            let regionName = (area.region && area.region[0]) ? area.region[0].value : "";
                            if (cityName && regionName) {
                                weatherRoot.areaName = cityName + ", " + regionName;
                            } else if (cityName) {
                                weatherRoot.areaName = cityName;
                            }
                        }

                        let code = current.weatherCode ? current.weatherCode.toString() : "";
                        let rawDesc = (current.weatherDesc && current.weatherDesc[0]) ? current.weatherDesc[0].value : "";

                        let descMap = { 
                            "113": "Clear Sky", "116": "Partly Cloudy", "119": "Cloudy", "122": "Overcast",
                            "143": "Mist", "176": "Patchy Rain", "179": "Patchy Snow", "182": "Patchy Sleet",
                            "200": "Thunderstorms", "248": "Foggy", "260": "Freezing Fog", "263": "Light Drizzle",
                            "266": "Drizzle", "293": "Patchy Light Rain", "296": "Light Rain", "299": "Moderate Rain",
                            "302": "Moderate Rain", "305": "Heavy Rain", "308": "Heavy Rain", "353": "Light Showers",
                            "356": "Moderate / Heavy Rain", "359": "Torrential Rain", "386": "Rain with Thunder",
                            "389": "Heavy Rain & Thunder", "395": "Heavy Snow & Thunder",
                            "0": "Clear Sky", "1": "Mainly Clear", "2": "Partly Cloudy", "3": "Overcast", 
                            "45": "Foggy", "48": "Rime Fog", "51": "Light Drizzle", "53": "Moderate Drizzle", 
                            "55": "Dense Drizzle", "61": "Slight Rain", "63": "Moderate Rain", "65": "Heavy Rain", 
                            "71": "Light Snow", "73": "Moderate Snow", "75": "Heavy Snow", "80": "Light Showers", 
                            "85": "Light Snow Showers", "95": "Thunderstorm" 
                        };

                        let iconMap = { 
                            "113": "wb_sunny", "116": "partly_cloudy_day", "119": "cloud", "122": "cloud", 
                            "143": "foggy", "176": "rainy", "179": "ac_unit", "182": "ac_unit", "185": "ac_unit", 
                            "200": "thunderstorm", "227": "ac_unit", "230": "ac_unit", "248": "foggy", "260": "foggy", 
                            "263": "rainy", "266": "rainy", "281": "ac_unit", "284": "ac_unit", "293": "rainy", 
                            "296": "rainy", "299": "rainy", "302": "rainy", "305": "rainy", "308": "rainy", 
                            "311": "ac_unit", "314": "ac_unit", "317": "ac_unit", "320": "ac_unit", "323": "ac_unit", 
                            "326": "ac_unit", "329": "ac_unit", "332": "ac_unit", "335": "ac_unit", "338": "ac_unit", 
                            "350": "ac_unit", "353": "rainy", "356": "rainy", "359": "rainy", "362": "ac_unit", 
                            "365": "ac_unit", "368": "ac_unit", "371": "ac_unit", "374": "ac_unit", "377": "ac_unit", 
                            "386": "thunderstorm", "389": "thunderstorm", "392": "thunderstorm", "395": "thunderstorm", 
                            "0": "wb_sunny", "1": "partly_cloudy_day", "2": "partly_cloudy_day", "3": "cloud", 
                            "45": "foggy", "48": "foggy", "51": "rainy", "53": "rainy", "55": "rainy", 
                            "61": "rainy", "63": "rainy", "65": "rainy", "71": "ac_unit", "73": "ac_unit", 
                            "75": "ac_unit", "80": "rainy", "85": "ac_unit", "95": "thunderstorm" 
                        };
                        
                        weatherRoot.desc = rawDesc !== "" ? rawDesc : (descMap[code] || "Clear");

                        let targetGlyph = iconMap[code];
                        if (!targetGlyph) {
                            let lower = weatherRoot.desc.toLowerCase();
                            if (lower.includes("thunder")) targetGlyph = "thunderstorm";
                            else if (lower.includes("rain") || lower.includes("drizzle") || lower.includes("shower")) targetGlyph = "rainy";
                            else if (lower.includes("snow") || lower.includes("sleet") || lower.includes("blizzard") || lower.includes("ice")) targetGlyph = "ac_unit";
                            else if (lower.includes("fog") || lower.includes("mist") || lower.includes("haze")) targetGlyph = "foggy";
                            else if (lower.includes("sunny") || lower.includes("clear")) targetGlyph = "wb_sunny";
                            else if (lower.includes("cloud")) targetGlyph = "partly_cloudy_day";
                            else targetGlyph = "cloud";
                        }
                        weatherRoot.glyph = targetGlyph;
                        weatherRoot.lastFetchTime = Date.now();
                    }
                } catch(e) {
                    console.error("Failed to parse weather JSON:", e);
                }
            }
        }
    }
}
