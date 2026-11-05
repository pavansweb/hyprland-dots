import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.styles
import qs.config
import qs.services

PanelWindow {
    id: dockRoot

    visible: Settings.dockVisible

    anchors {
        bottom: true
        left: true
    }

    readonly property int totalApps: ApplicationService.dockApps.length
    readonly property int appItemWidth: Settings.dockIconSize + Settings.dockSpacing + 12
    readonly property int fullWidth: (totalApps * appItemWidth) + (Theme.paddingLarge * 2)

    implicitWidth: Math.max(160, fullWidth)
    implicitHeight: Settings.dockAutoHide && !dockHover.containsMouse ? 6 : (Settings.dockIconSize + 22)

    // Auto-center dock horizontally if dockMarginLeft is 0 or negative
    readonly property int screenW: dockRoot.screen ? dockRoot.screen.width : 1920
    readonly property int calculatedLeft: Settings.dockMarginLeft > 0
        ? Settings.dockMarginLeft
        : Math.max(62, Math.round((screenW - implicitWidth) / 2))

    margins {
        bottom: Settings.dockMarginBottom
        left: dockRoot.calculatedLeft
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "nothing-desktop:dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: dockSurface
        anchors.fill: parent
        color: Theme.widgetBg
        border.color: Theme.border
        border.width: Theme.borderWidth
        radius: Theme.radiusLarge
        clip: true

        // Collapsed indicator when auto-hide is active
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: 3
            radius: 1.5
            color: Theme.accent
            visible: Settings.dockAutoHide && !dockHover.containsMouse
        }

        // Horizontal items row
        Row {
            anchors.centerIn: parent
            spacing: Settings.dockSpacing
            visible: !Settings.dockAutoHide || dockHover.containsMouse

            Repeater {
                model: ApplicationService.dockApps

                Item {
                    id: itemRoot
                    width: Settings.dockIconSize + 10
                    height: Settings.dockIconSize + 14

                    property var entry: modelData
                    property bool running: ApplicationService.isRunning(entry)
                    property bool hovered: itemMouse.containsMouse

                    // Subtle background highlight on hover
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius
                        color: itemRoot.hovered ? Theme.surfaceHover : "transparent"
                        border.color: itemRoot.hovered ? Theme.borderLight : "transparent"
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: Theme.animFast }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        // Icon container with slight scale up on hover
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            width: Settings.dockIconSize
                            height: Settings.dockIconSize
                            scale: itemRoot.hovered ? 1.12 : 1.0

                            Behavior on scale {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                            }

                            Image {
                                anchors.fill: parent
                                source: ApplicationService.resolveIcon(entry)
                                asynchronous: true
                                smooth: true
                                sourceSize: Qt.size(Settings.dockIconSize * 2, Settings.dockIconSize * 2)
                            }
                        }

                        // Running dot indicator
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 4
                            height: 4
                            radius: 2
                            color: itemRoot.running ? Theme.accent : "transparent"
                        }
                    }

                    // Tooltip text
                    Rectangle {
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: tooltipText.implicitWidth + 12
                        height: 22
                        radius: 3
                        color: Theme.surfaceSolid
                        border.color: Theme.border
                        border.width: 1
                        visible: itemRoot.hovered

                        Text {
                            id: tooltipText
                            anchors.centerIn: parent
                            text: entry ? entry.name : ""
                            font.family: Theme.bodyFont
                            font.pixelSize: 11
                            color: Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ApplicationService.activateApp(entry);
                        }
                    }
                }
            }
        }

        MouseArea {
            id: dockHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
}
