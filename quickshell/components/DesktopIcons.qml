import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.styles
import qs.config
import qs.services

Item {
    id: desktopIconsRoot

    visible: Settings.desktopIconsVisible
    x: Settings.iconGridStartX
    y: Settings.iconGridStartY

    Connections {
        target: Settings
        function onIconGridStartXChanged() { desktopIconsRoot.x = Settings.iconGridStartX; }
        function onIconGridStartYChanged() { desktopIconsRoot.y = Settings.iconGridStartY; }
    }

    readonly property int colWidth: 100
    readonly property int rowHeight: 84

    width: (Settings.iconGridColumns * colWidth) + (Theme.paddingLarge * 2)

    // Dynamic height based on rows needed
    readonly property int numRows: Math.max(1, Math.ceil(desktopIconsRoot.currentList.length / Settings.iconGridColumns))
    height: Math.min(460, Math.max(160, (numRows * rowHeight) + 80))

    Behavior on height {
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    property bool showAll: false
    property string searchQuery: ""

    // Current apps to display
    readonly property var currentList: {
        var base = showAll ? ApplicationService.allApps : ApplicationService.pinnedApps;
        if (!searchQuery || searchQuery.trim().length === 0) {
            return base;
        }
        var q = searchQuery.toLowerCase().trim();
        return base.filter(function(app) {
            return (app.name && app.name.toLowerCase().indexOf(q) !== -1) ||
                   (app.id && app.id.toLowerCase().indexOf(q) !== -1);
        });
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
            drag.target: desktopIconsRoot
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: (desktopIconsRoot.parent ? desktopIconsRoot.parent.width : 1920) - desktopIconsRoot.width
            drag.maximumY: (desktopIconsRoot.parent ? desktopIconsRoot.parent.height : 1080) - desktopIconsRoot.height
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

            onReleased: {
                Settings.iconGridStartX = Math.round(desktopIconsRoot.x);
                Settings.iconGridStartY = Math.round(desktopIconsRoot.y);
                Settings.save();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            spacing: Theme.spacing

            // Header: Category switch & Search & Drag handle
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Pinned tab button
                Rectangle {
                    width: 76
                    height: 26
                    radius: 3
                    color: !desktopIconsRoot.showAll ? Theme.accent : Theme.surfaceHover
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "PINNED"
                        font.family: Theme.dotCapsFont
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        color: !desktopIconsRoot.showAll ? "#FFFFFF" : Theme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            desktopIconsRoot.showAll = false;
                        }
                    }
                }

                // All Apps tab button
                Rectangle {
                    width: 84
                    height: 26
                    radius: 3
                    color: desktopIconsRoot.showAll ? Theme.accent : Theme.surfaceHover
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "ALL APPS"
                        font.family: Theme.dotCapsFont
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        color: desktopIconsRoot.showAll ? "#FFFFFF" : Theme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            desktopIconsRoot.showAll = true;
                        }
                    }
                }

                // Drag handle area in header spacer
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "⠿"
                            font.pixelSize: 12
                            color: headerDragArea.containsMouse ? Theme.accent : Theme.textDim
                            opacity: headerDragArea.containsMouse ? 1.0 : 0.4
                        }
                        Text {
                            text: "APPS"
                            font.family: Theme.dotCapsFont
                            font.pixelSize: 10
                            font.letterSpacing: 1
                            color: headerDragArea.containsMouse ? Theme.textPrimary : Theme.textDim
                            opacity: headerDragArea.containsMouse ? 0.9 : 0.4
                        }
                    }

                    MouseArea {
                        id: headerDragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        drag.target: desktopIconsRoot
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.minimumY: 0
                        drag.maximumX: (desktopIconsRoot.parent ? desktopIconsRoot.parent.width : 1920) - desktopIconsRoot.width
                        drag.maximumY: (desktopIconsRoot.parent ? desktopIconsRoot.parent.height : 1080) - desktopIconsRoot.height
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                        onReleased: {
                            Settings.iconGridStartX = Math.round(desktopIconsRoot.x);
                            Settings.iconGridStartY = Math.round(desktopIconsRoot.y);
                            Settings.save();
                        }
                    }
                }

                // Search input when browsing
                Rectangle {
                    width: 160
                    height: 26
                    radius: 3
                    color: Theme.surfaceHover
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 4

                        Text {
                            text: "⌕"
                            font.family: Theme.bodyFont
                            font.pixelSize: 13
                            color: Theme.textDim
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Theme.monoFont
                            font.pixelSize: 11
                            color: Theme.textPrimary
                            selectByMouse: true
                            clip: true

                            Text {
                                text: "Filter apps..."
                                font.family: Theme.monoFont
                                font.pixelSize: 11
                                color: Theme.textDim
                                visible: !searchInput.text && !searchInput.activeFocus
                            }

                            onTextChanged: {
                                desktopIconsRoot.searchQuery = text;
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

            // Grid of Applications
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                GridView {
                    id: grid
                    anchors.fill: parent
                    cellWidth: desktopIconsRoot.colWidth
                    cellHeight: desktopIconsRoot.rowHeight
                    model: desktopIconsRoot.currentList

                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight

                        property var entry: modelData
                        property bool running: ApplicationService.isRunning(entry)

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: Theme.radius
                            color: itemMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            border.color: itemMouse.containsMouse ? Theme.borderLight : "transparent"
                            border.width: 1

                            Behavior on color {
                                ColorAnimation { duration: Theme.animFast }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                // Application Icon
                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: Settings.iconSize
                                    height: Settings.iconSize

                                    Image {
                                        anchors.fill: parent
                                        source: ApplicationService.resolveIcon(entry)
                                        asynchronous: true
                                        smooth: true
                                        sourceSize: Qt.size(Settings.iconSize * 2, Settings.iconSize * 2)
                                    }

                                    // Running dot
                                    Rectangle {
                                        width: 5
                                        height: 5
                                        radius: 2.5
                                        color: Theme.accent
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: running
                                    }
                                }

                                // Application Name
                                Text {
                                    Layout.preferredWidth: grid.cellWidth - 12
                                    text: entry ? entry.name : ""
                                    font.family: Theme.bodyFont
                                    font.pixelSize: 11
                                    color: itemMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
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
            }
        }
    }
}
