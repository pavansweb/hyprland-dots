import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.styles
import qs.config

Item {
    id: notesRoot

    visible: Settings.notesVisible
    width: Settings.notesWidth
    height: Settings.notesHeight
    x: Settings.notesX
    y: Settings.notesY

    Connections {
        target: Settings
        function onNotesXChanged() { notesRoot.x = Settings.notesX; }
        function onNotesYChanged() { notesRoot.y = Settings.notesY; }
    }

    property var notesList: [
        { title: "Note 1", content: "Welcome to Nothing Desktop.\nType here to take notes..." }
    ]
    property int currentIndex: 0
    property string notesPath: Quickshell.env("HOME") + "/.local/share/nothing-desktop/notes.json"

    FileView {
        id: notesFile
        path: notesRoot.notesPath
        preload: true
        onLoaded: {
            notesRoot.loadNotes();
        }
    }

    function loadNotes() {
        var raw = notesFile.text();
        if (!raw || raw.trim().length === 0) return;
        try {
            var data = JSON.parse(raw);
            if (Array.isArray(data) && data.length > 0) {
                notesRoot.notesList = data;
                if (notesRoot.currentIndex >= data.length) {
                    notesRoot.currentIndex = 0;
                }
                textArea.text = notesRoot.notesList[notesRoot.currentIndex].content || "";
            }
        } catch(e) {
            console.warn("Failed to parse notes.json:", e);
        }
    }

    function saveNotes() {
        if (notesRoot.currentIndex < notesRoot.notesList.length) {
            notesRoot.notesList[notesRoot.currentIndex].content = textArea.text;
        }
        var json = JSON.stringify(notesRoot.notesList, null, 2);
        notesFile.setText(json);
    }

    Timer {
        id: autoSaveTimer
        interval: 800
        repeat: false
        onTriggered: notesRoot.saveNotes()
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
            drag.target: notesRoot
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: (notesRoot.parent ? notesRoot.parent.width : 1920) - notesRoot.width
            drag.maximumY: (notesRoot.parent ? notesRoot.parent.height : 1080) - notesRoot.height
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

            onReleased: {
                Settings.notesX = Math.round(notesRoot.x);
                Settings.notesY = Math.round(notesRoot.y);
                Settings.save();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            spacing: Theme.spacingSmall

            // Header & Note Tabs
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Item {
                    width: 70
                    height: 22

                    RowLayout {
                        anchors.fill: parent
                        Text {
                            text: "NOTES"
                            font.family: Theme.dotCapsFont
                            font.pixelSize: 12
                            font.letterSpacing: 2
                            color: titleDragArea.containsMouse ? Theme.text : Theme.textDim
                        }
                        Text {
                            text: "⠿"
                            font.pixelSize: 11
                            color: titleDragArea.containsMouse ? Theme.accent : Theme.textDim
                            opacity: titleDragArea.containsMouse ? 1.0 : 0.4
                        }
                    }

                    MouseArea {
                        id: titleDragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        drag.target: notesRoot
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.minimumY: 0
                        drag.maximumX: (notesRoot.parent ? notesRoot.parent.width : 1920) - notesRoot.width
                        drag.maximumY: (notesRoot.parent ? notesRoot.parent.height : 1080) - notesRoot.height
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                        onReleased: {
                            Settings.notesX = Math.round(notesRoot.x);
                            Settings.notesY = Math.round(notesRoot.y);
                            Settings.save();
                        }
                    }
                }

                Item { width: 4 }

                // Tabs for notes
                Row {
                    spacing: 4
                    Repeater {
                        model: notesRoot.notesList.length

                        Rectangle {
                            width: 24
                            height: 22
                            radius: 3
                            color: notesRoot.currentIndex === index ? Theme.accent : Theme.surfaceHover
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: (index + 1).toString()
                                font.family: Theme.monoFont
                                font.pixelSize: 11
                                color: notesRoot.currentIndex === index ? "#FFFFFF" : Theme.textSecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    notesRoot.saveNotes();
                                    notesRoot.currentIndex = index;
                                    textArea.text = notesRoot.notesList[index].content || "";
                                }
                            }
                        }
                    }
                }

                // Add note button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 3
                    color: addMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.family: Theme.bodyFont
                        font.pixelSize: 14
                        color: Theme.textSecondary
                    }

                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            notesRoot.saveNotes();
                            var newNotes = notesRoot.notesList.slice();
                            newNotes.push({ title: "Note " + (newNotes.length + 1), content: "" });
                            notesRoot.notesList = newNotes;
                            notesRoot.currentIndex = newNotes.length - 1;
                            textArea.text = "";
                            notesRoot.saveNotes();
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Delete current note button (if more than 1)
                Rectangle {
                    width: 22
                    height: 22
                    radius: 3
                    visible: notesRoot.notesList.length > 1
                    color: delMouse.containsMouse ? Theme.accent : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.family: Theme.bodyFont
                        font.pixelSize: 14
                        color: delMouse.containsMouse ? "#FFFFFF" : Theme.textDim
                    }

                    MouseArea {
                        id: delMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var newNotes = notesRoot.notesList.slice();
                            newNotes.splice(notesRoot.currentIndex, 1);
                            notesRoot.notesList = newNotes;
                            if (notesRoot.currentIndex >= newNotes.length) {
                                notesRoot.currentIndex = newNotes.length - 1;
                            }
                            textArea.text = notesRoot.notesList[notesRoot.currentIndex].content || "";
                            notesRoot.saveNotes();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Editable Text Area
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    id: textArea
                    text: notesRoot.notesList[notesRoot.currentIndex] ? notesRoot.notesList[notesRoot.currentIndex].content : ""
                    font.family: Theme.monoFont
                    font.pixelSize: 13
                    color: Theme.textPrimary
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    background: null
                    padding: 4

                    onTextChanged: {
                        autoSaveTimer.restart();
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        loadNotes();
    }
}
