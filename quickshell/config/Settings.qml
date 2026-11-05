pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // === CLOCK ===
    property bool clockVisible: true
    property bool clock24h: true
    property bool clockShowSeconds: false
    property int clockX: 70
    property int clockY: 40

    // === CALENDAR ===
    property bool calendarVisible: true
    property int calendarX: 70
    property int calendarY: 230

    // === SYSTEM MONITOR ===
    property bool systemMonitorVisible: true
    property int systemMonitorX: 70
    property int systemMonitorY: 520

    // === WEATHER ===
    property bool weatherVisible: true
    property int weatherX: 1520
    property int weatherY: 40
    property string weatherCity: "London"
    property string weatherUnits: "celsius"  // "celsius" or "fahrenheit"
    property real weatherLat: 51.5074
    property real weatherLon: -0.1278

    // === MUSIC ===
    property bool musicVisible: true
    property int musicX: 1520
    property int musicY: 260

    // === NOTES ===
    property bool notesVisible: true
    property int notesX: 1520
    property int notesY: 500
    property int notesWidth: 320
    property int notesHeight: 270

    // === DESKTOP ICONS ===
    property bool desktopIconsVisible: true
    property int iconSize: 44
    property int iconSpacing: 14
    property int iconGridColumns: 6
    property int iconGridStartX: 410
    property int iconGridStartY: 40
    property var pinnedApps: [
        "firefox",
        "kitty",
        "caja",
        "spotify",
        "discord",
        "visual-studio-code",
        "brave",
        "btop",
        "rofi"
    ]

    // === DOCK ===
    property bool dockVisible: true
    property bool dockAutoHide: false
    property int dockIconSize: 38
    property int dockSpacing: 8
    property int dockMarginBottom: 16
    property int dockMarginLeft: 0  // 0 = Auto-center horizontally, >0 = Fixed left margin
    property var dockPinnedApps: [
        "firefox",
        "kitty",
        "caja",
        "spotify",
        "discord",
        "visual-studio-code",
        "rofi"
    ]

    // === THEME OVERRIDES ===
    property string accentColor: "#D71920"
    property real transparency: 0.88

    // === PERSISTENCE ===
    property string _settingsPath: Quickshell.env("HOME") + "/.local/share/nothing-desktop/settings.json"

    property var _fileView: FileView {
        id: fileView
        path: root._settingsPath
        preload: true
    }

    function save() {
        var data = {
            clockVisible: clockVisible, clock24h: clock24h, clockShowSeconds: clockShowSeconds,
            clockX: clockX, clockY: clockY,
            calendarVisible: calendarVisible, calendarX: calendarX, calendarY: calendarY,
            systemMonitorVisible: systemMonitorVisible,
            systemMonitorX: systemMonitorX, systemMonitorY: systemMonitorY,
            weatherVisible: weatherVisible, weatherX: weatherX, weatherY: weatherY,
            weatherCity: weatherCity, weatherUnits: weatherUnits,
            weatherLat: weatherLat, weatherLon: weatherLon,
            musicVisible: musicVisible, musicX: musicX, musicY: musicY,
            notesVisible: notesVisible, notesX: notesX, notesY: notesY,
            notesWidth: notesWidth, notesHeight: notesHeight,
            desktopIconsVisible: desktopIconsVisible, iconSize: iconSize, iconSpacing: iconSpacing,
            iconGridColumns: iconGridColumns,
            iconGridStartX: iconGridStartX, iconGridStartY: iconGridStartY,
            dockVisible: dockVisible, dockAutoHide: dockAutoHide,
            dockIconSize: dockIconSize, dockSpacing: dockSpacing,
            dockMarginBottom: dockMarginBottom, dockMarginLeft: dockMarginLeft,
            dockPinnedApps: dockPinnedApps, pinnedApps: pinnedApps,
            accentColor: accentColor, transparency: transparency
        };
        fileView.setText(JSON.stringify(data, null, 2));
    }

    function load() {
        var raw = fileView.text();
        if (!raw || raw.length === 0) return;
        try {
            var data = JSON.parse(raw);
            if (data.clockVisible !== undefined) clockVisible = data.clockVisible;
            if (data.clock24h !== undefined) clock24h = data.clock24h;
            if (data.clockShowSeconds !== undefined) clockShowSeconds = data.clockShowSeconds;
            if (data.clockX !== undefined) clockX = data.clockX;
            if (data.clockY !== undefined) clockY = data.clockY;
            if (data.calendarVisible !== undefined) calendarVisible = data.calendarVisible;
            if (data.calendarX !== undefined) calendarX = data.calendarX;
            if (data.calendarY !== undefined) calendarY = data.calendarY;
            if (data.systemMonitorVisible !== undefined) systemMonitorVisible = data.systemMonitorVisible;
            if (data.systemMonitorX !== undefined) systemMonitorX = data.systemMonitorX;
            if (data.systemMonitorY !== undefined) systemMonitorY = data.systemMonitorY;
            if (data.weatherVisible !== undefined) weatherVisible = data.weatherVisible;
            if (data.weatherX !== undefined) weatherX = data.weatherX;
            if (data.weatherY !== undefined) weatherY = data.weatherY;
            if (data.weatherCity !== undefined) weatherCity = data.weatherCity;
            if (data.weatherUnits !== undefined) weatherUnits = data.weatherUnits;
            if (data.weatherLat !== undefined) weatherLat = data.weatherLat;
            if (data.weatherLon !== undefined) weatherLon = data.weatherLon;
            if (data.musicVisible !== undefined) musicVisible = data.musicVisible;
            if (data.musicX !== undefined) musicX = data.musicX;
            if (data.musicY !== undefined) musicY = data.musicY;
            if (data.notesVisible !== undefined) notesVisible = data.notesVisible;
            if (data.notesX !== undefined) notesX = data.notesX;
            if (data.notesY !== undefined) notesY = data.notesY;
            if (data.notesWidth !== undefined) notesWidth = data.notesWidth;
            if (data.notesHeight !== undefined) notesHeight = data.notesHeight;
            if (data.desktopIconsVisible !== undefined) desktopIconsVisible = data.desktopIconsVisible;
            if (data.iconSize !== undefined) iconSize = data.iconSize;
            if (data.iconSpacing !== undefined) iconSpacing = data.iconSpacing;
            if (data.iconGridColumns !== undefined) iconGridColumns = data.iconGridColumns;
            if (data.iconGridStartX !== undefined) iconGridStartX = data.iconGridStartX;
            if (data.iconGridStartY !== undefined) iconGridStartY = data.iconGridStartY;
            if (data.dockVisible !== undefined) dockVisible = data.dockVisible;
            if (data.dockAutoHide !== undefined) dockAutoHide = data.dockAutoHide;
            if (data.dockIconSize !== undefined) dockIconSize = data.dockIconSize;
            if (data.dockSpacing !== undefined) dockSpacing = data.dockSpacing;
            if (data.dockMarginBottom !== undefined) dockMarginBottom = data.dockMarginBottom;
            if (data.dockMarginLeft !== undefined) dockMarginLeft = data.dockMarginLeft;
            if (data.dockPinnedApps !== undefined) dockPinnedApps = data.dockPinnedApps;
            if (data.pinnedApps !== undefined) pinnedApps = data.pinnedApps;
            if (data.accentColor !== undefined) accentColor = data.accentColor;
            if (data.transparency !== undefined) transparency = data.transparency;
        } catch(e) {
            console.warn("Nothing Desktop: Failed to parse settings:", e);
        }
    }

    Component.onCompleted: {
        load();
    }
}
