import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.styles
import qs.config

Item {
    id: clockRoot

    visible: Settings.clockVisible
    width: 340
    height: 180
    x: Settings.clockX
    y: Settings.clockY

    Connections {
        target: Settings
        function onClockXChanged() { clockRoot.x = Settings.clockX; }
        function onClockYChanged() { clockRoot.y = Settings.clockY; }
    }

    property string currentTime: ""
    property string currentWeekday: ""
    property string currentDate: ""

    function updateClock() {
        var now = new Date();
        var hours = now.getHours();
        var minutes = now.getMinutes();
        var seconds = now.getSeconds();
        var ampm = "";

        if (!Settings.clock24h) {
            ampm = hours >= 12 ? " PM" : " AM";
            hours = hours % 12;
            if (hours === 0) hours = 12;
        }

        var hStr = hours.toString().padStart(2, '0');
        var mStr = minutes.toString().padStart(2, '0');

        if (Settings.clock24h) {
            currentTime = Settings.clockShowSeconds
                ? hStr + ":" + mStr + ":" + seconds.toString().padStart(2, '0')
                : hStr + ":" + mStr;
        } else {
            currentTime = Settings.clockShowSeconds
                ? hStr + ":" + mStr + ":" + seconds.toString().padStart(2, '0') + ampm
                : hStr + ":" + mStr + ampm;
        }

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        currentWeekday = days[now.getDay()];

        var months = ["January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"];
        currentDate = months[now.getMonth()] + " " + now.getDate() + ", " + now.getFullYear();
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: clockRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: clockRoot.updateClock()
    }

    Connections {
        target: Settings
        function onClockShowSecondsChanged() {
            clockRoot.updateClock();
        }
        function onClock24hChanged() {
            clockRoot.updateClock();
        }
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
            drag.target: clockRoot
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: (clockRoot.parent ? clockRoot.parent.width : 1920) - clockRoot.width
            drag.maximumY: (clockRoot.parent ? clockRoot.parent.height : 1080) - clockRoot.height
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

            onReleased: {
                Settings.clockX = Math.round(clockRoot.x);
                Settings.clockY = Math.round(clockRoot.y);
                Settings.save();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            spacing: Theme.spacingSmall

            // Header line with subtle dot and drag grip
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                RowLayout {
                    anchors.fill: parent
                    Text {
                        text: "TIME"
                        font.family: Theme.dotCapsFont
                        font.pixelSize: 11
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
                    drag.target: clockRoot
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.minimumY: 0
                    drag.maximumX: (clockRoot.parent ? clockRoot.parent.width : 1920) - clockRoot.width
                    drag.maximumY: (clockRoot.parent ? clockRoot.parent.height : 1080) - clockRoot.height
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    onReleased: {
                        Settings.clockX = Math.round(clockRoot.x);
                        Settings.clockY = Math.round(clockRoot.y);
                        Settings.save();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            Text {
                Layout.fillWidth: true
                text: clockRoot.currentTime
                font.family: Theme.dotFont
                font.pixelSize: Settings.clockShowSeconds ? 48 : 58
                color: Theme.textPrimary
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideNone
            }

            Text {
                Layout.fillWidth: true
                text: clockRoot.currentWeekday.toUpperCase()
                font.family: Theme.dotCapsFont
                font.pixelSize: 14
                font.letterSpacing: 1
                color: Theme.textPrimary
                horizontalAlignment: Text.AlignLeft
            }

            Text {
                Layout.fillWidth: true
                text: clockRoot.currentDate
                font.family: Theme.monoFont
                font.pixelSize: 12
                color: Theme.textSecondary
                horizontalAlignment: Text.AlignLeft
            }
        }
    }

    Component.onCompleted: updateClock()
}
