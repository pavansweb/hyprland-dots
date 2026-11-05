pragma Singleton
import QtQuick
import qs.config

QtObject {
    // === CONFIGURABLE VIA SETTINGS ===
    property real surfaceOpacity: Settings.transparency
    readonly property color accent: Settings.accentColor
    readonly property color accentDim: Qt.rgba(0.843, 0.098, 0.125, 0.3)

    // === COLORS ===
    readonly property color background: "#0A0A0A"
    readonly property color surface: Qt.rgba(0.08, 0.08, 0.08, surfaceOpacity)
    readonly property color surfaceSolid: "#141414"
    readonly property color surfaceHover: "#1C1C1C"
    readonly property color surfaceActive: "#222222"
    readonly property color border: "#2A2A2A"
    readonly property color borderLight: "#333333"
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#999999"
    readonly property color textDim: "#555555"
    readonly property color widgetBg: Qt.rgba(0.06, 0.06, 0.06, surfaceOpacity)

    // === FONTS ===
    readonly property string dotFont: "Ndot 57"
    readonly property string dotCapsFont: "Ndot57Caps"
    readonly property string bodyFont: "Space Grotesk"
    readonly property string monoFont: "JetBrains Mono"

    // === DIMENSIONS ===
    readonly property int borderWidth: 1
    readonly property int radius: 4
    readonly property int radiusLarge: 8
    readonly property int padding: 12
    readonly property int paddingSmall: 6
    readonly property int paddingLarge: 16
    readonly property int spacing: 8
    readonly property int spacingSmall: 4
    readonly property int spacingLarge: 12

    // === ICON SIZES ===
    readonly property int iconSmall: 16
    readonly property int iconMedium: 24
    readonly property int iconLarge: 32
    readonly property int iconXLarge: 48

    // === ANIMATION ===
    readonly property int animFast: 120
    readonly property int animNormal: 200
    readonly property int animSlow: 350
}
