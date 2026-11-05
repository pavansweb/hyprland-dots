import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.styles
import qs.config

Item {
    id: calendarRoot

    visible: Settings.calendarVisible
    width: 320
    height: 280
    x: Settings.calendarX
    y: Settings.calendarY

    Connections {
        target: Settings
        function onCalendarXChanged() { calendarRoot.x = Settings.calendarX; }
        function onCalendarYChanged() { calendarRoot.y = Settings.calendarY; }
    }

    property int viewMonth: new Date().getMonth()
    property int viewYear: new Date().getFullYear()

    readonly property int todayDay: new Date().getDate()
    readonly property int todayMonth: new Date().getMonth()
    readonly property int todayYear: new Date().getFullYear()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayLabels: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    function daysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate();
    }

    function firstDayOfWeek(month, year) {
        return new Date(year, month, 1).getDay();
    }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear -= 1;
        } else {
            viewMonth -= 1;
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear += 1;
        } else {
            viewMonth += 1;
        }
    }

    readonly property var gridCells: {
        var _m = viewMonth;
        var _y = viewYear;
        var cells = [];
        var totalDays = daysInMonth(viewMonth, viewYear);
        var startDay = firstDayOfWeek(viewMonth, viewYear);

        // Previous month trailing days
        var prevMonthNum = viewMonth === 0 ? 11 : viewMonth - 1;
        var prevYearNum = viewMonth === 0 ? viewYear - 1 : viewYear;
        var prevMonthDays = daysInMonth(prevMonthNum, prevYearNum);
        for (var i = 0; i < startDay; i++) {
            cells.push({
                day: prevMonthDays - startDay + 1 + i,
                currentMonth: false,
                isToday: false
            });
        }

        // Current month days
        for (var d = 1; d <= totalDays; d++) {
            cells.push({
                day: d,
                currentMonth: true,
                isToday: (d === todayDay && viewMonth === todayMonth && viewYear === todayYear)
            });
        }

        // Next month leading days
        var remaining = 42 - cells.length;
        for (var n = 1; n <= remaining; n++) {
            cells.push({
                day: n,
                currentMonth: false,
                isToday: false
            });
        }

        return cells;
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
            drag.target: calendarRoot
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: (calendarRoot.parent ? calendarRoot.parent.width : 1920) - calendarRoot.width
            drag.maximumY: (calendarRoot.parent ? calendarRoot.parent.height : 1080) - calendarRoot.height
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

            onReleased: {
                Settings.calendarX = Math.round(calendarRoot.x);
                Settings.calendarY = Math.round(calendarRoot.y);
                Settings.save();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            spacing: Theme.spacingSmall

            // Header row with month navigation & drag handle
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32

                // Prev month button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 3
                    color: prevHover.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        font.family: Theme.bodyFont
                        font.pixelSize: 18
                        color: prevHover.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }

                    MouseArea {
                        id: prevHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendarRoot.prevMonth()
                    }
                }

                // Month Year label (draggable header)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: calendarRoot.monthNames[calendarRoot.viewMonth].toUpperCase() + " " + calendarRoot.viewYear
                            font.family: Theme.dotCapsFont
                            font.pixelSize: 13
                            font.letterSpacing: 2
                            color: titleDragArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
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
                        drag.target: calendarRoot
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.minimumY: 0
                        drag.maximumX: (calendarRoot.parent ? calendarRoot.parent.width : 1920) - calendarRoot.width
                        drag.maximumY: (calendarRoot.parent ? calendarRoot.parent.height : 1080) - calendarRoot.height
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                        onReleased: {
                            Settings.calendarX = Math.round(calendarRoot.x);
                            Settings.calendarY = Math.round(calendarRoot.y);
                            Settings.save();
                        }
                    }
                }

                // Next month button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 3
                    color: nextHover.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        font.family: Theme.bodyFont
                        font.pixelSize: 18
                        color: nextHover.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }

                    MouseArea {
                        id: nextHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendarRoot.nextMonth()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Day-of-week header
            Row {
                Layout.fillWidth: true
                height: 20

                Repeater {
                    model: calendarRoot.dayLabels

                    Item {
                        width: (calendarRoot.width - (Theme.paddingLarge * 2)) / 7
                        height: 20

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Theme.monoFont
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                            color: Theme.textDim
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // Calendar grid: 6 rows x 7 columns
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Grid {
                    id: calendarGrid
                    anchors.fill: parent
                    columns: 7
                    rows: 6

                    Repeater {
                        model: calendarRoot.gridCells

                        Item {
                            width: calendarGrid.width / 7
                            height: calendarGrid.height / 6

                            property var cellData: modelData

                            Rectangle {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                radius: 13
                                color: cellData.isToday ? Theme.accent : "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: cellData.day
                                font.family: Theme.monoFont
                                font.pixelSize: 12
                                color: {
                                    if (cellData.isToday) return "#FFFFFF";
                                    if (cellData.currentMonth) return Theme.textSecondary;
                                    return Theme.textDim;
                                }
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
