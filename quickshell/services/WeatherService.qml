pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

QtObject {
    id: root

    property string temperature: "--"
    property string condition: "Loading..."
    property string humidity: "--"
    property string windSpeed: "--"
    property string iconGlyph: "○"
    property string city: Settings.weatherCity
    property bool isOffline: false
    property string lastUpdated: ""

    // Decode WMO Weather interpretation codes
    function parseWeatherCode(code) {
        switch(code) {
            case 0:
                return { desc: "Clear Sky", icon: "󰖙" };
            case 1:
                return { desc: "Mainly Clear", icon: "󰖕" };
            case 2:
                return { desc: "Partly Cloudy", icon: "󰖕" };
            case 3:
                return { desc: "Overcast", icon: "󰖐" };
            case 45:
            case 48:
                return { desc: "Fog", icon: "󰖑" };
            case 51:
            case 53:
            case 55:
                return { desc: "Drizzle", icon: "󰖗" };
            case 61:
            case 63:
            case 65:
                return { desc: "Rain", icon: "󰖖" };
            case 71:
            case 73:
            case 75:
                return { desc: "Snow", icon: "󰖘" };
            case 80:
            case 81:
            case 82:
                return { desc: "Showers", icon: "󰖖" };
            case 95:
            case 96:
            case 99:
                return { desc: "Thunderstorm", icon: "󰖓" };
            default:
                return { desc: "Fair", icon: "󰖐" };
        }
    }

    function refresh() {
        if (!weatherProc.running) {
            var unitParam = Settings.weatherUnits === "fahrenheit"
                ? "temperature_unit=fahrenheit&wind_speed_unit=mph"
                : "temperature_unit=celsius&wind_speed_unit=kmh";
            var url = "https://api.open-meteo.com/v1/forecast?latitude=" + Settings.weatherLat +
                      "&longitude=" + Settings.weatherLon +
                      "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&" + unitParam;
            weatherProc.command = ["curl", "-s", "--max-time", "6", url];
            weatherProc.running = true;
        }
    }

    // Geocoding process to resolve city name if city changed
    property var _geoProc: Process {
        id: geoProc
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return;
                try {
                    var data = JSON.parse(text);
                    if (data && data.results && data.results.length > 0) {
                        var res = data.results[0];
                        Settings.weatherLat = res.latitude;
                        Settings.weatherLon = res.longitude;
                        Settings.save();
                        root.refresh();
                    }
                } catch(e) {
                    console.warn("Weather geocoding parse error:", e);
                }
            }
        }
    }

    function searchCity(cityName) {
        if (!geoProc.running) {
            var encoded = encodeURIComponent(cityName);
            geoProc.command = [
                "curl", "-s", "--max-time", "6",
                "https://geocoding-api.open-meteo.com/v1/search?name=" + encoded + "&count=1&language=en&format=json"
            ];
            geoProc.running = true;
        }
    }

    property var _weatherProc: Process {
        id: weatherProc
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) {
                    root.isOffline = true;
                    root.condition = "Offline";
                    return;
                }
                try {
                    var data = JSON.parse(text);
                    if (data && data.current) {
                        var curr = data.current;
                        var units = data.current_units || {};
                        var tempUnit = units.temperature_2m || "°C";
                        var windUnit = units.wind_speed_10m || "km/h";

                        root.temperature = Math.round(curr.temperature_2m) + tempUnit;
                        root.humidity = curr.relative_humidity_2m + "%";
                        root.windSpeed = curr.wind_speed_10m + " " + windUnit;

                        var info = root.parseWeatherCode(curr.weather_code);
                        root.condition = info.desc;
                        root.iconGlyph = info.icon;
                        root.isOffline = false;

                        var now = new Date();
                        root.lastUpdated = now.getHours().toString().padStart(2, '0') + ":" +
                                           now.getMinutes().toString().padStart(2, '0');
                    } else {
                        root.isOffline = true;
                        root.condition = "Unavailable";
                    }
                } catch(e) {
                    root.isOffline = true;
                    root.condition = "Offline";
                }
            }
        }
    }

    // Refresh every 15 minutes (900,000 ms)
    property var _timer: Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.refresh()
    }

    property var _conn: Connections {
        target: Settings
        function onWeatherCityChanged() {
            root.city = Settings.weatherCity;
            root.searchCity(Settings.weatherCity);
        }
        function onWeatherUnitsChanged() {
            root.refresh();
        }
    }

    Component.onCompleted: {
        refresh();
    }
}
