import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.feature.bar

Item {
    id: root

    property bool isCurrentTab: true
    signal closeRequested()

    property var viewingDate: new Date()
    property var selectedDate: new Date()
    readonly property var today: new Date()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    readonly property var dayOfWeekNames: [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]

    readonly property string formattedDateText: {
        const d = root.selectedDate || root.today;
        const dayName = dayOfWeekNames[d.getDay()];
        const monthName = monthNames[d.getMonth()];
        const dateNum = d.getDate();
        const year = d.getFullYear();
        return `${dayName}, ${monthName} ${dateNum}, ${year}`;
    }

    readonly property string monthYearTitle: {
        return `${monthNames[viewingDate.getMonth()]} ${viewingDate.getFullYear()}`;
    }

    function prevMonth() {
        const y = viewingDate.getFullYear();
        const m = viewingDate.getMonth();
        viewingDate = new Date(y, m - 1, 1);
    }

    function nextMonth() {
        const y = viewingDate.getFullYear();
        const m = viewingDate.getMonth();
        viewingDate = new Date(y, m + 1, 1);
    }

    function jumpToToday() {
        const now = new Date();
        viewingDate = new Date(now.getFullYear(), now.getMonth(), 1);
        selectedDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    }

    function adjustSelectedDay(deltaDays) {
        const current = root.selectedDate || new Date();
        const target = new Date(current.getFullYear(), current.getMonth(), current.getDate() + deltaDays);
        root.selectedDate = target;
        if (target.getMonth() !== root.viewingDate.getMonth() || target.getFullYear() !== root.viewingDate.getFullYear()) {
            root.viewingDate = new Date(target.getFullYear(), target.getMonth(), 1);
        }
    }

    function focusKeyboardTarget() {
        calendarNavFocus.forceActiveFocus();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Top Header: Live Digital Clock & Formatted Date Banner
        Rectangle {
            id: headerBanner
            Layout.fillWidth: true
            Layout.preferredHeight: 66
            radius: Decorations.cornerRadius
            color: Colors.surfaceMuted

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: StatusBarService.clockValue
                        color: Colors.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    // Quick Jump To Today chip
                    Rectangle {
                        id: todayChip
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: Math.round(Decorations.cornerRadius / 2)
                        color: todayChipMouse.containsMouse ? Colors.surfaceSoft : Colors.clear
                        border.color: Colors.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "today"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: Colors.accent
                        }

                        MouseArea {
                            id: todayChipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.jumpToToday()
                        }
                    }
                }

                Text {
                    text: root.formattedDateText
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // Navigation Bar: Previous, Month/Year label, Next
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Previous Month Button
            Rectangle {
                id: prevMonthButton
                implicitWidth: 32
                implicitHeight: 32
                radius: Math.round(Decorations.cornerRadius / 2)
                color: prevMouseArea.containsMouse ? Colors.surfaceSoft : Colors.surface
                border.color: Colors.border
                border.width: 1

                scale: prevMouseArea.pressed ? Motion.scalePress : (prevMouseArea.containsMouse ? Motion.scaleHover : Motion.scaleNormal)

                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "chevron_left"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: Colors.text
                }

                MouseArea {
                    id: prevMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.prevMonth()
                }
            }

            // Month & Year Title (clicking resets to current month)
            Rectangle {
                id: monthTitleBadge
                Layout.fillWidth: true
                implicitHeight: 32
                radius: Math.round(Decorations.cornerRadius / 2)
                color: titleMouseArea.containsMouse ? Colors.surfaceSoft : Colors.surface
                border.color: Colors.border
                border.width: 1

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.monthYearTitle
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: titleMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.jumpToToday()
                }
            }

            // Next Month Button
            Rectangle {
                id: nextMonthButton
                implicitWidth: 32
                implicitHeight: 32
                radius: Math.round(Decorations.cornerRadius / 2)
                color: nextMouseArea.containsMouse ? Colors.surfaceSoft : Colors.surface
                border.color: Colors.border
                border.width: 1

                scale: nextMouseArea.pressed ? Motion.scalePress : (nextMouseArea.containsMouse ? Motion.scaleHover : Motion.scaleNormal)

                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: Colors.text
                }

                MouseArea {
                    id: nextMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextMonth()
                }
            }
        }

        // Decomposed Calendar Grid
        CalendarGrid {
            id: calendarGrid
            Layout.fillWidth: true
            viewingDate: root.viewingDate
            selectedDate: root.selectedDate

            onDayClicked: date => {
                root.selectedDate = date;
                if (date.getMonth() !== root.viewingDate.getMonth() || date.getFullYear() !== root.viewingDate.getFullYear()) {
                    root.viewingDate = new Date(date.getFullYear(), date.getMonth(), 1);
                }
            }
        }
    }

    FocusScope {
        id: calendarNavFocus
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left) {
                root.adjustSelectedDay(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.adjustSelectedDay(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                root.adjustSelectedDay(-7);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                root.adjustSelectedDay(7);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageUp) {
                root.prevMonth();
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                root.nextMonth();
                event.accepted = true;
            } else if (event.key === Qt.Key_Home || event.key === Qt.Key_T) {
                root.jumpToToday();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                root.closeRequested();
                event.accepted = true;
            }
        }
    }
}
