import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.styles
import qs.config
import qs.services

Item {
    id: weatherRoot

    visible: Settings.weatherVisible
    width: 320
    height: 220
    x: Settings.weatherX
    y: Settings.weatherY

    Connections {
        target: Settings
        function onWeatherXChanged() { weatherRoot.x = Settings.weatherX; }
        function onWeatherYChanged() { weatherRoot.y = Settings.weatherY; }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.widgetBg
        border.color: Theme.border
        border.width: Theme.borderWidth
        radius: Theme.radius

        // Background drag: catches clicks on empty space behind items
        MouseArea {
            anchors.fill: parent
            z: -1
            drag.target: weatherRoot
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: (weatherRoot.parent ? weatherRoot.parent.width : 1920) - weatherRoot.width
            drag.maximumY: (weatherRoot.parent ? weatherRoot.parent.height : 1080) - weatherRoot.height
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

            onReleased: {
                Settings.weatherX = Math.round(weatherRoot.x);
                Settings.weatherY = Math.round(weatherRoot.y);
                Settings.save();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            spacing: Theme.spacing

            // Top Header: City & Status indicator & drag handle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                RowLayout {
                    anchors.fill: parent

                    Text {
                        text: (WeatherService.city || "WEATHER").toUpperCase()
                        font.family: Theme.dotCapsFont
                        font.pixelSize: 13
                        font.letterSpacing: 2
                        color: headerDragArea.containsMouse ? Theme.text : Theme.textDim
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "⠿"
                        font.pixelSize: 12
                        color: headerDragArea.containsMouse ? Theme.accent : Theme.textDim
                        opacity: headerDragArea.containsMouse ? 1.0 : 0.4
                    }

                    // Refresh indicator / dot (clickable to refresh)
                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: "transparent"
                        border.color: WeatherService.isOffline ? Theme.textDim : Theme.accent
                        border.width: 1

                        Rectangle {
                            anchors.centerIn: parent
                            width: 6
                            height: 6
                            radius: 3
                            color: WeatherService.isOffline ? Theme.textDim : Theme.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: WeatherService.refresh()
                        }
                    }
                }

                MouseArea {
                    id: headerDragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    drag.target: weatherRoot
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.minimumY: 0
                    drag.maximumX: (weatherRoot.parent ? weatherRoot.parent.width : 1920) - weatherRoot.width
                    drag.maximumY: (weatherRoot.parent ? weatherRoot.parent.height : 1080) - weatherRoot.height
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    onReleased: {
                        Settings.weatherX = Math.round(weatherRoot.x);
                        Settings.weatherY = Math.round(weatherRoot.y);
                        Settings.save();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Main Weather Display
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingLarge

                // Weather Icon / Glyph
                Text {
                    text: WeatherService.iconGlyph
                    font.family: Theme.bodyFont
                    font.pixelSize: 42
                    color: Theme.textPrimary
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Temperature in Ndot 57
                    Text {
                        text: WeatherService.temperature
                        font.family: Theme.dotFont
                        font.pixelSize: 36
                        color: Theme.textPrimary
                    }

                    // Condition text
                    Text {
                        text: WeatherService.condition
                        font.family: Theme.bodyFont
                        font.pixelSize: 14
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Details Footer: Humidity & Wind
            RowLayout {
                Layout.fillWidth: true

                // Humidity
                RowLayout {
                    spacing: 4
                    Text {
                        text: "HUMIDITY"
                        font.family: Theme.monoFont
                        font.pixelSize: 10
                        color: Theme.textDim
                    }
                    Text {
                        text: WeatherService.humidity
                        font.family: Theme.monoFont
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                // Wind
                RowLayout {
                    spacing: 4
                    Text {
                        text: "WIND"
                        font.family: Theme.monoFont
                        font.pixelSize: 10
                        color: Theme.textDim
                    }
                    Text {
                        text: WeatherService.windSpeed
                        font.family: Theme.monoFont
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                }
            }
        }
    }
}
