import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.styles
import qs.config
import qs.services

Item {
    id: sysRoot

    visible: Settings.systemMonitorVisible
    width: 320
    height: 260
    x: Settings.systemMonitorX
    y: Settings.systemMonitorY

    Connections {
        target: Settings
        function onSystemMonitorXChanged() { sysRoot.x = Settings.systemMonitorX; }
        function onSystemMonitorYChanged() { sysRoot.y = Settings.systemMonitorY; }
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
            drag.target: sysRoot
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: (sysRoot.parent ? sysRoot.parent.width : 1920) - sysRoot.width
            drag.maximumY: (sysRoot.parent ? sysRoot.parent.height : 1080) - sysRoot.height
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

            onReleased: {
                Settings.systemMonitorX = Math.round(sysRoot.x);
                Settings.systemMonitorY = Math.round(sysRoot.y);
                Settings.save();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            spacing: Theme.spacing

            // Header with drag handle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                RowLayout {
                    anchors.fill: parent
                    Text {
                        text: "SYSTEM MONITOR"
                        font.family: Theme.dotCapsFont
                        font.pixelSize: 12
                        font.letterSpacing: 2
                        color: headerDragArea.containsMouse ? Theme.text : Theme.textDim
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "⠿"
                        font.pixelSize: 12
                        color: headerDragArea.containsMouse ? Theme.accent : Theme.textDim
                        opacity: headerDragArea.containsMouse ? 1.0 : 0.4
                    }
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.accent
                    }
                }

                MouseArea {
                    id: headerDragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    drag.target: sysRoot
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.minimumY: 0
                    drag.maximumX: (sysRoot.parent ? sysRoot.parent.width : 1920) - sysRoot.width
                    drag.maximumY: (sysRoot.parent ? sysRoot.parent.height : 1080) - sysRoot.height
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    onReleased: {
                        Settings.systemMonitorX = Math.round(sysRoot.x);
                        Settings.systemMonitorY = Math.round(sysRoot.y);
                        Settings.save();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // CPU Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "CPU"
                        font.family: Theme.monoFont
                        font.pixelSize: 11
                        color: Theme.textSecondary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Math.round(SystemService.cpuUsage) + "%"
                        font.family: Theme.dotFont
                        font.pixelSize: 22
                        color: Theme.textPrimary
                    }
                }

                // Mini CPU History Graph (20 bars)
                Item {
                    Layout.fillWidth: true
                    height: 32

                    Row {
                        anchors.fill: parent
                        spacing: 2

                        Repeater {
                            model: SystemService.cpuHistory

                            Item {
                                width: Math.max(2, (parent.width - (20 * 2)) / 20)
                                height: parent.height

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(2, (modelData / 100) * parent.height)
                                    color: index === SystemService.cpuHistory.length - 1
                                           ? Theme.accent
                                           : (modelData > 80 ? Theme.accent : Theme.textDim)
                                    radius: 1
                                    opacity: 0.3 + (index / 20) * 0.7
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // RAM Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "RAM"
                        font.family: Theme.monoFont
                        font.pixelSize: 11
                        color: Theme.textSecondary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: SystemService.memUsed + " / " + SystemService.memTotal + " GB"
                        font.family: Theme.dotFont
                        font.pixelSize: 16
                        color: Theme.textPrimary
                    }
                }

                // RAM Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    color: Theme.surfaceHover
                    border.color: Theme.border
                    border.width: 1
                    radius: 2

                    Rectangle {
                        width: parent.width * (SystemService.memPercent / 100)
                        height: parent.height
                        color: SystemService.memPercent > 85 ? Theme.accent : Theme.textPrimary
                        radius: 2
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Uptime Section
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "UPTIME"
                    font.family: Theme.monoFont
                    font.pixelSize: 11
                    color: Theme.textDim
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: SystemService.uptime
                    font.family: Theme.monoFont
                    font.pixelSize: 13
                    color: Theme.textSecondary
                }
            }
        }
    }
}
