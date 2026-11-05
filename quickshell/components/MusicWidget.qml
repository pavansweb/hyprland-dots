import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.styles
import qs.config
import qs.services

Item {
    id: musicRoot

    visible: Settings.musicVisible
    width: 320
    height: 220
    x: Settings.musicX
    y: Settings.musicY

    Connections {
        target: Settings
        function onMusicXChanged() { musicRoot.x = Settings.musicX; }
        function onMusicYChanged() { musicRoot.y = Settings.musicY; }
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
            drag.target: musicRoot
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: (musicRoot.parent ? musicRoot.parent.width : 1920) - musicRoot.width
            drag.maximumY: (musicRoot.parent ? musicRoot.parent.height : 1080) - musicRoot.height
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

            onReleased: {
                Settings.musicX = Math.round(musicRoot.x);
                Settings.musicY = Math.round(musicRoot.y);
                Settings.save();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            spacing: Theme.spacing

            // Top Header: Label & Player Name & drag handle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                RowLayout {
                    anchors.fill: parent

                    Text {
                        text: (MusicService.identity || "MEDIA").toUpperCase()
                        font.family: Theme.dotCapsFont
                        font.pixelSize: 12
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

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: MusicService.isPlaying ? Theme.accent : Theme.textDim
                    }
                }

                MouseArea {
                    id: headerDragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    drag.target: musicRoot
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.minimumY: 0
                    drag.maximumX: (musicRoot.parent ? musicRoot.parent.width : 1920) - musicRoot.width
                    drag.maximumY: (musicRoot.parent ? musicRoot.parent.height : 1080) - musicRoot.height
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    onReleased: {
                        Settings.musicX = Math.round(musicRoot.x);
                        Settings.musicY = Math.round(musicRoot.y);
                        Settings.save();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Track Details + Artwork
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingLarge

                // Album Art or Placeholder
                Rectangle {
                    width: 64
                    height: 64
                    radius: Theme.radius
                    color: Theme.surfaceHover
                    border.color: Theme.border
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: MusicService.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: MusicService.artUrl.length > 0
                        asynchronous: true
                    }

                    // Placeholder if no art
                    Text {
                        anchors.centerIn: parent
                        text: MusicService.isPlaying ? "♪" : "■"
                        font.family: Theme.bodyFont
                        font.pixelSize: 24
                        color: Theme.textDim
                        visible: MusicService.artUrl.length === 0
                    }
                }

                // Title & Artist
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: MusicService.title
                        font.family: Theme.bodyFont
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        Layout.fillWidth: true
                        text: MusicService.artist
                        font.family: Theme.bodyFont
                        font.pixelSize: 13
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        Layout.fillWidth: true
                        text: MusicService.album
                        font.family: Theme.monoFont
                        font.pixelSize: 10
                        color: Theme.textDim
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        visible: MusicService.album.length > 0
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                Item { Layout.fillWidth: true }

                // Prev Button
                Rectangle {
                    width: 36
                    height: 36
                    radius: Theme.radius
                    color: prevMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: prevMouse.containsMouse ? Theme.borderLight : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "⏮"
                        font.pixelSize: 14
                        color: prevMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MusicService.previous()
                    }
                }

                Item { width: 16 }

                // Play / Pause Button
                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: playMouse.containsMouse ? Theme.accent : Theme.surfaceHover
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: MusicService.isPlaying ? "⏸" : "▶"
                        font.pixelSize: 16
                        color: playMouse.containsMouse ? "#FFFFFF" : Theme.textPrimary
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MusicService.togglePlay()
                    }
                }

                Item { width: 16 }

                // Next Button
                Rectangle {
                    width: 36
                    height: 36
                    radius: Theme.radius
                    color: nextMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: nextMouse.containsMouse ? Theme.borderLight : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "⏭"
                        font.pixelSize: 14
                        color: nextMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MusicService.next()
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
